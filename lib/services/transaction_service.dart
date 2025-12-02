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

  // Removed fromFirestore - now using fromMap for all data
  // Firestore data comes through backend API, not direct Firestore access

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
  // Removed FirebaseFirestore - all Firestore access now through backend API
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get transaction history for a user (Local + Sync)
  Stream<List<TransactionModel>> getUserTransactions(
    String userId, {
    String? filterType, // 'earning', 'withdrawal', null for all
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async* {
    // 1. Note: Sync of withdrawals happens through backend API, not here
    // Backend pushes withdrawal data which gets synced separately

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

  // Note: _syncExternalTransactions removed
  // Withdrawal syncing now happens through backend API
  // No direct Firestore access needed

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
