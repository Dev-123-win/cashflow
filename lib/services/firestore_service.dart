import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/withdrawal_model.dart';
import '../models/leaderboard_model.dart';
import '../core/constants/app_constants.dart';
import 'cache_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cache = CacheService();

  // ============ USER OPERATIONS ============

  /// Create a new user document
  Future<void> createUser({
    required String userId,
    required String email,
    required String displayName,
    String? referralCode,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set({
            'userId': userId,
            'email': email,
            'displayName': displayName,
            'availableBalance': 0.0,
            'totalEarned': 0.0,
            'totalWithdrawn': 0.0,
            'currentStreak': 0,
            'longestStreak': 0,
            'tasksCompletedToday': 0,
            'gamesPlayedToday': 0,
            'adsWatchedToday': 0,
            'dailySpins': 0,
            'referralCode': referralCode ?? _generateReferralCode(),
            'referralCount': 0,
            'referredBy': null,
            'accountCreatedAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isAccountLocked': false,
            'lockReason': '',
            'kycVerified': false,
            'upiId': null,
            'failedWithdrawals': 0,
          });
      debugPrint('✅ User created: $userId');
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      rethrow;
    }
  }

  /// Get user document (with caching)
  /// Cache TTL: 5 minutes
  Future<User> getUser(String userId) async {
    try {
      // Check cache first
      final cached = _cache.get<User>('user_$userId');
      if (cached != null) {
        return cached;
      }

      // Cache miss - fetch from Firestore
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      final user = User.fromJson(doc.data()!);

      // Cache for 5 minutes
      _cache.set('user_$userId', user, const Duration(minutes: 5));

      return user;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      rethrow;
    }
  }

  /// Stream of user document (real-time)
  Stream<User?> getUserStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return User.fromJson(doc.data()!);
        });
  }

  /// Update user balance
  Future<void> updateBalance(String userId, double newBalance) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'availableBalance': newBalance,
            'totalEarned': FieldValue.increment(
              newBalance > 0 ? newBalance : 0,
            ), // Only increment positive changes
          });
      debugPrint('✅ Balance updated for $userId: ₹$newBalance');
    } catch (e) {
      debugPrint('❌ Error updating balance: $e');
      rethrow;
    }
  }

  /// Record task completion (OPTIMIZED with batch writes)
  /// Reduces 3 separate writes to 1 batch write
  Future<void> recordTaskCompletion(
    String userId,
    String taskId,
    double reward, {
    String? requestId,
    String? deviceFingerprint,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Add transaction record
      final txnRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('transactions')
          .doc();

      batch.set(txnRef, {
        'userId': userId,
        'type': 'earning',
        'source': 'task',
        'taskId': taskId,
        'amount': reward,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
        'success': true,
        'requestId':
            requestId ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
        'deviceFingerprint': deviceFingerprint,
      });

      // 2. Update user stats
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      batch.update(userRef, {
        'tasksCompletedToday': FieldValue.increment(1),
        'availableBalance': FieldValue.increment(reward),
        'totalEarned': FieldValue.increment(reward),
        'dailyEarningsToday': FieldValue.increment(reward),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Single commit = 1 write operation instead of 3
      await batch.commit();

      // Invalidate user cache
      _cache.invalidate('user_$userId');

      debugPrint(
        '✅ Task completion recorded (BATCH): $taskId for $userId (+₹$reward)',
      );
    } catch (e) {
      debugPrint('❌ Error recording task completion: $e');
      rethrow;
    }
  }

  /// Record game result (OPTIMIZED with batch writes)
  /// Reduces 3 separate writes to 1 batch write
  Future<void> recordGameResult(
    String userId,
    String gameId,
    bool won,
    double reward, {
    String? requestId,
    String? deviceFingerprint,
  }) async {
    try {
      final batch = _firestore.batch();
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      if (won) {
        // 1. Add transaction record
        final txnRef = userRef.collection('transactions').doc();

        batch.set(txnRef, {
          'userId': userId,
          'type': 'earning',
          'source': 'game',
          'gameId': gameId,
          'gameType': gameId,
          'amount': reward,
          'result': 'win',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
          'success': true,
          'requestId':
              requestId ?? 'game_${DateTime.now().millisecondsSinceEpoch}',
          'deviceFingerprint': deviceFingerprint,
        });

        // 2. Update user stats
        batch.update(userRef, {
          'gamesPlayedToday': FieldValue.increment(1),
          'availableBalance': FieldValue.increment(reward),
          'totalEarned': FieldValue.increment(reward),
          'dailyEarningsToday': FieldValue.increment(reward),
          'lastActivity': FieldValue.serverTimestamp(),
        });

        debugPrint(
          '✅ Game result recorded (BATCH): $gameId for $userId - WIN (+₹$reward)',
        );
      } else {
        // Just update games played count
        batch.update(userRef, {
          'gamesPlayedToday': FieldValue.increment(1),
          'lastActivity': FieldValue.serverTimestamp(),
        });

        debugPrint(
          '✅ Game result recorded (BATCH): $gameId for $userId - LOSS',
        );
      }

      // Single commit
      await batch.commit();

      // Invalidate user cache
      _cache.invalidate('user_$userId');
    } catch (e) {
      debugPrint('❌ Error recording game result: $e');
      rethrow;
    }
  }

  /// Record ad view (OPTIMIZED with batch writes)
  /// Reduces 3 separate writes to 1 batch write
  Future<void> recordAdView(
    String userId,
    String adType,
    double reward, {
    String? requestId,
    String? deviceFingerprint,
  }) async {
    try {
      final batch = _firestore.batch();
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      // 1. Add transaction record
      final txnRef = userRef.collection('transactions').doc();

      batch.set(txnRef, {
        'userId': userId,
        'type': 'earning',
        'source': 'ad',
        'adType': adType,
        'amount': reward,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
        'success': true,
        'requestId': requestId ?? 'ad_${DateTime.now().millisecondsSinceEpoch}',
        'deviceFingerprint': deviceFingerprint,
      });

      // 2. Update user stats
      batch.update(userRef, {
        'adsWatchedToday': FieldValue.increment(1),
        'availableBalance': FieldValue.increment(reward),
        'totalEarned': FieldValue.increment(reward),
        'dailyEarningsToday': FieldValue.increment(reward),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Single commit
      await batch.commit();

      // Invalidate user cache
      _cache.invalidate('user_$userId');

      debugPrint('✅ Ad view recorded (BATCH): $adType for $userId (+₹$reward)');
    } catch (e) {
      debugPrint('❌ Error recording ad view: $e');
      rethrow;
    }
  }

  /// Record spin result (OPTIMIZED with batch writes)
  /// Reduces 2 separate writes to 1 batch write
  Future<void> recordSpinResult(String userId, double reward) async {
    try {
      final batch = _firestore.batch();
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      // 1. Add transaction record
      final txnRef = userRef.collection('transactions').doc();

      batch.set(txnRef, {
        'userId': userId,
        'type': 'earning',
        'source': 'spin',
        'amount': reward,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
        'success': true,
        'requestId': 'spin_${DateTime.now().millisecondsSinceEpoch}',
      });

      // 2. Update user stats
      batch.update(userRef, {
        'dailySpins': FieldValue.increment(1),
        'availableBalance': FieldValue.increment(reward),
        'totalEarned': FieldValue.increment(reward),
        'dailyEarningsToday': FieldValue.increment(reward),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Single commit
      await batch.commit();

      // Invalidate user cache
      _cache.invalidate('user_$userId');

      debugPrint('✅ Spin result recorded (BATCH): $userId (+₹$reward)');
    } catch (e) {
      debugPrint('❌ Error recording spin result: $e');
      rethrow;
    }
  }

  // ============ WITHDRAWAL OPERATIONS ============

  /// Create withdrawal request
  Future<String> createWithdrawalRequest(
    String userId,
    double amount,
    String upiId,
  ) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .add({
            'userId': userId,
            'amount': amount,
            'upiId': upiId,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'processedAt': null,
            'transactionRef': null,
          });

      // Deduct from user balance
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'availableBalance': FieldValue.increment(-amount),
            'totalWithdrawn': FieldValue.increment(amount),
          });

      debugPrint('✅ Withdrawal request created: ${docRef.id} (₹$amount)');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating withdrawal request: $e');
      rethrow;
    }
  }

  /// Get withdrawal history
  Future<List<Withdrawal>> getWithdrawalHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Withdrawal.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting withdrawal history: $e');
      rethrow;
    }
  }

  // ============ LEADERBOARD OPERATIONS ============

  /// Get top leaderboard entries (with caching)
  /// Cache TTL: 1 hour
  Future<List<LeaderboardEntry>> getTopLeaderboard({int limit = 50}) async {
    try {
      // Check cache first
      final cacheKey = 'leaderboard_$limit';
      final cached = _cache.get<List<LeaderboardEntry>>(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Cache miss - fetch from Firestore
      final snapshot = await _firestore
          .collection(AppConstants.leaderboardCollection)
          .orderBy('totalEarnings', descending: true)
          .limit(limit)
          .get();

      final leaderboard = snapshot.docs.asMap().entries.map((entry) {
        final doc = entry.value;
        final index = entry.key;
        final data = doc.data();
        return LeaderboardEntry(
          rank: index + 1,
          userId: data['userId'] ?? '',
          displayName: data['displayName'] ?? 'User',
          totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
        );
      }).toList();

      // Cache for 1 hour
      _cache.set(cacheKey, leaderboard, const Duration(hours: 1));

      return leaderboard;
    } catch (e) {
      debugPrint('❌ Error getting leaderboard: $e');
      rethrow;
    }
  }

  /// Update leaderboard entry
  Future<void> updateLeaderboardEntry(
    String userId,
    String displayName,
    double totalEarnings,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.leaderboardCollection)
          .doc(userId)
          .set({
            'userId': userId,
            'displayName': displayName,
            'totalEarnings': totalEarnings,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('✅ Leaderboard entry updated: $userId');
    } catch (e) {
      debugPrint('❌ Error updating leaderboard: $e');
      rethrow;
    }
  }

  // ============ UTILITY OPERATIONS ============

  /// Generate referral code
  String _generateReferralCode() {
    return 'EQ${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
  }

  /// Reset daily stats
  Future<void> resetDailyStats(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'tasksCompletedToday': 0,
            'gamesPlayedToday': 0,
            'adsWatchedToday': 0,
            'dailySpins': 0,
          });

      debugPrint('✅ Daily stats reset for $userId');
    } catch (e) {
      debugPrint('❌ Error resetting daily stats: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      final data = doc.data()!;
      return {
        'availableBalance': data['availableBalance'] ?? 0.0,
        'totalEarned': data['totalEarned'] ?? 0.0,
        'totalWithdrawn': data['totalWithdrawn'] ?? 0.0,
        'tasksCompletedToday': data['tasksCompletedToday'] ?? 0,
        'gamesPlayedToday': data['gamesPlayedToday'] ?? 0,
        'adsWatchedToday': data['adsWatchedToday'] ?? 0,
        'dailySpins': data['dailySpins'] ?? 0,
        'currentStreak': data['currentStreak'] ?? 0,
        'referralCount': data['referralCount'] ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting user stats: $e');
      rethrow;
    }
  }
}
