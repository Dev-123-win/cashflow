import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late SharedPreferences _prefs;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Validation
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        throw Exception('All fields are required');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserInFirestore(
        userId: userCredential.user!.uid,
        email: email,
        displayName: displayName,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Store locally
      await _prefs.setString('userId', userCredential.user!.uid);
      await _prefs.setString('userEmail', email);
      await _prefs.setString('displayName', displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // Store locally
      await _prefs.setString('userId', userCredential.user!.uid);
      await _prefs.setString('userEmail', email);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  /// Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Create user document if new user
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        await _createUserInFirestore(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? 'User',
        );
      }

      // Store locally
      await _prefs.setString('userId', userCredential.user!.uid);
      await _prefs.setString('userEmail', userCredential.user!.email ?? '');
      await _prefs.setString(
        'displayName',
        userCredential.user!.displayName ?? 'User',
      );

      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      // Clear local data
      await _prefs.remove('userId');
      await _prefs.remove('userEmail');
      await _prefs.remove('displayName');
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) {
        throw Exception('Please enter your email address');
      }
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  Future<bool> isEmailVerified() async {
    await _firebaseAuth.currentUser?.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  Future<void> resendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to resend verification: ${e.toString()}');
    }
  }

  /// Get saved user ID from local storage
  String? getSavedUserId() {
    return _prefs.getString('userId');
  }

  /// Create user document in Firestore
  Future<void> _createUserInFirestore({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'totalEarnings': 0.0,
        'availableBalance': 0.0,
        'monthlyEarnings': 0.0,
        'currentStreak': 0,
        'referralCode': _generateReferralCode(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user in Firestore: $e');
    }
  }

  String _generateReferralCode() {
    return 'EARN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
