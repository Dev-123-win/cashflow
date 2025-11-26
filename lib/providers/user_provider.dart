import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  User _user = User.empty();
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  StreamSubscription? _userSubscription;

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  final _firestoreService = FirestoreService();
  final _auth = fb_auth.FirebaseAuth.instance;

  /// Initialize user profile from Firebase
  Future<void> initializeUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Listen to real-time user updates from Firestore
      _userSubscription = _firestoreService
          .getUserStream(userId)
          .listen(
            (user) {
              if (user != null) {
                _user = user;
                _isAuthenticated = true;
                _error = null;
                notifyListeners();
              }
            },
            onError: (error) {
              _error = error.toString();
              notifyListeners();
            },
          );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
