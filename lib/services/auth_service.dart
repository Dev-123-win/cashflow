import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'cloudflare_workers_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final CloudflareWorkersService _backend = CloudflareWorkersService();
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

      // Create user document in Firestore with retry logic
      bool profileCreated = false;
      int attempts = 0;
      while (!profileCreated && attempts < 3) {
        try {
          await _createUserInFirestore(
            userId: userCredential.user!.uid,
            email: email,
            displayName: displayName,
          );
          // Verify creation
          final doc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
          if (doc.exists) {
            profileCreated = true;
          } else {
            throw Exception('Profile verification failed');
          }
        } catch (e) {
          attempts++;
          await Future.delayed(Duration(seconds: 1 * attempts));
        }
      }

      if (!profileCreated) {
        // Critical failure: Delete auth user to prevent zombie state
        await userCredential.user!.delete();
        throw Exception('Failed to create user profile. Please try again.');
      }

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Store locally
      await _prefs.setString('userId', userCredential.user!.uid);
      await _prefs.setString('userEmail', email);
      await _prefs.setString('displayName', displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
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

      // Ensure user exists in Firestore (self-healing)
      await ensureUserExists(userCredential.user!);

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

      // Ensure user exists in Firestore (self-healing)
      await ensureUserExists(userCredential.user!);

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

  /// Ensure user exists in Firestore
  Future<void> ensureUserExists(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _createUserInFirestore(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
        );
      }
    } catch (e) {
      debugPrint('Error ensuring user exists: $e');
    }
  }

  /// Create user document in Firestore via Backend
  Future<void> _createUserInFirestore({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      await _backend.createUser(
        userId: userId,
        email: email,
        displayName: displayName,
      );
    } catch (e) {
      debugPrint('Error creating user via backend: $e');
      // If backend fails, we might want to retry or handle it.
      // For now, just logging.
    }
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
