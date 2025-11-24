import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages cooldown timers with persistent storage (survives app restart)
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
  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _restorePersistedCooldowns();
      debugPrint('✅ CooldownService initialized');
    } catch (e) {
      debugPrint('❌ CooldownService initialization error: $e');
    }
  }

  /// Restore cooldowns that were persisted (survive app restart)
  Future<void> _restorePersistedCooldowns() async {
    if (_prefs == null) return;

    try {
      final keys = _prefs!.getKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.startsWith('cooldown_')) {
          final expiryTimeStr = _prefs!.getString(key);
          if (expiryTimeStr != null) {
            final expiryTime = DateTime.parse(expiryTimeStr);

            // Check if cooldown has expired
            if (now.isBefore(expiryTime)) {
              // Still active, restore it
              final remaining = expiryTime.difference(now).inSeconds;
              _activeCooldowns[key.replaceFirst('cooldown_', '')] = remaining;
              _startLocalTimer(key.replaceFirst('cooldown_', ''), remaining);
              debugPrint(
                '✅ Restored cooldown from storage: $key ($remaining sec)',
              );
            } else {
              // Expired, remove from storage
              await _prefs!.remove(key);
              debugPrint('✅ Expired cooldown removed: $key');
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error restoring cooldowns: $e');
    }
  }

  /// Start a cooldown timer for a specific activity (with persistence)
  void startCooldown(String userId, String activityType, int durationSeconds) {
    final key = '${userId}_$activityType';

    // Cancel existing timer if any
    _timers[key]?.cancel();

    int remainingSeconds = durationSeconds;
    _activeCooldowns[key] = remainingSeconds;

    // ✅ PERSIST to SharedPreferences (survives app restart)
    final expiryTime = DateTime.now().add(Duration(seconds: durationSeconds));
    _prefs?.setString('cooldown_$key', expiryTime.toIso8601String());

    _timers[key] = Timer.periodic(Duration(seconds: 1), (timer) {
      remainingSeconds--;
      _activeCooldowns[key] = remainingSeconds;

      if (remainingSeconds <= 0) {
        timer.cancel();
        _activeCooldowns.remove(key);
        _timers[key] = null;
        // Remove from persistent storage
        _prefs?.remove('cooldown_$key');
        debugPrint('✅ Cooldown expired: $activityType for $userId');
      }

      notifyListeners();
    });

    debugPrint(
      '⏱️ Cooldown started: $activityType for $userId (${durationSeconds}s)',
    );
  }

  /// Start local timer without updating persistent storage (internal use)
  void _startLocalTimer(String key, int durationSeconds) {
    _timers[key]?.cancel();

    int remainingSeconds = durationSeconds;

    _timers[key] = Timer.periodic(Duration(seconds: 1), (timer) {
      remainingSeconds--;
      _activeCooldowns[key] = remainingSeconds;

      if (remainingSeconds <= 0) {
        timer.cancel();
        _activeCooldowns.remove(key);
        _timers[key] = null;
        _prefs?.remove('cooldown_$key');
      }

      notifyListeners();
    });
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
    _prefs?.remove('cooldown_$key');
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
    // Clear from persistent storage
    if (_prefs != null) {
      final keys = _prefs!.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith('cooldown_')) {
          _prefs!.remove(key);
        }
      }
    }
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
