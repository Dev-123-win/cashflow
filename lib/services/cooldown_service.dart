import 'dart:async';
import 'package:flutter/material.dart';

/// Manages cooldown timers and state changes across the app
class CooldownService extends ChangeNotifier {
  static final CooldownService _instance = CooldownService._internal();

  factory CooldownService() {
    return _instance;
  }

  CooldownService._internal();

  // Cooldown durations (in seconds)
  static const int gameCooldownSeconds = 300; // 5 minutes
  static const int taskCooldownSeconds = 60; // 1 minute
  static const int adCooldownSeconds = 30; // 30 seconds

  // Active cooldowns: key = userId_activityType, value = remaining seconds
  final Map<String, int> _activeCooldowns = {};
  final Map<String, Timer?> _timers = {};

  /// Start a cooldown timer for a specific activity
  void startCooldown(String userId, String activityType, int durationSeconds) {
    final key = '${userId}_$activityType';

    // Cancel existing timer if any
    _timers[key]?.cancel();

    int remainingSeconds = durationSeconds;
    _activeCooldowns[key] = remainingSeconds;

    _timers[key] = Timer.periodic(Duration(seconds: 1), (timer) {
      remainingSeconds--;
      _activeCooldowns[key] = remainingSeconds;

      if (remainingSeconds <= 0) {
        timer.cancel();
        _activeCooldowns.remove(key);
        _timers[key] = null;
        debugPrint('✅ Cooldown expired: $activityType for $userId');
      }

      notifyListeners();
    });

    debugPrint(
      '⏱️ Cooldown started: $activityType for $userId (${durationSeconds}s)',
    );
  }

  /// Get remaining cooldown time in seconds
  int getRemainingCooldown(String userId, String activityType) {
    final key = '${userId}_$activityType';
    return _activeCooldowns[key] ?? 0;
  }

  /// Check if activity is on cooldown
  bool isOnCooldown(String userId, String activityType) {
    final key = '${userId}_$activityType';
    return _activeCooldowns.containsKey(key) && _activeCooldowns[key]! > 0;
  }

  /// Cancel a cooldown
  void cancelCooldown(String userId, String activityType) {
    final key = '${userId}_$activityType';
    _timers[key]?.cancel();
    _timers[key] = null;
    _activeCooldowns.remove(key);
    notifyListeners();
  }

  /// Format cooldown time for display
  String formatCooldown(int seconds) {
    if (seconds <= 0) return 'Ready!';

    if (seconds < 60) {
      return '${seconds}s';
    }

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  /// Clear all cooldowns (for testing/logout)
  void clearAllCooldowns() {
    _timers.forEach((_, timer) => timer?.cancel());
    _timers.clear();
    _activeCooldowns.clear();
    debugPrint('✅ All cooldowns cleared');
    notifyListeners();
  }

  @override
  void dispose() {
    clearAllCooldowns();
    super.dispose();
  }
}

/// Activity type constants
class ActivityType {
  static const String gameTicTacToe = 'game_tictactoe';
  static const String gameMemory = 'game_memory';
  static const String gameQuiz = 'game_quiz';
  static const String watchAd = 'watch_ad';
  static const String taskCompletion = 'task_completion';
  static const String spinWheel = 'spin_wheel';
}
