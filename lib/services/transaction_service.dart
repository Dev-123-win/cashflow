import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';

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

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      amount: map['amount'],
      gameType: map['gameType'],
      success: map['success'] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      description: map['description'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type,
    'amount': amount,
    'gameType': gameType,
    'success': success ? 1 : 0,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'description': description,
    'status': status,
  };
}

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get transaction history for a user (Local + Sync)
  Stream<List<TransactionModel>> getUserTransactions(
    String userId, {
    String? filterType, // 'earning', 'withdrawal', null for all
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async* {
    // 1. Sync withdrawals/referrals from Firestore first
    _syncExternalTransactions(userId);

    // 2. Return local stream
    while (true) {
      final transactions = await _dbHelper.getTransactions(
        userId,
        filterType: filterType,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      yield transactions;
      await Future.delayed(
        const Duration(seconds: 5),
      ); // Poll every 5 seconds for updates
    }
  }

  Future<void> _syncExternalTransactions(String userId) async {
    try {
      // Sync Withdrawals
      final withdrawals = await _firestore
          .collection('withdrawals')
          .where('userId', isEqualTo: userId)
          .limit(20) // Limit sync to recent
          .get();

      for (var doc in withdrawals.docs) {
        final data = doc.data();
        final transaction = TransactionModel(
          id: doc.id,
          userId: userId,
          type: 'withdrawal',
          amount: (data['amount'] ?? 0).toDouble(),
          success: true,
          timestamp:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'pending',
          description: 'Withdrawal Request',
        );
        await _dbHelper.insertTransaction(transaction);
      }

      // Sync Referrals (assuming source='referral')
      final externalEarnings = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'earning')
          .where('source', isEqualTo: 'referral')
          .limit(20)
          .get();

      for (var doc in externalEarnings.docs) {
        final t = TransactionModel.fromFirestore(doc);
        await _dbHelper.insertTransaction(t);
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  // Record a new transaction (Local Only for earnings)
  Future<void> recordTransaction({
    required String userId,
    required String type,
    required double amount,
    String? gameType,
    required bool success,
    String? description,
    required String status,
    Map<String, dynamic>?
    extraData, // To pass full transaction object from worker response
  }) async {
    try {
      final transaction = TransactionModel(
        id:
            extraData?['requestId'] ??
            '${type}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: type,
        amount: amount,
        gameType: gameType,
        success: success,
        timestamp: DateTime.now(),
        description: description,
        status: status,
      );

      await _dbHelper.insertTransaction(transaction);
      debugPrint('✅ Transaction recorded locally');
    } catch (e) {
      debugPrint('❌ Error recording transaction: $e');
      rethrow;
    }
  }

  // Get transaction statistics (From Local DB)
  Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    try {
      final transactions = await _dbHelper.getTransactions(userId, limit: 1000);

      double totalEarned = 0;
      double totalWithdrawn = 0;
      int earningCount = 0;
      int withdrawalCount = 0;

      for (var t in transactions) {
        if (t.type == 'earning' && t.status == 'completed') {
          totalEarned += t.amount;
          earningCount++;
        } else if (t.type == 'withdrawal' && t.status == 'completed') {
          totalWithdrawn += t.amount;
          withdrawalCount++;
        }
      }

      return {
        'totalEarned': totalEarned,
        'totalWithdrawn': totalWithdrawn,
        'balance': totalEarned - totalWithdrawn,
        'earningCount': earningCount,
        'withdrawalCount': withdrawalCount,
        'thisMonthEarnings': _calculateMonthlyEarnings(transactions),
        'thisWeekEarnings': _calculateWeeklyEarnings(transactions),
      };
    } catch (e) {
      debugPrint('Error getting transaction stats: $e');
      rethrow;
    }
  }

  // Calculate this month's earnings
  double _calculateMonthlyEarnings(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    double total = 0;

    for (var t in transactions) {
      if (t.timestamp.isAfter(startOfMonth) && t.type == 'earning') {
        total += t.amount;
      }
    }

    return total;
  }

  // Calculate this week's earnings
  double _calculateWeeklyEarnings(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    double total = 0;

    for (var t in transactions) {
      if (t.timestamp.isAfter(startOfWeek) && t.type == 'earning') {
        total += t.amount;
      }
    }

    return total;
  }
}
