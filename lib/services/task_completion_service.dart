import 'package:flutter/material.dart';
import 'cloudflare_workers_service.dart';
import 'device_fingerprint_service.dart';

/// TaskCompletionService - Routes all task operations through Cloudflare Workers
///
/// Architecture: UI -> Cloudflare Workers -> Firestore
/// This service no longer writes directly to Firestore, all operations go through the backend
class TaskCompletionService {
  static final TaskCompletionService _instance =
      TaskCompletionService._internal();

  factory TaskCompletionService() {
    return _instance;
  }

  TaskCompletionService._internal();

  final CloudflareWorkersService _cloudflareService =
      CloudflareWorkersService();
  final DeviceFingerprintService _deviceFingerprint =
      DeviceFingerprintService();

  // ============ TASK COMPLETION ============

  /// Complete a task via Cloudflare Workers backend
  ///
  /// This method:
  /// 1. Gets device fingerprint
  /// 2. Sends request to Cloudflare Workers
  /// 3. Backend validates and writes to Firestore
  /// 4. Backend enforces limits (5 tasks/day, no duplicates)
  Future<bool> completeTask(
    String userId,
    String taskId,
    String taskCategory,
  ) async {
    try {
      final deviceId = await _deviceFingerprint.getDeviceFingerprint();

      // Route through Cloudflare Workers backend
      final result = await _cloudflareService.recordTaskEarning(
        userId: userId,
        taskId: taskId,
        deviceId: deviceId,
      );

      // Backend returns success response
      final success = result['success'] ?? false;
      if (success) {
        final reward = result['reward'] ?? 0.0;
        debugPrint(
          '✅ Task completed: $taskId with reward: ₹$reward via backend',
        );
        return true;
      } else {
        final error = result['error'] ?? 'Unknown error';
        debugPrint('⚠️ Task completion failed: $error');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error completing task: $e');
      return false;
    }
  }

  // Note: The following methods (getUserCompletedTasks, getTodayCompletedTasksCount, etc.)
  // are READ operations that can still query Firestore directly for better performance
  // Only WRITE operations need to go through Cloudflare Workers

  // These methods are removed as they would require direct Firestore access
  // The UI should fetch user stats from CloudflareWorkersService.getUserStats() instead

  /// Get user stats including task completions
  /// Routes through backend for consistency
  Future<Map<String, dynamic>> getUserTaskStats(String userId) async {
    try {
      return await _cloudflareService.getUserStats(userId: userId);
    } catch (e) {
      debugPrint('❌ Error getting user task stats: $e');
      rethrow;
    }
  }
}
