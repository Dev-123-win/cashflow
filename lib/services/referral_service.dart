import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory ReferralService() {
    return _instance;
  }

  ReferralService._internal();

  // Generate referral code for user
  Future<String> generateReferralCode(String userId) async {
    try {
      // Check if user already has a referral code
      final existingDoc = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingDoc.docs.isNotEmpty) {
        return existingDoc.docs.first['code'];
      }

      // Generate unique 8-character code
      String code = _generateUniqueCode();

      // Verify code doesn't exist
      while (await _codeExists(code)) {
        code = _generateUniqueCode();
      }

      // Create referral record
      await _firestore.collection('referrals').add({
        'referrerId': userId,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'usageCount': 0,
        'reward': 10.00, // ₹10 bonus for referrer
        'referralReward': 10.00, // ₹10 bonus for new user
        'isActive': true,
        'totalEarningsFromReferrals': 0.0,
      });

      debugPrint('Generated referral code: $code for user: $userId');
      return code;
    } catch (e) {
      debugPrint('Error generating referral code: $e');
      rethrow;
    }
  }

  // Generate unique code
  String _generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[(DateTime.now().microsecond + i) % chars.length];
    }
    return code;
  }

  // Check if code exists
  Future<bool> _codeExists(String code) async {
    try {
      final result = await _firestore
          .collection('referrals')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Validate and use referral code
  Future<bool> validateAndUseReferralCode(String userId, String code) async {
    try {
      // Find referral code
      final referralSnap = await _firestore
          .collection('referrals')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (referralSnap.docs.isEmpty) {
        debugPrint('Referral code not found: $code');
        return false;
      }

      final referralDoc = referralSnap.docs.first;
      final referralData = referralDoc.data();
      final referrerId = referralData['referrerId'];

      // Prevent self-referral
      if (referrerId == userId) {
        debugPrint('Cannot use own referral code');
        return false;
      }

      // Check if user already used a referral
      final usageSnap = await _firestore
          .collection('referrals')
          .doc(referralDoc.id)
          .collection('usages')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (usageSnap.docs.isNotEmpty) {
        debugPrint('User already used this referral code');
        return false;
      }

      // Record usage
      final referralReward = (referralData['referralReward'] ?? 10.0)
          .toDouble();
      final referrerReward = (referralData['reward'] ?? 10.0).toDouble();

      await _firestore
          .collection('referrals')
          .doc(referralDoc.id)
          .collection('usages')
          .add({
            'userId': userId,
            'usedAt': FieldValue.serverTimestamp(),
            'reward': referralReward,
          });

      // Give bonus to new user
      await _firestore.collection('users').doc(userId).update({
        'availableBalance': FieldValue.increment(referralReward),
        'totalEarned': FieldValue.increment(referralReward),
        'referralCode': code.toUpperCase(),
        'referredBy': referrerId,
      });

      // Give bonus to referrer
      await _firestore.collection('users').doc(referrerId).update({
        'availableBalance': FieldValue.increment(referrerReward),
        'totalEarned': FieldValue.increment(referrerReward),
      });

      // Update referral stats
      await _firestore.collection('referrals').doc(referralDoc.id).update({
        'usageCount': FieldValue.increment(1),
        'totalEarningsFromReferrals': FieldValue.increment(referrerReward),
      });

      // Record transaction for referral reward
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add({
            'userId': userId,
            'type': 'earning',
            'amount': referralReward,
            'gameType': 'referral',
            'success': true,
            'timestamp': FieldValue.serverTimestamp(),
            'description': 'Referral bonus using code: $code',
            'status': 'completed',
          });

      await _firestore
          .collection('users')
          .doc(referrerId)
          .collection('transactions')
          .add({
            'userId': referrerId,
            'type': 'earning',
            'amount': referrerReward,
            'gameType': 'referral',
            'success': true,
            'timestamp': FieldValue.serverTimestamp(),
            'description': 'Referral reward for inviting user',
            'status': 'completed',
          });

      debugPrint('Referral code used successfully: $code');
      return true;
    } catch (e) {
      debugPrint('Error using referral code: $e');
      return false;
    }
  }

  // Get user's referral code
  Future<String?> getUserReferralCode(String userId) async {
    try {
      final snap = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.first['code'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user referral code: $e');
      return null;
    }
  }

  // Get referral statistics for user
  Future<ReferralStats> getReferralStats(String userId) async {
    try {
      final referralSnap = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (referralSnap.docs.isEmpty) {
        return ReferralStats(
          code: '',
          totalReferrals: 0,
          totalEarningsFromReferrals: 0.0,
          recentReferrals: [],
        );
      }

      final referralDoc = referralSnap.docs.first;
      final code = referralDoc['code'];
      final usageCount = referralDoc['usageCount'] ?? 0;
      final totalEarnings = (referralDoc['totalEarningsFromReferrals'] ?? 0.0)
          .toDouble();

      // Get recent referrals
      final usageSnap = await _firestore
          .collection('referrals')
          .doc(referralDoc.id)
          .collection('usages')
          .orderBy('usedAt', descending: true)
          .limit(10)
          .get();

      final recentReferrals = usageSnap.docs
          .map(
            (doc) => ReferralUsage(
              userId: doc['userId'],
              usedAt: (doc['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              reward: (doc['reward'] ?? 0.0).toDouble(),
            ),
          )
          .toList();

      return ReferralStats(
        code: code,
        totalReferrals: usageCount,
        totalEarningsFromReferrals: totalEarnings,
        recentReferrals: recentReferrals,
      );
    } catch (e) {
      debugPrint('Error getting referral stats: $e');
      return ReferralStats(
        code: '',
        totalReferrals: 0,
        totalEarningsFromReferrals: 0.0,
        recentReferrals: [],
      );
    }
  }

  // Get all referrals for a user
  Stream<List<ReferralUsage>> getUserReferrals(String userId) {
    return _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) {
            return [];
          }

          final referralDoc = snap.docs.first;
          final usageSnap = await _firestore
              .collection('referrals')
              .doc(referralDoc.id)
              .collection('usages')
              .orderBy('usedAt', descending: true)
              .get();

          return usageSnap.docs
              .map(
                (doc) => ReferralUsage(
                  userId: doc['userId'],
                  usedAt:
                      (doc['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  reward: (doc['reward'] ?? 0.0).toDouble(),
                ),
              )
              .toList();
        });
  }
}

// Referral statistics model
class ReferralStats {
  final String code;
  final int totalReferrals;
  final double totalEarningsFromReferrals;
  final List<ReferralUsage> recentReferrals;

  ReferralStats({
    required this.code,
    required this.totalReferrals,
    required this.totalEarningsFromReferrals,
    required this.recentReferrals,
  });
}

// Individual referral usage model
class ReferralUsage {
  final String userId;
  final DateTime usedAt;
  final double reward;

  ReferralUsage({
    required this.userId,
    required this.usedAt,
    required this.reward,
  });
}
