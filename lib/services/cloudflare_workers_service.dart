import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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

  // Singleton instance
  static final CloudflareWorkersService _instance =
      CloudflareWorkersService._internal();

  factory CloudflareWorkersService() {
    return _instance;
  }

  CloudflareWorkersService._internal();

  /// Record task completion
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  /// - taskId: Task identifier
  /// - deviceId: Device fingerprint
  ///
  /// Returns: Earnings record with new balance
  Future<Map<String, dynamic>> recordTaskEarning({
    required String userId,
    required String taskId,
    required String deviceId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/earn/task'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'taskId': taskId,
              'deviceId': deviceId,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Task earning error: $e');
      rethrow;
    }
  }

  /// Record game result
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  /// - gameId: Game identifier
  /// - won: Whether game was won
  /// - score: Game score (optional)
  /// - deviceId: Device fingerprint
  ///
  /// Returns: Game result with earnings
  Future<Map<String, dynamic>> recordGameResult({
    required String userId,
    required String gameId,
    required bool won,
    int score = 0,
    required String deviceId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/earn/game'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'gameId': gameId,
              'won': won,
              'score': score,
              'deviceId': deviceId,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Game result error: $e');
      rethrow;
    }
  }

  /// Record ad view and earning
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  /// - adType: Type of ad (rewarded, interstitial, etc.)
  /// - deviceId: Device fingerprint
  ///
  /// Returns: Ad earning record
  Future<Map<String, dynamic>> recordAdView({
    required String userId,
    required String adType,
    required String deviceId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/earn/ad'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'adType': adType,
              'deviceId': deviceId,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Ad view error: $e');
      rethrow;
    }
  }

  /// Execute daily spin
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  /// - deviceId: Device fingerprint
  ///
  /// Returns: Spin result with reward amount
  Future<Map<String, dynamic>> executeSpin({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/spin'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'userId': userId, 'deviceId': deviceId}),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Spin error: $e');
      rethrow;
    }
  }

  /// Fetch top leaderboard
  ///
  /// Parameters:
  /// - limit: Number of top users to fetch (1-100, default 50)
  ///
  /// Returns: List of leaderboard entries
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      // Clamp limit
      limit = limit.clamp(1, 100);

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/leaderboard?limit=$limit'),
            headers: {'Accept': 'application/json'},
          )
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
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  /// - amount: Withdrawal amount in rupees (50-5000)
  /// - upiId: UPI ID for payment (e.g., user@bank)
  /// - deviceId: Device fingerprint
  ///
  /// Returns: Withdrawal request confirmation
  Future<Map<String, dynamic>> requestWithdrawal({
    required String userId,
    required double amount,
    required String upiId,
    required String deviceId,
  }) async {
    try {
      // Validate UPI format
      if (!_isValidUPI(upiId)) {
        throw ArgumentError('Invalid UPI ID format');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/withdrawal/request'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'amount': amount,
              'upiId': upiId,
              'deviceId': deviceId,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Withdrawal request error: $e');
      rethrow;
    }
  }

  /// Get user statistics
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  ///
  /// Returns: User daily/monthly stats and earning limits
  Future<Map<String, dynamic>> getUserStats({required String userId}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/user/stats?userId=$userId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('User stats error: $e');
      rethrow;
    }
  }

  /// Create a new user
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  /// - email: User email
  /// - displayName: User display name
  /// - referralCode: Optional referral code
  ///
  /// Returns: Created user data
  Future<Map<String, dynamic>> createUser({
    required String userId,
    required String email,
    required String displayName,
    String? referralCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/user/create'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'email': email,
              'displayName': displayName,
              'referralCode': referralCode,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Create user error: $e');
      rethrow;
    }
  }

  /// Check and unlock achievements
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  ///
  /// Returns: List of newly unlocked achievement IDs
  Future<List<String>> checkAchievements({required String userId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/achievements/check'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'userId': userId}),
          )
          .timeout(_timeout);

      final result = _handleResponse(response);
      final newAchievements = result['newAchievements'] as List? ?? [];
      return newAchievements.cast<String>().toList();
    } catch (e) {
      debugPrint('Check achievements error: $e');
      // Return empty list on error to avoid blocking UI
      return [];
    }
  }

  /// Record generic transaction
  ///
  /// Parameters:
  /// - userId: User ID from Firebase Auth
  /// - type: Transaction type
  /// - amount: Amount
  /// - description: Description
  ///
  /// Returns: Transaction record
  Future<Map<String, dynamic>> recordTransaction({
    required String userId,
    required String type,
    required double amount,
    required String description,
    String? gameType,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/transaction/record'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'type': type,
              'amount': amount,
              'description': description,
              'gameType': gameType,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('Record transaction error: $e');
      rethrow;
    }
  }

  /// Check API health
  ///
  /// Returns: Health status
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check error: $e');
      return false;
    }
  }

  // ============ PRIVATE HELPERS ============

  /// Parse HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

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
