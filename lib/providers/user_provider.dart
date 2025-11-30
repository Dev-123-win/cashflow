import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user_model.dart';
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

  final _cloudflareService = getIt<CloudflareWorkersService>();
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
  void confirmOptimisticCoins(int amount) {
    _optimisticCoins -= amount;
    notifyListeners();
  }

  /// Initialize user profile from Cloudflare Worker
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

      // Fetch user stats from Worker
      final userData = await _cloudflareService.getUserStats(userId: userId);
      _user = User.fromJson(userData);
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

    // Sync availableBalance with coins if coins updated
    if (coins != null) {
      _user = _user.copyWith(availableBalance: coins.toDouble() / 1000);
    }

    notifyListeners();
  }

  /// Logout and cleanup
  Future<void> logout() async {
    try {
      await _userSubscription?.cancel();
      await _auth.signOut();

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

  /// Refresh user data from Cloudflare Worker
  Future<void> refreshUser() async {
    if (!_isAuthenticated || _user.userId.isEmpty) return;

    try {
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
