import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'cloudflare_workers_service.dart';
import 'device_fingerprint_service.dart';

// ============ TIC-TAC-TOE GAME (Top-level class) ============

/// Tic-Tac-Toe AI logic
class TicTacToeGame {
  late List<String> board; // Empty = '', Player = 'X', AI = 'O'
  bool isGameOver = false;
  String? winner; // 'X', 'O', or 'draw'

  TicTacToeGame() {
    resetBoard();
  }

  void resetBoard() {
    board = List.filled(9, '');
    isGameOver = false;
    winner = null;
  }

  /// Player makes a move
  bool playerMove(int index) {
    if (board[index].isNotEmpty || isGameOver) return false;

    board[index] = 'X';
    _checkGameState();

    if (!isGameOver) {
      aiMove();
    }

    return true;
  }

  /// AI makes a move (easier difficulty - intentionally makes suboptimal moves)
  void aiMove() {
    if (isGameOver) return;

    // 30% chance to play random move (makes AI beatable)
    if (Random().nextDouble() < 0.3) {
      final available = board
          .asMap()
          .entries
          .where((e) => e.value.isEmpty)
          .map((e) => e.key)
          .toList();
      if (available.isNotEmpty) {
        board[available[Random().nextInt(available.length)]] = 'O';
        _checkGameState();
        return;
      }
    }

    // Try to win (50% of the time)
    final winMove = _findWinningMove('O');
    if (winMove != -1 && Random().nextDouble() < 0.5) {
      board[winMove] = 'O';
      _checkGameState();
      return;
    }

    // Block player from winning (40% of the time)
    final blockMove = _findWinningMove('X');
    if (blockMove != -1 && Random().nextDouble() < 0.4) {
      board[blockMove] = 'O';
      _checkGameState();
      return;
    }

    // Take center if available (60% chance)
    if (board[4].isEmpty && Random().nextDouble() < 0.6) {
      board[4] = 'O';
      _checkGameState();
      return;
    }

    // Take a corner
    final corners = [0, 2, 6, 8].where((i) => board[i].isEmpty).toList();
    if (corners.isNotEmpty) {
      board[corners[Random().nextInt(corners.length)]] = 'O';
      _checkGameState();
      return;
    }

    // Take any available space
    final available = board
        .asMap()
        .entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();
    if (available.isNotEmpty) {
      board[available[Random().nextInt(available.length)]] = 'O';
      _checkGameState();
    }
  }

  int _findWinningMove(String player) {
    const winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (final combo in winningCombos) {
      final values = [board[combo[0]], board[combo[1]], board[combo[2]]];
      final playerCount = values.where((v) => v == player).length;
      final emptyCount = values.where((v) => v.isEmpty).length;

      if (playerCount == 2 && emptyCount == 1) {
        return combo.firstWhere((i) => board[i].isEmpty);
      }
    }

    return -1;
  }

  void _checkGameState() {
    // Check for winner
    const winningCombos = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final combo in winningCombos) {
      final values = [board[combo[0]], board[combo[1]], board[combo[2]]];
      if (values[0].isNotEmpty &&
          values[0] == values[1] &&
          values[1] == values[2]) {
        winner = values[0];
        isGameOver = true;
        return;
      }
    }

    // Check for draw
    if (board.every((cell) => cell.isNotEmpty)) {
      winner = 'draw';
      isGameOver = true;
      return;
    }
  }

  bool playerWon() => winner == 'X';
}

// ============ MEMORY MATCH GAME (Top-level class) ============

class MemoryMatchGame {
  late List<String> cards; // emoji list
  late List<bool> revealed;
  late List<bool> matched;
  int moves = 0;
  int matchedPairs = 0;

  MemoryMatchGame() {
    initializeGame();
  }

  void initializeGame() {
    final cardEmojis = [
      '🍎',
      '🍊',
      '🍋',
      '🍌',
      '🍓',
      '🍉',
      '🍎',
      '🍊',
      '🍋',
      '🍌',
      '🍓',
      '🍉',
    ];
    cards = cardEmojis..shuffle();
    revealed = List.filled(12, false);
    matched = List.filled(12, false);
    moves = 0;
    matchedPairs = 0;
  }

  bool revealCard(int index) {
    if (revealed[index] || matched[index]) return false;
    revealed[index] = true;
    return true;
  }

  bool checkMatch(int index1, int index2) {
    final isMatch = cards[index1] == cards[index2];
    if (isMatch) {
      matched[index1] = true;
      matched[index2] = true;
      matchedPairs++;
    }
    return isMatch;
  }

  void resetCards(int index1, int index2) {
    revealed[index1] = false;
    revealed[index2] = false;
  }

  bool isGameOver() => matchedPairs == 6;

  double getAccuracy() {
    if (moves == 0) return 0;
    return (matchedPairs / moves) * 100;
  }
}

/// Game Service for managing game logic, cooldowns, and rewards
class GameService {
  static final GameService _instance = GameService._internal();

  factory GameService() {
    return _instance;
  }

  GameService._internal();

  final CloudflareWorkersService _cloudflareService =
      CloudflareWorkersService();
  final DeviceFingerprintService _deviceFingerprint =
      DeviceFingerprintService();

  // Game cooldown constants (in minutes)
  static const int gameCooldownMinutes = 5;
  static const int maxGamesPerDay = 10;

  // Game rewards
  static const double gameWinReward = 0.50;
  static const double gameLossReward = 0.10;

  // Cooldown tracking
  final Map<String, DateTime> _gameCooldowns = {};

  // ============ COOLDOWN MANAGEMENT ============

  /// Check if user can play a game (cooldown expired)
  bool canPlayGame(String userId) {
    final lastGameTime = _gameCooldowns[userId];
    if (lastGameTime == null) return true;

    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastGameTime).inMinutes;
    return elapsedMinutes >= gameCooldownMinutes;
  }

  /// Get remaining cooldown time in seconds
  int getRemainingCooldownSeconds(String userId) {
    final lastGameTime = _gameCooldowns[userId];
    if (lastGameTime == null) return 0;

    final now = DateTime.now();
    final elapsedSeconds = now.difference(lastGameTime).inSeconds;
    final remainingSeconds = (gameCooldownMinutes * 60) - elapsedSeconds;

    return max(0, remainingSeconds);
  }

  /// Set cooldown for user after playing a game
  void setCooldown(String userId) {
    _gameCooldowns[userId] = DateTime.now();
    debugPrint('⏱️ Game cooldown set for $userId (${gameCooldownMinutes}min)');
  }

  /// Clear cooldown (for testing)
  void clearCooldown(String userId) {
    _gameCooldowns.remove(userId);
    debugPrint('✅ Game cooldown cleared for $userId');
  }

  /// Create new Tic-Tac-Toe game
  TicTacToeGame createTicTacToeGame() {
    return TicTacToeGame();
  }

  /// Create new Memory Match game
  MemoryMatchGame createMemoryMatchGame() {
    return MemoryMatchGame();
  }

  // ============ GAME RESULT RECORDING ============

  /// Record game result and update user balance
  Future<void> recordGameWin(
    String userId,
    String gameId, {
    double? customReward,
  }) async {
    try {
      final reward = customReward ?? gameWinReward;
      final deviceId = await _deviceFingerprint.getDeviceFingerprint();

      // Route through Cloudflare Workers backend
      await _cloudflareService.recordGameResult(
        userId: userId,
        gameId: gameId,
        won: true,
        score: 0, // Can be enhanced to pass actual score
        deviceId: deviceId,
      );

      debugPrint('✅ Game won: $gameId for $userId (+₹$reward) via backend');
    } catch (e) {
      debugPrint('❌ Error recording game win: $e');
      rethrow;
    }
  }

  /// Record game loss
  Future<void> recordGameLoss(
    String userId,
    String gameId, {
    double? customReward,
  }) async {
    try {
      final deviceId = await _deviceFingerprint.getDeviceFingerprint();

      // Route through Cloudflare Workers backend
      await _cloudflareService.recordGameResult(
        userId: userId,
        gameId: gameId,
        won: false,
        score: 0,
        deviceId: deviceId,
      );

      final reward = customReward ?? 0.0;
      if (reward > 0) {
        debugPrint(
          '✅ Game lost: $gameId for $userId (+₹$reward consolation) via backend',
        );
      } else {
        debugPrint('✅ Game lost: $gameId for $userId (no reward) via backend');
      }
    } catch (e) {
      debugPrint('❌ Error recording game loss: $e');
      rethrow;
    }
  }

  // ============ UTILITY METHODS ============

  /// Get game statistics for user
  Future<Map<String, dynamic>> getGameStats(String userId) async {
    try {
      final stats = await _cloudflareService.getUserStats(userId: userId);
      return {
        'gamesPlayedToday': stats['gamesPlayedToday'] ?? 0,
        'maxGamesPerDay': maxGamesPerDay,
        'canPlayMore': (stats['gamesPlayedToday'] ?? 0) < maxGamesPerDay,
      };
    } catch (e) {
      debugPrint('❌ Error getting game stats: $e');
      rethrow;
    }
  }

  /// Check if user has reached daily game limit
  Future<bool> hasReachedDailyLimit(String userId) async {
    try {
      final stats = await getGameStats(userId);
      return !(stats['canPlayMore'] ?? false);
    } catch (e) {
      debugPrint('❌ Error checking daily limit: $e');
      return false;
    }
  }

  /// Format cooldown time for display (e.g., "4m 30s")
  String formatCooldownTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}
