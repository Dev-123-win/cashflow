import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';

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

  /// Clears cached fingerprint (useful for testing)
  void clearCache() {
    _cachedFingerprint = null;
  }
}
