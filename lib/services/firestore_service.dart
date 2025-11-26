import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/withdrawal_model.dart';
import '../models/leaderboard_model.dart';
import '../core/constants/app_constants.dart';
import 'cloudflare_workers_service.dart';
import 'cache_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cache = CacheService();
  final CloudflareWorkersService _backend = CloudflareWorkersService();

  // ============ USER OPERATIONS ============

  /// Create a new user document
  Future<void> createUser({
    required String userId,
    required String email,
    required String displayName,
    String? referralCode,
  }) async {
    try {
      await _backend.createUser(
        userId: userId,
        email: email,
        displayName: displayName,
        referralCode: referralCode,
      );
      debugPrint('✅ User created via Backend: $userId');
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
  /// DEPRECATED: Balance is updated by backend
  Future<void> updateBalance(String userId, double newBalance) async {
    debugPrint(
      '⚠️ updateBalance called locally. This should be handled by backend.',
    );
    // We do nothing here to enforce backend authority
  }

  /// Record task completion (OPTIMIZED with batch writes)
  /// Reduces 3 separate writes to 1 batch write
  /// Record task completion
  Future<void> recordTaskCompletion(
    String userId,
    String taskId,
    double reward, {
    String? requestId,
    String? deviceFingerprint,
  }) async {
    try {
      await _backend.recordTaskEarning(
        userId: userId,
        taskId: taskId,
        deviceId: deviceFingerprint ?? 'unknown',
      );

      // Invalidate user cache
      _cache.invalidate('user_$userId');

      debugPrint('✅ Task completion recorded via Backend: $taskId');
    } catch (e) {
      debugPrint('❌ Error recording task completion: $e');
      rethrow;
    }
  }

  /// Record game result (OPTIMIZED with batch writes)
  /// Reduces 3 separate writes to 1 batch write
  /// Record game result
  Future<void> recordGameResult(
    String userId,
    String gameId,
    bool won,
    double reward, {
    String? requestId,
    String? deviceFingerprint,
  }) async {
    try {
      await _backend.recordGameResult(
        userId: userId,
        gameId: gameId,
        won: won,
        score: 0, // Score not passed in original method, defaulting to 0
        deviceId: deviceFingerprint ?? 'unknown',
      );

      // Invalidate user cache
      _cache.invalidate('user_$userId');
    } catch (e) {
      debugPrint('❌ Error recording game result: $e');
      rethrow;
    }
  }

  /// Record ad view (OPTIMIZED with batch writes)
  /// Reduces 3 separate writes to 1 batch write
  /// Record ad view
  Future<void> recordAdView(
    String userId,
    String adType,
    double reward, {
    String? requestId,
    String? deviceFingerprint,
  }) async {
    try {
      await _backend.recordAdView(
        userId: userId,
        adType: adType,
        deviceId: deviceFingerprint ?? 'unknown',
      );

      // Invalidate user cache
      _cache.invalidate('user_$userId');

      debugPrint('✅ Ad view recorded via Backend: $adType for $userId');
    } catch (e) {
      debugPrint('❌ Error recording ad view: $e');
      rethrow;
    }
  }

  /// Record spin result (OPTIMIZED with batch writes)
  /// Reduces 2 separate writes to 1 batch write
  /// Record spin result
  Future<void> recordSpinResult(String userId, double reward) async {
    try {
      await _backend.executeSpin(
        userId: userId,
        deviceId: 'unknown', // Device ID not passed in original method
      );

      // Invalidate user cache
      _cache.invalidate('user_$userId');

      debugPrint('✅ Spin result recorded via Backend: $userId');
    } catch (e) {
      debugPrint('❌ Error recording spin result: $e');
      rethrow;
    }
  }

  // ============ WITHDRAWAL OPERATIONS ============

  /// Create withdrawal request
  /// Create withdrawal request
  Future<String> createWithdrawalRequest(
    String userId,
    double amount,
    String upiId,
  ) async {
    try {
      final result = await _backend.requestWithdrawal(
        userId: userId,
        amount: amount,
        upiId: upiId,
        deviceId: 'unknown',
      );

      debugPrint('✅ Withdrawal request created via Backend');
      return result['withdrawalId'] ?? 'pending';
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

  // updateLeaderboardEntry removed as it should be handled by backend

  // ============ UTILITY OPERATIONS ============

  // _generateReferralCode removed as it is unused

  /// Reset daily stats
  /// DEPRECATED: Handled by backend cron jobs
  Future<void> resetDailyStats(String userId) async {
    debugPrint(
      '⚠️ resetDailyStats called locally. This is handled by backend cron.',
    );
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
