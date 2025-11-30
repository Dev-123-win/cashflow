import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';

/// CloudflareWorkersService
///
/// Handles all API calls to the Cloudflare Workers backend
/// - Earning endpoints (task, game, ad, spin)
/// - Leaderboard fetching
/// - Withdrawal requests
/// - User statistics
class CloudflareWorkersService {
  static const String _baseUrl =
      'https://earnquest-worker.earnplay12345.workers.dev';
  static const Duration _timeout = Duration(seconds: 30);

  // TODO: In production, use a more secure way to manage secrets (e.g. obfuscation)
  static const String _requestSecret = "dev-secret-key-12345";

  // Singleton instance
  static final CloudflareWorkersService _instance =
      CloudflareWorkersService._internal();

  factory CloudflareWorkersService() {
    return _instance;
  }

  CloudflareWorkersService._internal();

  /// Generate secure headers with Auth Token and HMAC Signature
  Future<Map<String, String>> _getAuthHeaders(String body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // 1. Get Firebase ID Token
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get ID token');
    }

    // 2. Generate Timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // 3. Generate HMAC-SHA256 Signature
    final hmac = Hmac(sha256, utf8.encode(_requestSecret));
    final message = body + timestamp;
    final signature = hmac.convert(utf8.encode(message)).toString();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Request-Signature': signature,
      'X-Request-Timestamp': timestamp,
    };
  }

  /// Record task completion
  Future<Map<String, dynamic>> recordTaskEarning({
    required String userId,
    required String taskId,
    required String deviceId,
    String? requestId,
  }) async {
    try {
      final url = '$_baseUrl/api/earn/task';
      final body = jsonEncode({
        'userId': userId,
        'taskId': taskId,
        'deviceId': deviceId,
        'requestId':
            requestId ??
            'task_${DateTime.now().millisecondsSinceEpoch}_$taskId',
      });

      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Task earning error: $e');
      rethrow;
    }
  }

  /// Record game result
  Future<Map<String, dynamic>> recordGameResult({
    required String userId,
    required String gameId,
    required bool won,
    int score = 0,
    required String deviceId,
    String? requestId,
  }) async {
    try {
      final url = '$_baseUrl/api/earn/game';
      final body = jsonEncode({
        'userId': userId,
        'gameId': gameId,
        'won': won,
        'score': score,
        'deviceId': deviceId,
        'requestId':
            requestId ??
            'game_${DateTime.now().millisecondsSinceEpoch}_$gameId',
      });

      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Game result error: $e');
      rethrow;
    }
  }

  /// Record ad view and earning
  Future<Map<String, dynamic>> recordAdView({
    required String userId,
    required String adType,
    required String deviceId,
    String? requestId,
  }) async {
    try {
      final url = '$_baseUrl/api/earn/ad';
      final body = jsonEncode({
        'userId': userId,
        'adType': adType,
        'deviceId': deviceId,
        'requestId':
            requestId ?? 'ad_${DateTime.now().millisecondsSinceEpoch}_$adType',
      });

      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Ad view error: $e');
      rethrow;
    }
  }

  /// Execute daily spin
  Future<Map<String, dynamic>> executeSpin({
    required String userId,
    required String deviceId,
    String? requestId,
  }) async {
    try {
      final url = '$_baseUrl/api/spin';
      final body = jsonEncode({
        'userId': userId,
        'deviceId': deviceId,
        'requestId':
            requestId ?? 'spin_${DateTime.now().millisecondsSinceEpoch}',
      });

      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Spin error: $e');
      rethrow;
    }
  }

  /// Fetch top leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      limit = limit.clamp(1, 100);
      final url = '$_baseUrl/api/leaderboard?limit=$limit';
      _logRequest('GET', url);

      // Public endpoint, no auth required (or optional)
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      final result = _handleResponse(response);
      final leaderboard = result['leaderboard'] as List? ?? [];

      return leaderboard.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Leaderboard error: $e');
      rethrow;
    }
  }

  /// Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required String userId,
    required int coins,
    required String upiId,
    required String deviceId,
    String? requestId,
  }) async {
    try {
      if (!_isValidUPI(upiId)) {
        throw ArgumentError('Invalid UPI ID format');
      }

      final url = '$_baseUrl/api/withdrawal/request';
      final body = jsonEncode({
        'userId': userId,
        'amount': coins,
        'upiId': upiId,
        'deviceId': deviceId,
        'requestId':
            requestId ?? 'withdrawal_${DateTime.now().millisecondsSinceEpoch}',
      });

      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Withdrawal request error: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats({required String userId}) async {
    try {
      final url = '$_baseUrl/api/user/stats?userId=$userId';
      _logRequest('GET', url);

      // Use auth header if user is logged in
      Map<String, String> headers = {'Accept': 'application/json'};
      if (FirebaseAuth.instance.currentUser != null) {
        final token = await FirebaseAuth.instance.currentUser!.getIdToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('User stats error: $e');
      rethrow;
    }
  }

  /// Create a new user
  Future<Map<String, dynamic>> createUser({
    required String userId,
    required String email,
    required String displayName,
    String? referralCode,
  }) async {
    try {
      final url = '$_baseUrl/api/user/create';
      final body = jsonEncode({
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'referralCode': referralCode,
      });

      // Auth is required for creation too
      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Create user error: $e');
      rethrow;
    }
  }

  /// Check and unlock achievements
  Future<List<String>> checkAchievements({required String userId}) async {
    try {
      final url = '$_baseUrl/api/achievements/check';
      final body = jsonEncode({'userId': userId});

      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      final result = _handleResponse(response);
      final newAchievements = result['newAchievements'] as List? ?? [];
      return newAchievements.cast<String>().toList();
    } catch (e) {
      debugPrint('Check achievements error: $e');
      return [];
    }
  }

  /// Record generic transaction
  Future<Map<String, dynamic>> recordTransaction({
    required String userId,
    required String type,
    required double amount,
    required String description,
    String? gameType,
  }) async {
    try {
      final url = '$_baseUrl/api/transaction/record';
      final body = jsonEncode({
        'userId': userId,
        'type': type,
        'amount': amount,
        'description': description,
        'gameType': gameType,
      });

      final headers = await _getAuthHeaders(body);
      _logRequest('POST', url, body: body);

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Record transaction error: $e');
      rethrow;
    }
  }

  // Health check cache
  bool? _lastHealthStatus;
  DateTime? _lastHealthCheckTime;
  static const Duration _healthCheckCacheDuration = Duration(seconds: 30);

  /// Check API health (with 30-second caching)
  Future<bool> healthCheck() async {
    try {
      // Return cached result if still valid
      if (_lastHealthStatus != null && _lastHealthCheckTime != null) {
        final cacheAge = DateTime.now().difference(_lastHealthCheckTime!);
        if (cacheAge < _healthCheckCacheDuration) {
          debugPrint(
            '✅ Health check: Using cached result ($_lastHealthStatus)',
          );
          return _lastHealthStatus!;
        }
      }

      // Perform fresh health check
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      final isHealthy = response.statusCode == 200;

      // Update cache
      _lastHealthStatus = isHealthy;
      _lastHealthCheckTime = DateTime.now();

      debugPrint('🔄 Health check: Fresh result ($isHealthy)');
      return isHealthy;
    } catch (e) {
      debugPrint('Health check error: $e');

      // Cache the failure for 30 seconds to avoid hammering a down server
      _lastHealthStatus = false;
      _lastHealthCheckTime = DateTime.now();

      return false;
    }
  }

  // ============ PRIVATE HELPERS ============

  /// Parse HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('--------------------------------------------------');
    debugPrint(
      '📥 RESPONSE: ${response.request?.method} ${response.request?.url}',
    );
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('--------------------------------------------------');

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for error
      if (response.statusCode >= 400) {
        throw ApiException(
          message: data['error'] ?? 'Unknown error',
          statusCode: response.statusCode,
        );
      }

      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  /// Log API Request
  void _logRequest(String method, String url, {Object? body}) {
    debugPrint('--------------------------------------------------');
    debugPrint('📤 REQUEST: $method $url');
    if (body != null) {
      debugPrint('Body: $body');
    }
    debugPrint('--------------------------------------------------');
  }

  /// Validate UPI ID format
  bool _isValidUPI(String upiId) {
    final upiRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]{3,}$');
    return upiRegex.hasMatch(upiId);
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
