import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../core/di/service_locator.dart';

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

  final _firestoreService = getIt<FirestoreService>();

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

      // ✅ CRITICAL: Check daily cap BEFORE recording (client-side validation)
      if (_dailyEarnings + reward > _dailyCap) {
        _error = 'Daily limit reached. You can only earn ₹$_dailyCap/day.';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

      // Record task completion in Firestore (atomically)
      // ⚠️ Server also validates daily cap - if fails, UI is NOT updated
      await _firestoreService.recordTaskCompletion(userId, taskId, reward);

      // Update local task state
      final index = _tasks.indexWhere((t) => t.taskId == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(completed: true);
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

      // ✅ CRITICAL: Check daily cap BEFORE recording
      if (won && _dailyEarnings + reward > _dailyCap) {
        _error = 'Daily limit reached. Come back tomorrow to earn more!';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded for game: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

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

      // ✅ CRITICAL: Check daily cap BEFORE recording
      if (_dailyEarnings + reward > _dailyCap) {
        _error = 'Daily limit reached! Maximum ₹$_dailyCap per day.';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded for spin: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

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

      // ✅ CRITICAL: Check daily cap BEFORE recording ad reward
      if (_dailyEarnings + reward > _dailyCap) {
        _error = 'You\'ve reached today\'s earning limit.';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded for ad: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

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
