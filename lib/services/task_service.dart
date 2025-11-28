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
            reward: (data['reward'] ?? 0.0).toDouble(),
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

  List<Task> _getDefaultTasks() {
    return [
      Task(
        taskId: 'survey_1',
        title: 'Daily Survey',
        description: 'Answer 5 quick questions',
        reward: 0.10,
        icon: 'https://img.icons8.com/color/96/survey.png',
        actionUrl: 'https://example.com/survey',
        category: 'survey',
        duration: '2 min',
      ),
      Task(
        taskId: 'share_1',
        title: 'Share & Earn',
        description: 'Share app with friends',
        reward: 0.15,
        icon: 'https://img.icons8.com/color/96/share.png',
        actionUrl: 'https://example.com/share',
        category: 'social',
        duration: '1 min',
      ),
      Task(
        taskId: 'rating_1',
        title: 'Rate Us',
        description: 'Give us 5 stars',
        reward: 0.20,
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
