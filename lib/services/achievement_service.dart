import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AchievementService() {
    return _instance;
  }

  AchievementService._internal();

  // Define all available achievements
  static const List<Achievement> allAchievements = [
    // First-time achievements
    Achievement(
      id: 'first_game',
      name: 'Game Starter',
      description: 'Play your first game',
      icon: '🎮',
      reward: 0.10,
      condition: 'gamesPlayed >= 1',
    ),
    Achievement(
      id: 'first_win',
      name: 'Victory! 🏆',
      description: 'Win your first game',
      icon: '🏆',
      reward: 0.25,
      condition: 'gamesWon >= 1',
    ),

    // Game-based achievements
    Achievement(
      id: 'quiz_master',
      name: 'Quiz Master',
      description: 'Answer 5 questions correctly in one quiz',
      icon: '🧠',
      reward: 0.50,
      condition: 'perfectQuiz == true',
    ),
    Achievement(
      id: 'memory_genius',
      name: 'Memory Genius',
      description: 'Get 100% accuracy in Memory Match',
      icon: '🎴',
      reward: 0.75,
      condition: 'memoryPerfect == true',
    ),
    Achievement(
      id: 'tic_tac_strategist',
      name: 'Tic-Tac Strategist',
      description: 'Win 5 Tic-Tac-Toe games',
      icon: '❌⭕',
      reward: 1.00,
      condition: 'ticTacWins >= 5',
    ),

    // Earning milestones
    Achievement(
      id: 'first_100',
      name: 'Century Club',
      description: 'Earn ₹100 total',
      icon: '💯',
      reward: 0.50,
      condition: 'totalEarned >= 100',
    ),
    Achievement(
      id: 'first_500',
      name: 'High Roller',
      description: 'Earn ₹500 total',
      icon: '🤑',
      reward: 1.00,
      condition: 'totalEarned >= 500',
    ),
    Achievement(
      id: 'first_1000',
      name: 'Millionaire Mindset',
      description: 'Earn ₹1000 total',
      icon: '💰',
      reward: 2.00,
      condition: 'totalEarned >= 1000',
    ),

    // Streak achievements
    Achievement(
      id: 'week_streak',
      name: '7-Day Streak',
      description: 'Maintain a 7-day earning streak',
      icon: '🔥',
      reward: 0.50,
      condition: 'streak >= 7',
    ),
    Achievement(
      id: 'month_streak',
      name: '30-Day Legend',
      description: 'Maintain a 30-day earning streak',
      icon: '⭐',
      reward: 2.00,
      condition: 'streak >= 30',
    ),

    // Game frequency achievements
    Achievement(
      id: 'game_addict',
      name: 'Game Addict',
      description: 'Play 50 games total',
      icon: '🎯',
      reward: 1.50,
      condition: 'gamesPlayed >= 50',
    ),
    Achievement(
      id: 'true_winner',
      name: 'True Winner',
      description: 'Win 25 games total',
      icon: '👑',
      reward: 2.50,
      condition: 'gamesWon >= 25',
    ),

    // Task achievements
    Achievement(
      id: 'task_master',
      name: 'Task Master',
      description: 'Complete 10 tasks',
      icon: '✅',
      reward: 1.00,
      condition: 'tasksCompleted >= 10',
    ),

    // Withdrawal achievements
    Achievement(
      id: 'first_withdrawal',
      name: 'Cashed Out',
      description: 'Make your first withdrawal',
      icon: '🏦',
      reward: 0.50,
      condition: 'withdrawalsCompleted >= 1',
    ),
  ];

  // Check and unlock achievements for user
  Future<List<String>> checkAndUnlockAchievements(
    String userId,
    Map<String, dynamic> userStats,
  ) async {
    try {
      List<String> newAchievements = [];
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final unlockedAchievements = List<String>.from(
        userData['unlockedAchievements'] ?? [],
      );

      for (final achievement in allAchievements) {
        // Skip if already unlocked
        if (unlockedAchievements.contains(achievement.id)) {
          continue;
        }

        // Check if achievement condition is met
        if (_checkAchievementCondition(achievement.condition, userStats)) {
          // Unlock achievement
          unlockedAchievements.add(achievement.id);
          newAchievements.add(achievement.id);

          // Record achievement unlock in Firestore
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('achievements')
              .doc(achievement.id)
              .set({
                'achievementId': achievement.id,
                'name': achievement.name,
                'description': achievement.description,
                'icon': achievement.icon,
                'reward': achievement.reward,
                'unlockedAt': FieldValue.serverTimestamp(),
              });

          // Add reward to user balance
          await _firestore.collection('users').doc(userId).update({
            'availableBalance': FieldValue.increment(achievement.reward),
            'totalEarned': FieldValue.increment(achievement.reward),
          });
        }
      }

      // Update user's unlocked achievements list
      if (newAchievements.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update({
          'unlockedAchievements': unlockedAchievements,
          'achievementCount': unlockedAchievements.length,
        });
      }

      return newAchievements;
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      return [];
    }
  }

  // Check if achievement condition is met
  bool _checkAchievementCondition(
    String condition,
    Map<String, dynamic> stats,
  ) {
    try {
      // Parse condition string and check against stats
      // Examples: "gamesPlayed >= 1", "totalEarned >= 100", "streak >= 7"

      if (condition.contains('gamesPlayed')) {
        int games = stats['gamesPlayedTotal'] ?? 0;
        if (condition.contains('>=')) {
          int required = int.parse(condition.split('>=')[1].trim());
          return games >= required;
        }
      }

      if (condition.contains('gamesWon')) {
        int wins = stats['gamesWonTotal'] ?? 0;
        if (condition.contains('>=')) {
          int required = int.parse(condition.split('>=')[1].trim());
          return wins >= required;
        }
      }

      if (condition.contains('totalEarned')) {
        double earned = (stats['totalEarned'] ?? 0).toDouble();
        if (condition.contains('>=')) {
          double required = double.parse(condition.split('>=')[1].trim());
          return earned >= required;
        }
      }

      if (condition.contains('streak')) {
        int streak = stats['streak'] ?? 0;
        if (condition.contains('>=')) {
          int required = int.parse(condition.split('>=')[1].trim());
          return streak >= required;
        }
      }

      if (condition.contains('perfectQuiz')) {
        return stats['lastQuizScore'] == 5; // 5 out of 5
      }

      if (condition.contains('memoryPerfect')) {
        return stats['lastMemoryAccuracy'] == 100;
      }

      if (condition.contains('ticTacWins')) {
        int ticTacWins = stats['ticTacWinsTotal'] ?? 0;
        if (condition.contains('>=')) {
          int required = int.parse(condition.split('>=')[1].trim());
          return ticTacWins >= required;
        }
      }

      if (condition.contains('tasksCompleted')) {
        int tasks = stats['tasksCompletedTotal'] ?? 0;
        if (condition.contains('>=')) {
          int required = int.parse(condition.split('>=')[1].trim());
          return tasks >= required;
        }
      }

      if (condition.contains('withdrawalsCompleted')) {
        int withdrawals = stats['withdrawalsCompletedTotal'] ?? 0;
        if (condition.contains('>=')) {
          int required = int.parse(condition.split('>=')[1].trim());
          return withdrawals >= required;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking condition: $e');
      return false;
    }
  }

  // Get user's unlocked achievements
  Stream<List<AchievementUnlock>> getUserAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AchievementUnlock.fromFirestore(doc))
              .toList(),
        );
  }

  // Get specific achievement details
  static Achievement? getAchievementById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get achievement progress
  Future<Map<String, dynamic>> getAchievementProgress(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final unlockedCount =
          (userData['unlockedAchievements'] as List?)?.length ?? 0;
      final totalCount = allAchievements.length;

      return {
        'unlocked': unlockedCount,
        'total': totalCount,
        'progress': (unlockedCount / totalCount * 100).toStringAsFixed(1),
      };
    } catch (e) {
      debugPrint('Error getting achievement progress: $e');
      return {'unlocked': 0, 'total': allAchievements.length, 'progress': '0'};
    }
  }
}

// Achievement model
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double reward;
  final String condition;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.reward,
    required this.condition,
  });
}

// Achievement unlock tracking model
class AchievementUnlock {
  final String achievementId;
  final String name;
  final String description;
  final String icon;
  final double reward;
  final DateTime unlockedAt;

  AchievementUnlock({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.icon,
    required this.reward,
    required this.unlockedAt,
  });

  factory AchievementUnlock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AchievementUnlock(
      achievementId: data['achievementId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      reward: (data['reward'] ?? 0).toDouble(),
      unlockedAt:
          (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
