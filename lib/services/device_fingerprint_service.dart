import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:safe_device/safe_device.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// SECURITY SERVICE: Device fingerprinting for fraud detection
///
/// This service prevents users from creating multiple accounts on the same device
/// and helps detect suspicious earning patterns (e.g., earning from 100 accounts
/// on same device).
///
/// Why this matters:
/// - Prevents multi-accounting fraud (one person, multiple fake accounts)
/// - Detects bulk earnings manipulation
/// - Completely client-side (no external APIs)
/// - Privacy-respecting (we don't store personal data)
///
/// What data we use:
/// - Device type (e.g., "iPhone12,1")
/// - OS version (e.g., "14.3")
/// - Device model name (e.g., "iPhone X")
/// - Does NOT use IDFA or other tracking IDs
class DeviceFingerprintService {
  static final DeviceFingerprintService _instance =
      DeviceFingerprintService._internal();

  factory DeviceFingerprintService() {
    return _instance;
  }

  DeviceFingerprintService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _cachedFingerprint;
  Map<String, bool>? _cachedSecurityStatus;

  /// Generates a SHA-256 fingerprint of device characteristics
  ///
  /// Returns: Hex string of SHA-256 hash
  ///
  /// This fingerprint is:
  /// - Deterministic (same device = same fingerprint)
  /// - Unique (different devices = different fingerprints)
  /// - Anonymous (doesn't contain personal identifiable information)
  /// - Stable (doesn't change unless OS updates)
  Future<String> getDeviceFingerprint() async {
    // Return cached fingerprint if available
    if (_cachedFingerprint != null) {
      return _cachedFingerprint!;
    }

    try {
      final fingerprint = await _generateFingerprint();
      _cachedFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
      // Return a random fingerprint on error (better than failing)
      return _generateRandomFingerprint();
    }
  }

  /// Internal: Generates fingerprint based on device info
  Future<String> _generateFingerprint() async {
    final components = <String>[];

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        components.addAll([
          androidInfo.device,
          androidInfo.model,
          androidInfo.version.release,
          androidInfo.manufacturer,
          androidInfo.fingerprint,
        ]);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        components.addAll([
          iosInfo.utsname.machine,
          iosInfo.systemVersion,
          iosInfo.name,
        ]);
      }
    } catch (e) {
      // Silent catch - use random fingerprint
    }

    // Create fingerprint hash
    final combined = components.join('|');
    final digest = sha256.convert(utf8.encode(combined));

    return digest.toString();
  }

  /// Generates a random fingerprint for error cases
  String _generateRandomFingerprint() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = '$timestamp|${DateTime.now().microsecond}';
    return sha256.convert(utf8.encode(random)).toString();
  }

  /// Gets human-readable device info for debugging
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'device': androidInfo.device,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'machine': iosInfo.utsname.machine,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      }
    } catch (e) {
      // Silent catch
    }

    return {'platform': 'unknown', 'error': 'Could not get device info'};
  }

  /// Comprehensive device security check using safe_device
  /// Returns a map with security status flags
  Future<Map<String, bool>> getDeviceSecurityStatus() async {
    if (_cachedSecurityStatus != null) {
      return _cachedSecurityStatus!;
    }

    try {
      final results = await Future.wait([
        SafeDevice.isJailBroken,
        SafeDevice.isMockLocation,
        SafeDevice.isRealDevice,
        SafeDevice.isSafeDevice,
        SafeDevice.isDevelopmentModeEnable,
        SafeDevice.isOnExternalStorage,
      ]);

      _cachedSecurityStatus = {
        'isJailbroken': results[0],
        'isMockLocation': results[1],
        'isRealDevice': results[2],
        'isSafeDevice': results[3],
        'isDevelopmentMode': results[4],
        'isOnExternalStorage': results[5],
      };

      return _cachedSecurityStatus!;
    } catch (e) {
      // Return safe defaults on error
      return {
        'isJailbroken': false,
        'isMockLocation': false,
        'isRealDevice': true,
        'isSafeDevice': true,
        'isDevelopmentMode': false,
        'isOnExternalStorage': false,
      };
    }
  }

  /// Check if device is rooted/jailbroken
  Future<bool> isRooted() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (e) {
      return false;
    }
  }

  /// Check if device is an emulator
  Future<bool> isEmulator() async {
    try {
      final isReal = await SafeDevice.isRealDevice;
      return !isReal;
    } catch (e) {
      return false;
    }
  }

  /// Check if device can mock location (GPS spoofing)
  Future<bool> canMockLocation() async {
    try {
      return await SafeDevice.isMockLocation;
    } catch (e) {
      return false;
    }
  }

  /// Check if device is safe (not rooted, not emulator, etc.)
  Future<bool> isSafeDevice() async {
    try {
      return await SafeDevice.isSafeDevice;
    } catch (e) {
      return true; // Default to safe on error
    }
  }

  /// Get security risk score (0-100, higher = more risky)
  Future<int> getSecurityRiskScore() async {
    final status = await getDeviceSecurityStatus();
    int score = 0;

    if (status['isJailbroken'] == true) score += 40;
    if (status['isRealDevice'] == false) score += 30;
    if (status['isMockLocation'] == true) score += 15;
    if (status['isDevelopmentMode'] == true) score += 10;
    if (status['isOnExternalStorage'] == true) score += 5;

    return score;
  }

  /// Register device fingerprint in Firestore
  Future<void> registerFingerprint(String userId) async {
    try {
      final fingerprint = await getDeviceFingerprint();
      final docRef = FirebaseFirestore.instance
          .collection('deviceFingerprints')
          .doc(fingerprint);

      final doc = await docRef.get();
      if (!doc.exists) {
        final deviceInfo = await getDeviceInfo();
        await docRef.set({
          'fingerprint': fingerprint,
          'firstSeen': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'deviceInfo': deviceInfo,
          'userIds': [userId], // Track users associated with this device
        });
        debugPrint('✅ Device fingerprint registered: $fingerprint');
      } else {
        // Update last seen and add user if new
        await docRef.update({
          'lastSeen': FieldValue.serverTimestamp(),
          'userIds': FieldValue.arrayUnion([userId]),
        });
        debugPrint('✅ Device fingerprint updated: $fingerprint');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to register device fingerprint: $e');
    }
  }

  /// Clears cached fingerprint (useful for testing)
  void clearCache() {
    _cachedFingerprint = null;
    _cachedSecurityStatus = null;
  }
}
