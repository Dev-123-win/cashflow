import 'package:flutter/foundation.dart';

/// CacheService - In-memory caching to reduce Firestore reads
///
/// This service provides TTL-based caching for Firestore data
/// to significantly reduce read operations and stay within free tier limits.
///
/// Usage:
/// ```dart
/// final cache = CacheService();
///
/// // Set cache
/// cache.set('user_123', userData, Duration(minutes: 5));
///
/// // Get cache
/// final user = cache.get<User>('user_123');
/// if (user != null) {
///   // Use cached data
/// } else {
///   // Fetch from Firestore
/// }
/// ```
class CacheService {
  // Singleton instance
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  // In-memory cache storage
  final Map<String, CachedData> _cache = {};

  /// Get cached data by key
  /// Returns null if cache miss or expired
  T? get<T>(String key) {
    final cached = _cache[key];

    if (cached == null) {
      debugPrint('Cache MISS: $key');
      return null;
    }

    if (cached.isExpired) {
      debugPrint('Cache EXPIRED: $key');
      _cache.remove(key);
      return null;
    }

    debugPrint('Cache HIT: $key');
    return cached.data as T;
  }

  /// Set cache with TTL (Time To Live)
  void set<T>(String key, T data, Duration ttl) {
    _cache[key] = CachedData(data: data, expiresAt: DateTime.now().add(ttl));
    debugPrint('Cache SET: $key (TTL: ${ttl.inMinutes}m)');
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    debugPrint('Cache INVALIDATED: $key');
  }

  /// Invalidate all cache entries matching pattern
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    debugPrint(
      'Cache INVALIDATED pattern: $pattern (${keysToRemove.length} entries)',
    );
  }

  /// Clear all cache
  void clear() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('Cache CLEARED: $count entries');
  }

  /// Get cache statistics
  CacheStats getStats() {
    int expired = 0;
    int valid = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expired++;
      } else {
        valid++;
      }
    }

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: valid,
      expiredEntries: expired,
    );
  }

  /// Clean up expired entries
  void cleanup() {
    final keysToRemove = <String>[];

    _cache.forEach((key, value) {
      if (value.isExpired) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    debugPrint('Cache CLEANUP: Removed ${keysToRemove.length} expired entries');
  }
}

/// Cached data wrapper with expiration
class CachedData {
  final dynamic data;
  final DateTime expiresAt;

  CachedData({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeToLive {
    final now = DateTime.now();
    if (isExpired) return Duration.zero;
    return expiresAt.difference(now);
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
  });

  double get hitRate {
    if (totalEntries == 0) return 0.0;
    return validEntries / totalEntries;
  }

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, expired: $expiredEntries, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
