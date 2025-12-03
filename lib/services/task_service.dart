import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'cache_service.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cache = CacheService();

  /// Fetch tasks from Firestore (with caching)
  /// Cache TTL: 1 hour (Tasks don't change often)
  Future<List<Task>> getTasks() async {
    try {
      // Check cache first
      final cached = _cache.get<List<Task>>('tasks_list');
      if (cached != null) {
        return cached;
      }

      // Cache miss - fetch from Firestore
      final snapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'active')
          .get();

      List<Task> tasks;
      if (snapshot.docs.isEmpty) {
        // Fallback to default tasks if collection is empty (First run)
        tasks = _getDefaultTasks();
      } else {
        tasks = snapshot.docs.map((doc) {
          final data = doc.data();
          return Task(
            taskId: doc.id,
            title: data['title'] ?? 'Task',
            description: data['description'] ?? '',
            reward: (data['reward'] ?? 0).toInt(),
            icon: _getIconUrl(data['icon']),
            actionUrl: data['actionUrl'] ?? '',
            category: data['category'] ?? 'general',
            duration: data['duration'] ?? '1 min',
          );
        }).toList();
      }

      // Cache for 1 hour
      _cache.set('tasks_list', tasks, const Duration(hours: 1));

      return tasks;
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return _getDefaultTasks(); // Fallback
    }
  }

  /// Complete a task and update user balance
  ///
  /// ❌ DEPRECATED: This method writes directly to Firestore,
  /// bypassing the Cloudflare Worker backend (no validation, no audit trail).
  /// Use CloudflareWorkersService().recordTaskEarning() instead.
  @Deprecated('Use CloudflareWorkersService().recordTaskEarning() instead')
  Future<void> completeTask(String userId, String taskId, int reward) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'coins': FieldValue.increment(reward),
        'totalEarnings': FieldValue.increment(
          reward / 1000,
        ), // Keep tracking total earnings in currency for analytics if needed, or just coins
        'completedTasks': FieldValue.increment(1),
        'completedTaskIds': FieldValue.arrayUnion([taskId]),
      });
    } catch (e) {
      debugPrint('Error completing task: $e');
      rethrow;
    }
  }

  List<Task> _getDefaultTasks() {
    return [
      Task(
        taskId: 'survey_1',
        title: 'Daily Survey',
        description: 'Answer 5 quick questions',
        reward: 100, // 0.10 * 1000
        icon: 'https://img.icons8.com/color/96/survey.png',
        actionUrl: 'https://example.com/survey',
        category: 'survey',
        duration: '2 min',
      ),
      Task(
        taskId: 'share_1',
        title: 'Share & Earn',
        description: 'Share app with friends',
        reward: 150, // 0.15 * 1000
        icon: 'https://img.icons8.com/color/96/share.png',
        actionUrl: 'https://example.com/share',
        category: 'social',
        duration: '1 min',
      ),
      Task(
        taskId: 'rating_1',
        title: 'Rate Us',
        description: 'Give us 5 stars',
        reward: 200, // 0.20 * 1000
        icon: 'https://img.icons8.com/color/96/star.png',
        actionUrl: 'https://example.com/rate',
        category: 'social',
        duration: '1 min',
      ),
    ];
  }

  String _getIconUrl(String? iconName) {
    switch (iconName) {
      case 'assignment':
        return 'https://img.icons8.com/color/96/survey.png';
      case 'share':
        return 'https://img.icons8.com/color/96/share.png';
      case 'star':
        return 'https://img.icons8.com/color/96/star.png';
      case 'video':
        return 'https://img.icons8.com/color/96/video.png';
      case 'game':
        return 'https://img.icons8.com/color/96/controller.png';
      default:
        return 'https://img.icons8.com/color/96/task.png';
    }
  }
}
