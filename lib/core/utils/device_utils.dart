import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

/// Device utilities for getting device-specific information
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get unique device identifier
  ///
  /// Returns a unique ID for the device based on the platform
  /// - Android: Uses androidId from device_info_plus
  /// - iOS: Uses identifierForVendor
  /// - Web/Other: Uses a default identifier
  static Future<String> getDeviceId() async {
    try {
      // Try Android first
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } catch (e) {
        debugPrint('Not Android: $e');
      }

      // Try iOS
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      } catch (e) {
        debugPrint('Not iOS: $e');
      }

      // Fallback
      return 'unknown_device';
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return 'error_device_id';
    }
  }

  /// Get device model name for debugging
  static Future<String> getDeviceModel() async {
    try {
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } catch (e) {
        debugPrint('Not Android: $e');
      }

      try {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      } catch (e) {
        debugPrint('Not iOS: $e');
      }

      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Get device OS version
  static Future<String> getOSVersion() async {
    try {
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } catch (e) {
        debugPrint('Not Android: $e');
      }

      try {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } catch (e) {
        debugPrint('Not iOS: $e');
      }

      return 'Unknown OS';
    } catch (e) {
      return 'Unknown OS';
    }
  }
}
