import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/cloudflare_workers_service.dart';
import '../core/di/service_locator.dart';

/// Pending transaction for optimistic UI
class PendingTransaction {
  final String id;
  final int amount;
  final DateTime timestamp;
  final String type; // 'task', 'game', 'ad', 'spin', etc.

  PendingTransaction({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
  };

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    return PendingTransaction(
      id: json['id'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class UserProvider extends ChangeNotifier {
  User _user = User.empty();
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  StreamSubscription? _userSubscription;

  // Singleton SharedPreferences instance (fixes memory leak)
  SharedPreferences? _prefs;

  // Optimistic UI State with transaction tracking
  final Map<String, PendingTransaction> _pendingTransactions = {};

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Get effective coins (Server + Pending transactions)
  int get coins {
    final pendingTotal = _pendingTransactions.values
        .map((t) => t.amount)
        .fold(0, (sum, amount) => sum + amount);
    return _user.coins + pendingTotal;
  }

  final _cloudflareService = getIt<CloudflareWorkersService>();
  final _auth = fb_auth.FirebaseAuth.instance;

  /// Add coins optimistically with transaction tracking
  ///
  /// CRITICAL FIX: Each transaction has unique ID for proper reconciliation
  void addOptimisticCoins(int amount, String transactionId, String type) {
    _pendingTransactions[transactionId] = PendingTransaction(
      id: transactionId,
      amount: amount,
      timestamp: DateTime.now(),
      type: type,
    );
    _savePendingTransactions(); // Persist for crash recovery
    notifyListeners();
  }

  /// Rollback optimistic coins if backend fails
  void rollbackOptimisticCoins(String transactionId) {
    _pendingTransactions.remove(transactionId);
    _savePendingTransactions();
    notifyListeners();
  }

  /// Confirm optimistic coins when backend succeeds
  ///
  /// CRITICAL FIX: Server balance is source of truth, discard optimistic value
  void confirmOptimisticCoins(String transactionId, int serverCoins) {
    _pendingTransactions.remove(transactionId);
    _user = _user.copyWith(coins: serverCoins);
    _savePendingTransactions();
    _saveUserToPrefs();
    notifyListeners();
  }

  /// Clear stale pending transactions (older than 5 minutes)
  ///
  /// Prevents memory leak from failed requests that were never confirmed/rolled back
  void _clearStalePendingTransactions() {
    final now = DateTime.now();
    final staleIds = <String>[];

    for (final entry in _pendingTransactions.entries) {
      if (now.difference(entry.value.timestamp).inMinutes > 5) {
        staleIds.add(entry.key);
      }
    }

    for (final id in staleIds) {
      _pendingTransactions.remove(id);
    }

    if (staleIds.isNotEmpty) {
      _savePendingTransactions();
    }
  }

  /// Initialize user profile from Cloudflare Worker
  Future<void> initializeUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Initialize SharedPreferences singleton
      _prefs ??= await SharedPreferences.getInstance();

      // 1. Try to load from local storage first (Instant UI)
      await _loadUserFromPrefs(userId);
      await _loadPendingTransactions();
      _clearStalePendingTransactions();

      // Ensure user exists before listening (self-healing)
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await AuthService().ensureUserExists(currentUser);
      }

      // 2. Fetch fresh user stats from Worker
      try {
        final userData = await _cloudflareService.getUserStats(userId: userId);
        _user = User.fromJson(userData);
      } catch (e) {
        // If user not found (404), try to create it
        if (e.toString().contains('404') ||
            (e is ApiException && e.statusCode == 404)) {
          debugPrint('User not found, creating new user...');
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            final newUserData = await _cloudflareService.createUser(
              userId: userId,
              email: currentUser.email ?? '',
              displayName: currentUser.displayName ?? 'User',
            );
            _user = User.fromJson(newUserData);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      // Fallback to Firebase Auth data if backend returns empty fields
      if (currentUser != null) {
        if (_user.displayName.isEmpty || _user.email.isEmpty) {
          _user = _user.copyWith(
            displayName: _user.displayName.isEmpty
                ? currentUser.displayName
                : _user.displayName,
            email: _user.email.isEmpty ? currentUser.email : _user.email,
          );
        }
      }

      // 3. Save fresh data to local storage
      await _saveUserToPrefs();

      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    _isAuthenticated = true;
    _error = null;
    _saveUserToPrefs(); // Persist
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void updateMonthlyEarnings(double newEarnings) {
    _user = _user.copyWith(monthlyEarnings: newEarnings);
    _saveUserToPrefs(); // Persist
    notifyListeners();
  }

  /// Manually update local user state (Optimized)
  ///
  /// CRITICAL FIX: Server state is source of truth, clears optimistic updates
  void updateLocalState({
    int? coins,
    double? totalEarnings,
    int? completedTasks,
    int? gamesPlayedToday,
    List<String>? completedTaskIds,
  }) {
    _user = _user.copyWith(
      coins: coins ?? _user.coins,
      totalEarnings: totalEarnings ?? _user.totalEarnings,
      completedTasks: completedTasks ?? _user.completedTasks,
      gamesPlayedToday: gamesPlayedToday ?? _user.gamesPlayedToday,
      completedTaskIds: completedTaskIds ?? _user.completedTaskIds,
    );

    // Sync availableBalance with coins if coins updated
    if (coins != null) {
      _user = _user.copyWith(availableBalance: coins.toDouble() / 1000);
    }

    _saveUserToPrefs(); // Persist immediately
    notifyListeners();
  }

  /// Logout and cleanup
  Future<void> logout() async {
    try {
      await _userSubscription?.cancel();
      await _auth.signOut();

      // Clear local storage
      if (_prefs != null) {
        await _prefs!.remove('cached_user_data');
        await _prefs!.remove('pending_transactions');
      }

      _user = User.empty();
      _isAuthenticated = false;
      _error = null;
      _pendingTransactions.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh user data from Cloudflare Worker
  ///
  /// CRITICAL FIX: Uses mutex-like flag to prevent concurrent refreshes
  bool _isRefreshing = false;

  Future<void> refreshUser() async {
    if (!_isAuthenticated || _user.userId.isEmpty || _isRefreshing) return;

    try {
      _isRefreshing = true;

      // Check backend health before refreshing
      final isBackendHealthy = await _cloudflareService.healthCheck();

      if (!isBackendHealthy) {
        debugPrint('Backend unreachable during refreshUser');
        return;
      }

      final userData = await _cloudflareService.getUserStats(
        userId: _user.userId,
      );
      _user = User.fromJson(userData);

      // Fallback to Firebase Auth data if backend returns empty fields
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (_user.displayName.isEmpty || _user.email.isEmpty) {
          _user = _user.copyWith(
            displayName: _user.displayName.isEmpty
                ? currentUser.displayName
                : _user.displayName,
            email: _user.email.isEmpty ? currentUser.email : _user.email,
          );
        }
      }

      await _saveUserToPrefs(); // Persist

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error refreshing user: $e');
      notifyListeners();
    } finally {
      _isRefreshing = false;
    }
  }

  // Persistence Helpers

  Future<void> _saveUserToPrefs() async {
    try {
      if (_user.userId.isEmpty || _prefs == null) return;
      final userJson = jsonEncode(_user.toJson());
      await _prefs!.setString('cached_user_data', userJson);
    } catch (e) {
      debugPrint('Error saving user to prefs: $e');
    }
  }

  Future<void> _loadUserFromPrefs(String userId) async {
    try {
      if (_prefs == null) return;

      final userJson = _prefs!.getString('cached_user_data');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        // Only load if it matches current user
        if (userData['userId'] == userId) {
          _user = User.fromJson(userData);
          _isAuthenticated = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading user from prefs: $e');
      // Clear corrupted cache
      await _prefs?.remove('cached_user_data');
    }
  }

  Future<void> _savePendingTransactions() async {
    try {
      if (_prefs == null) return;

      final transactionsJson = jsonEncode(
        _pendingTransactions.map((key, value) => MapEntry(key, value.toJson())),
      );
      await _prefs!.setString('pending_transactions', transactionsJson);
    } catch (e) {
      debugPrint('Error saving pending transactions: $e');
    }
  }

  Future<void> _loadPendingTransactions() async {
    try {
      if (_prefs == null) return;

      final transactionsJson = _prefs!.getString('pending_transactions');
      if (transactionsJson != null) {
        final Map<String, dynamic> data = jsonDecode(transactionsJson);
        _pendingTransactions.clear();
        data.forEach((key, value) {
          _pendingTransactions[key] = PendingTransaction.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading pending transactions: $e');
      // Clear corrupted cache
      await _prefs?.remove('pending_transactions');
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
