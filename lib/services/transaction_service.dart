import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cloudflare_workers_service.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'earning', 'withdrawal', 'refund'
  final double amount;
  final String?
  gameType; // 'tictactoe', 'memory_match', 'quiz', null for withdrawal
  final bool success;
  final DateTime timestamp;
  final String? description;
  final String status; // 'pending', 'completed', 'failed'

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.gameType,
    required this.success,
    required this.timestamp,
    this.description,
    required this.status,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'earning',
      amount: (data['amount'] ?? 0).toDouble(),
      gameType: data['gameType'],
      success: data['success'] ?? true,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      status: data['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type,
    'amount': amount,
    'gameType': gameType,
    'success': success,
    'timestamp': Timestamp.fromDate(timestamp),
    'description': description,
    'status': status,
  };
}

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudflareWorkersService _backend = CloudflareWorkersService();

  // Get transaction history for a user
  Stream<List<TransactionModel>> getUserTransactions(
    String userId, {
    String? filterType, // 'earning', 'withdrawal', null for all
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType);
    }

    if (startDate != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    query = query.limit(limit);

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList(),
    );
  }

  // Get earnings transactions (games)
  Stream<List<TransactionModel>> getUserEarnings(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    return getUserTransactions(
      userId,
      filterType: 'earning',
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  // Get withdrawal transactions
  Stream<List<TransactionModel>> getUserWithdrawals(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    return getUserTransactions(
      userId,
      filterType: 'withdrawal',
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  // Record a new transaction
  Future<void> recordTransaction({
    required String userId,
    required String type, // 'earning', 'withdrawal', 'refund'
    required double amount,
    String? gameType,
    required bool success,
    String? description,
    required String status,
  }) async {
    try {
      await _backend.recordTransaction(
        userId: userId,
        type: type,
        amount: amount,
        description: description ?? '',
        gameType: gameType,
      );
      debugPrint('✅ Transaction recorded via Backend');
    } catch (e) {
      debugPrint('❌ Error recording transaction: $e');
      rethrow;
    }
  }

  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    try {
      final earnings = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'earning')
          .where('status', isEqualTo: 'completed')
          .get();

      final withdrawals = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'withdrawal')
          .where('status', isEqualTo: 'completed')
          .get();

      double totalEarned = 0;
      double totalWithdrawn = 0;
      int earningCount = 0;
      int withdrawalCount = 0;

      for (var doc in earnings.docs) {
        final data = doc.data();
        totalEarned += (data['amount'] ?? 0).toDouble();
        earningCount++;
      }

      for (var doc in withdrawals.docs) {
        final data = doc.data();
        totalWithdrawn += (data['amount'] ?? 0).toDouble();
        withdrawalCount++;
      }

      return {
        'totalEarned': totalEarned,
        'totalWithdrawn': totalWithdrawn,
        'balance': totalEarned - totalWithdrawn,
        'earningCount': earningCount,
        'withdrawalCount': withdrawalCount,
        'thisMonthEarnings': _calculateMonthlyEarnings(earnings.docs),
        'thisWeekEarnings': _calculateWeeklyEarnings(earnings.docs),
      };
    } catch (e) {
      debugPrint('Error getting transaction stats: $e');
      rethrow;
    }
  }

  // Calculate this month's earnings
  double _calculateMonthlyEarnings(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null && timestamp.isAfter(startOfMonth)) {
        total += (data['amount'] ?? 0).toDouble();
      }
    }

    return total;
  }

  // Calculate this week's earnings
  double _calculateWeeklyEarnings(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    double total = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null && timestamp.isAfter(startOfWeek)) {
        total += (data['amount'] ?? 0).toDouble();
      }
    }

    return total;
  }

  // Get earnings by game type
  Future<Map<String, double>> getEarningsByGameType(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'earning')
          .get();

      final earnings = <String, double>{
        'tictactoe': 0,
        'memory_match': 0,
        'quiz': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final gameType = (data['gameType'] as String?) ?? 'unknown';
        final amount = (data['amount'] ?? 0).toDouble();

        if (earnings.containsKey(gameType)) {
          earnings[gameType] = (earnings[gameType] ?? 0) + amount;
        }
      }

      return earnings;
    } catch (e) {
      debugPrint('Error getting earnings by game type: $e');
      rethrow;
    }
  }

  // Get total earnings for a specific game type
  Future<double> getGameTypeEarnings(String userId, String gameType) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'earning')
          .where('gameType', isEqualTo: gameType)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      debugPrint('Error getting game type earnings: $e');
      rethrow;
    }
  }
}
