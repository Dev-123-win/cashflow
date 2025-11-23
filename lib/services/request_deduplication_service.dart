import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Record for tracking requests
class RequestRecord {
  final String requestId;
  final String requestHash;
  final DateTime timestamp;
  final bool success;
  final String? transactionId;
  final String? error;

  RequestRecord({
    required this.requestId,
    required this.requestHash,
    required this.timestamp,
    required this.success,
    this.transactionId,
    this.error,
  });
}

/// Prevents duplicate API requests and ensures idempotency
class RequestDeduplicationService {
  static final RequestDeduplicationService _instance =
      RequestDeduplicationService._internal();

  factory RequestDeduplicationService() {
    return _instance;
  }

  RequestDeduplicationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local cache for recent requests (30 seconds TTL)
  final Map<String, RequestRecord> _localCache = {};

  /// Generate unique request ID for idempotency
  String generateRequestId(String userId, String action, Map<String, dynamic> params) {
    // Create hash of action + params to detect duplicate requests
    final payload = jsonEncode({
      'userId': userId,
      'action': action,
      'params': params,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    final hash = sha256.convert(utf8.encode(payload)).toString();
    return 'req_${userId}_${action}_${hash.substring(0, 8)}';
  }

  /// Check if request was recently processed (in local cache)
  RequestRecord? getFromLocalCache(String requestId) {
    final record = _localCache[requestId];

    if (record != null) {
      // Check if within 30 seconds
      if (DateTime.now().difference(record.timestamp).inSeconds < 30) {
        debugPrint('✅ Request found in local cache: $requestId');
        return record;
      } else {
        // Expired, remove from cache
        _localCache.remove(requestId);
      }
    }

    return null;
  }

  /// Check if request was recently processed (in Firestore - backup)
  Future<RequestRecord?> getFromFirestoreCache(String requestId) async {
    try {
      final doc = await _firestore
          .collection('requestCache')
          .doc(requestId)
          .get(const GetOptions(source: Source.cache)); // Use cache to save quota

      if (doc.exists) {
        final data = doc.data()!;
        final record = RequestRecord(
          requestId: data['requestId'],
          requestHash: data['requestHash'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          success: data['success'],
          transactionId: data['transactionId'],
          error: data['error'],
        );

        // Check if within 30 seconds
        if (DateTime.now().difference(record.timestamp).inSeconds < 30) {
          debugPrint('✅ Request found in Firestore cache: $requestId');
          return record;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Firestore cache check failed (using local): $e');
    }

    return null;
  }

  /// Record a request result for deduplication
  Future<void> recordRequest({
    required String requestId,
    required String requestHash,
    required bool success,
    String? transactionId,
    String? error,
  }) async {
    final record = RequestRecord(
      requestId: requestId,
      requestHash: requestHash,
      timestamp: DateTime.now(),
      success: success,
      transactionId: transactionId,
      error: error,
    );

    // Store in local cache
    _localCache[requestId] = record;

    // Also store in Firestore for backup (with TTL of 24 hours via Cloud Firestore TTL policy)
    try {
      await _firestore.collection('requestCache').doc(requestId).set({
        'requestId': requestId,
        'requestHash': requestHash,
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
        'transactionId': transactionId,
        'error': error,
      });

      debugPrint('✅ Request recorded for deduplication: $requestId');
    } catch (e) {
      debugPrint('⚠️ Failed to record request in Firestore: $e');
      // Continue anyway - local cache will handle it
    }
  }

  /// Clear old entries from local cache
  void clearOldEntries() {
    final now = DateTime.now();
    _localCache.removeWhere((key, record) =>
        now.difference(record.timestamp).inSeconds > 60);
    debugPrint('✅ Cleared old cache entries');
  }
}
