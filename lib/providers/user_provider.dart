import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cloudflare_workers_service.dart';
import '../core/di/service_locator.dart';

class UserProvider extends ChangeNotifier {
  User _user = User.empty();
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  StreamSubscription? _userSubscription;

  // Optimistic UI State
  int _optimisticCoins = 0;

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Get effective coins (Server + Optimistic)
  int get coins => _user.coins + _optimisticCoins;

  final _firestoreService = getIt<FirestoreService>();
  final _auth = fb_auth.FirebaseAuth.instance;

  /// Add coins optimistically (Instant UI update)
  void addOptimisticCoins(int amount) {
    _optimisticCoins += amount;
    notifyListeners();
  }

  /// Rollback optimistic coins (If backend fails)
  void rollbackOptimisticCoins(int amount) {
    _optimisticCoins -= amount;
    notifyListeners();
  }

  /// Confirm optimistic coins (Backend success)
  /// We don't need to do anything here if we fetch the new user state,
  /// but if we just want to clear the optimistic buffer and assume server state is updated:
  void confirmOptimisticCoins(int amount) {
    _optimisticCoins -= amount;
    // We assume the server state (which we might fetch or update manually) now has the coins.
    // If we updated local state manually via updateLocalState, we should do that concurrently.
    notifyListeners();
  }

  /// Initialize user profile from Firebase (Optimized for reads)
  Future<void> initializeUser(String userId) async {
    try {
      _isLoading = true;
      _optimisticCoins = 0; // Reset on init
      notifyListeners();

      // Ensure user exists before listening (self-healing)
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await AuthService().ensureUserExists(currentUser);
      }

      // Fetch user once (No Stream!)
      // This saves massive amounts of reads. We will update local state manually.
      final user = await _firestoreService.getUser(userId);
      _user = user;
      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
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
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Update balance and sync with Firebase
  /// ✅ FIXED: Wait for backend confirmation before updating UI
  // updateBalance removed. Balance updates are handled by backend and synced via stream.

  void updateMonthlyEarnings(double newEarnings) {
    _user = _user.copyWith(monthlyEarnings: newEarnings);
    notifyListeners();
  }

  /// Manually update local user state (Optimized)
  /// Call this after a successful backend operation to update UI without a read
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

    // If coins provided, update the underlying user model (we need to add a copyWith for coins if not exists)
    // Since User model might not have copyWith for coins (it uses availableBalance), we handle it.
    // The User model has `int get coins => availableBalance.toInt()`.
    // So updating availableBalance updates coins.
    if (coins != null) {
      _user = _user.copyWith(availableBalance: coins.toDouble());
    }

    notifyListeners();
  }

  /// Logout and cleanup
  Future<void> logout() async {
    try {
      // Cancel Firestore subscription
      await _userSubscription?.cancel();

      // Sign out from Firebase
      await _auth.signOut();

      // Clear user data
      _user = User.empty();
      _isAuthenticated = false;
      _error = null;
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

  /// Refresh user data from Firestore
  Future<void> refreshUser() async {
    if (!_isAuthenticated || _user.userId.isEmpty) return;

    try {
      // Check backend health before refreshing
      final cloudflareService = CloudflareWorkersService();
      final isBackendHealthy = await cloudflareService.healthCheck();

      if (!isBackendHealthy) {
        debugPrint('Backend unreachable during refreshUser');
        return;
      }

      final updatedUser = await _firestoreService.getUser(_user.userId);
      _user = updatedUser;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
