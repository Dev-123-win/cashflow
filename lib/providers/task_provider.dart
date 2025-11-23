import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  double _dailyEarnings = 0;
  final double _dailyCap = 1.50;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get dailyEarnings => _dailyEarnings;
  double get dailyCap => _dailyCap;
  double get remainingDaily => (_dailyCap - _dailyEarnings).clamp(0, _dailyCap);
  int get completedTasksCount => _tasks.where((t) => t.completed).length;
  int get completedTasks =>
      completedTasksCount; // Alias for backwards compatibility

  final _firestoreService = FirestoreService();

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    _error = null;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Complete task and record in Firestore
  Future<void> completeTask(String userId, String taskId, double reward) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Record task completion in Firestore (atomically)
      await _firestoreService.recordTaskCompletion(userId, taskId, reward);

      // Update local task state
      final index = _tasks.indexWhere((t) => t.taskId == taskId);
      if (index != -1) {
        final task = _tasks[index];
        _tasks[index] = Task(
          taskId: task.taskId,
          title: task.title,
          description: task.description,
          type: task.type,
          reward: task.reward,
          timeRequired: task.timeRequired,
          completed: true,
          completedAt: DateTime.now(),
          nextAvailableAt: task.nextAvailableAt,
        );
      }

      // Update daily earnings locally
      _dailyEarnings += reward;
      _error = null;
    } catch (e) {
      _error = 'Failed to complete task: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record game result in Firestore
  Future<void> recordGameResult(
    String userId,
    String gameId,
    bool won,
    double reward,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Record game result in Firestore
      await _firestoreService.recordGameResult(userId, gameId, won, reward);

      if (won) {
        _dailyEarnings += reward;
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to record game result: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record spin result in Firestore
  Future<double> recordSpinResult(String userId, double reward) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Record spin in Firestore
      await _firestoreService.recordSpinResult(userId, reward);

      _dailyEarnings += reward;
      _error = null;
      return reward;
    } catch (e) {
      _error = 'Failed to record spin: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record ad view in Firestore
  Future<void> recordAdView(String userId, String adType, double reward) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Record ad view in Firestore
      await _firestoreService.recordAdView(userId, adType, reward);

      _dailyEarnings += reward;
      _error = null;
    } catch (e) {
      _error = 'Failed to record ad view: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetDailyProgress() {
    _dailyEarnings = 0;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
