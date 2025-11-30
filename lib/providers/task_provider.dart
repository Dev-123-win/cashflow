import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/cloudflare_workers_service.dart';
import '../services/device_fingerprint_service.dart';
import '../core/di/service_locator.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  int _dailyEarnings = 0;
  final int _dailyCap = 1500; // 1.50 * 1000

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get dailyEarnings => _dailyEarnings;
  int get dailyCap => _dailyCap;
  int get remainingDaily => (_dailyCap - _dailyEarnings).clamp(0, _dailyCap);
  int get completedTasksCount => _tasks.where((t) => t.completed).length;
  int get completedTasks =>
      completedTasksCount; // Alias for backwards compatibility

  final _cloudflareService = getIt<CloudflareWorkersService>();
  final _fingerprintService = getIt<DeviceFingerprintService>();

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

  /// Complete task and record in Cloudflare Worker
  Future<void> completeTask(String userId, String taskId, int reward) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Client-side daily cap check (pre-validation)
      if (_dailyEarnings + reward > _dailyCap) {
        _error = 'Daily limit reached. You can only earn $_dailyCap Coins/day.';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

      final deviceId = await _fingerprintService.getDeviceFingerprint();
      final requestId = 'task_${DateTime.now().millisecondsSinceEpoch}_$taskId';

      // Record task completion in Cloudflare Worker
      final result = await _cloudflareService.recordTaskEarning(
        userId: userId,
        taskId: taskId,
        deviceId: deviceId,
        requestId: requestId,
      );

      if (result['success'] == true) {
        // Update local task state
        final index = _tasks.indexWhere((t) => t.taskId == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(completed: true);
        }

        // Update daily earnings locally
        _dailyEarnings += reward;
        _error = null;
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _error = 'Failed to complete task: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record game result in Cloudflare Worker
  Future<void> recordGameResult(
    String userId,
    String gameId,
    bool won,
    int reward,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Client-side daily cap check
      if (won && _dailyEarnings + reward > _dailyCap) {
        _error = 'Daily limit reached. Come back tomorrow to earn more!';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded for game: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

      final deviceId = await _fingerprintService.getDeviceFingerprint();
      final requestId = 'game_${DateTime.now().millisecondsSinceEpoch}_$gameId';

      // Record game result
      final result = await _cloudflareService.recordGameResult(
        userId: userId,
        gameId: gameId,
        won: won,
        score: reward, // Using reward as score/value
        deviceId: deviceId,
        requestId: requestId,
      );

      if (result['success'] == true) {
        if (won) {
          _dailyEarnings += reward;
        }
        _error = null;
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _error = 'Failed to record game result: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record spin result in Cloudflare Worker
  Future<int> recordSpinResult(String userId, int reward) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Client-side daily cap check
      if (_dailyEarnings + reward > _dailyCap) {
        _error = 'Daily limit reached! Maximum $_dailyCap Coins per day.';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded for spin: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

      final deviceId = await _fingerprintService.getDeviceFingerprint();
      final requestId = 'spin_${DateTime.now().millisecondsSinceEpoch}';

      // Record spin
      final result = await _cloudflareService.executeSpin(
        userId: userId,
        deviceId: deviceId,
        requestId: requestId,
      );

      if (result['success'] == true) {
        // Backend determines reward, but we passed 'reward' as expected?
        // Wait, executeSpin doesn't take 'reward'. Backend calculates it.
        // So the 'reward' passed here is client-side estimation?
        // Or did I change executeSpin to accept reward? No.
        // The backend determines spin result.
        // So we should use the result from backend.
        final earned = result['reward'] as int? ?? 0;

        _dailyEarnings += earned;
        _error = null;
        return earned;
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      _error = 'Failed to record spin: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record ad view in Cloudflare Worker
  Future<void> recordAdView(String userId, String adType, int reward) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Client-side daily cap check
      if (_dailyEarnings + reward > _dailyCap) {
        _error = 'You\'ve reached today\'s earning limit.';
        notifyListeners();
        throw Exception(
          'Daily cap exceeded for ad: $_dailyEarnings + $reward > $_dailyCap',
        );
      }

      final deviceId = await _fingerprintService.getDeviceFingerprint();
      final requestId = 'ad_${DateTime.now().millisecondsSinceEpoch}_$adType';

      // Record ad view
      final result = await _cloudflareService.recordAdView(
        userId: userId,
        adType: adType,
        deviceId: deviceId,
        requestId: requestId,
      );

      if (result['success'] == true) {
        _dailyEarnings += reward;
        _error = null;
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
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
