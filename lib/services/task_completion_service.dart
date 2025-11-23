import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskCompletionService {
  static final TaskCompletionService _instance =
      TaskCompletionService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory TaskCompletionService() {
    return _instance;
  }

  TaskCompletionService._internal();

  // Complete a task
  Future<bool> completeTask(
    String userId,
    String taskId,
    String taskCategory,
  ) async {
    try {
      // Get task details
      final taskSnap = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskSnap.exists) {
        debugPrint('Task not found: $taskId');
        return false;
      }

      final taskData = taskSnap.data() ?? {};
      final reward = (taskData['reward'] ?? 0.5).toDouble();
      final title = taskData['title'] ?? 'Task Completed';

      // Check if user already completed this task today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final completionSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .where('taskId', isEqualTo: taskId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .limit(1)
          .get();

      if (completionSnap.docs.isNotEmpty) {
        debugPrint('Task already completed today: $taskId');
        return false;
      }

      // Check daily task limit
      final dailyCompletionsSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      if (dailyCompletionsSnap.docs.length >= 5) {
        // Max 5 tasks per day
        debugPrint('Daily task limit reached');
        return false;
      }

      // Record task completion
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .add({
            'taskId': taskId,
            'taskTitle': title,
            'taskCategory': taskCategory,
            'reward': reward,
            'completedAt': FieldValue.serverTimestamp(),
            'verified': true,
            'status': 'completed',
          });

      // Add reward to user balance
      await _firestore.collection('users').doc(userId).update({
        'availableBalance': FieldValue.increment(reward),
        'totalEarned': FieldValue.increment(reward),
        'tasksCompletedTotal': FieldValue.increment(1),
      });

      // Record transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add({
            'userId': userId,
            'type': 'earning',
            'amount': reward,
            'gameType': 'task',
            'success': true,
            'timestamp': FieldValue.serverTimestamp(),
            'description': 'Completed task: $title',
            'status': 'completed',
            'taskId': taskId,
            'taskCategory': taskCategory,
          });

      debugPrint('Task completed: $taskId with reward: ₹$reward');
      return true;
    } catch (e) {
      debugPrint('Error completing task: $e');
      return false;
    }
  }

  // Get user's completed tasks
  Stream<List<TaskCompletion>> getUserCompletedTasks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('taskCompletions')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskCompletion.fromFirestore(doc))
              .toList(),
        );
  }

  // Get today's completed tasks count
  Future<int> getTodayCompletedTasksCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      return snap.docs.length;
    } catch (e) {
      debugPrint('Error getting today completed tasks: $e');
      return 0;
    }
  }

  // Get this month's task earnings
  Future<double> getMonthlyTaskEarnings(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .get();

      double total = 0;
      for (var doc in snap.docs) {
        total += (doc['reward'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      debugPrint('Error getting monthly task earnings: $e');
      return 0.0;
    }
  }

  // Get task statistics for user
  Future<TaskStats> getTaskStatistics(String userId) async {
    try {
      final allCompletions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .get();

      int totalCompleted = allCompletions.docs.length;
      double totalEarned = 0;
      Map<String, int> categoryBreakdown = {};

      for (var doc in allCompletions.docs) {
        totalEarned += (doc['reward'] ?? 0).toDouble();
        String category = doc['taskCategory'] ?? 'other';
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayCompletions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      return TaskStats(
        totalCompleted: totalCompleted,
        totalEarned: totalEarned,
        completedToday: todayCompletions.docs.length,
        categoryBreakdown: categoryBreakdown,
        dailyLimit: 5,
        remainingToday: 5 - todayCompletions.docs.length,
      );
    } catch (e) {
      debugPrint('Error getting task statistics: $e');
      return TaskStats(
        totalCompleted: 0,
        totalEarned: 0.0,
        completedToday: 0,
        categoryBreakdown: {},
        dailyLimit: 5,
        remainingToday: 5,
      );
    }
  }

  // Verify task completion (for surveys/videos)
  Future<bool> verifyTaskCompletion(String userId, String taskId) async {
    try {
      // This would be called after user completes survey/video
      // Mark task as verified in Firestore
      final completionSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskCompletions')
          .where('taskId', isEqualTo: taskId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (completionSnap.docs.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('taskCompletions')
            .doc(completionSnap.docs.first.id)
            .update({
              'verified': true,
              'verifiedAt': FieldValue.serverTimestamp(),
            });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying task: $e');
      return false;
    }
  }

  // Get available tasks
  Stream<List<Task>> getAvailableTasks() {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'active')
        .orderBy('reward', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // Get task details
  Future<Task?> getTaskDetails(String taskId) async {
    try {
      final snap = await _firestore.collection('tasks').doc(taskId).get();
      if (snap.exists) {
        return Task.fromFirestore(snap);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting task details: $e');
      return null;
    }
  }
}

// Task model
class Task {
  final String id;
  final String title;
  final String description;
  final String category; // survey, video, install, signup
  final double reward;
  final String actionUrl;
  final String status;
  final DateTime createdAt;
  final int? completionCount;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.reward,
    required this.actionUrl,
    required this.status,
    required this.createdAt,
    this.completionCount,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
      reward: (data['reward'] ?? 0.5).toDouble(),
      actionUrl: data['actionUrl'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completionCount: data['completionCount'],
    );
  }
}

// Task completion model
class TaskCompletion {
  final String taskId;
  final String taskTitle;
  final String taskCategory;
  final double reward;
  final DateTime completedAt;
  final bool verified;
  final String status;

  TaskCompletion({
    required this.taskId,
    required this.taskTitle,
    required this.taskCategory,
    required this.reward,
    required this.completedAt,
    required this.verified,
    required this.status,
  });

  factory TaskCompletion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCompletion(
      taskId: data['taskId'] ?? '',
      taskTitle: data['taskTitle'] ?? '',
      taskCategory: data['taskCategory'] ?? 'other',
      reward: (data['reward'] ?? 0).toDouble(),
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verified: data['verified'] ?? false,
      status: data['status'] ?? 'completed',
    );
  }
}

// Task statistics model
class TaskStats {
  final int totalCompleted;
  final double totalEarned;
  final int completedToday;
  final Map<String, int> categoryBreakdown;
  final int dailyLimit;
  final int remainingToday;

  TaskStats({
    required this.totalCompleted,
    required this.totalEarned,
    required this.completedToday,
    required this.categoryBreakdown,
    required this.dailyLimit,
    required this.remainingToday,
  });
}
