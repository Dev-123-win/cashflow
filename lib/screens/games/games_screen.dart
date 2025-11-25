import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';
import './tictactoe_screen.dart';
import './memory_match_screen.dart';
import './quiz_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _navigateToGame(String gameId, String gameName) async {
    Widget gameScreen;
    switch (gameId) {
      case 'tictactoe':
        gameScreen = const TicTacToeScreen();
        break;
      case 'memory_match':
        gameScreen = const MemoryMatchScreen();
        break;
      case 'quiz':
        gameScreen = const QuizScreen();
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Game not found')));
        return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => gameScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Play & Earn'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Stats
                    ZenCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Game Limit',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Consumer2<UserProvider, TaskProvider>(
                            builder: (context, userProvider, taskProvider, _) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${taskProvider.completedTasks}/6 games played',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space12,
                                      vertical: AppTheme.space4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusS,
                                      ),
                                    ),
                                    child: Text(
                                      '₹${taskProvider.dailyEarnings.toStringAsFixed(2)} earned',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.successColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),

                    // Available Games Grid
                    Text(
                      'Available Games',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.space16),

                    StaggeredGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppTheme.space12,
                      crossAxisSpacing: AppTheme.space12,
                      children: [
                        StaggeredGridTile.count(
                          crossAxisCellCount: 2,
                          mainAxisCellCount: 1,
                          child: _GameCard(
                            title: 'Tic-Tac-Toe',
                            description: 'Beat the AI to win!',
                            reward: 0.50,
                            icon: Icons.close,
                            color: const Color(0xFF6C63FF),
                            onTap: () =>
                                _navigateToGame('tictactoe', 'Tic-Tac-Toe'),
                          ),
                        ),
                        StaggeredGridTile.count(
                          crossAxisCellCount: 1,
                          mainAxisCellCount: 1.2,
                          child: _GameCard(
                            title: 'Memory Match',
                            description: 'Find pairs!',
                            reward: 0.50,
                            icon: Icons.grid_view,
                            color: const Color(0xFF00D9C0),
                            onTap: () =>
                                _navigateToGame('memory_match', 'Memory Match'),
                          ),
                        ),
                        StaggeredGridTile.count(
                          crossAxisCellCount: 1,
                          mainAxisCellCount: 1.2,
                          child: _GameCard(
                            title: 'Daily Quiz',
                            description: 'Test knowledge',
                            reward: 0.75,
                            icon: Icons.psychology,
                            color: const Color(0xFFFFB800),
                            onTap: () => _navigateToGame('quiz', 'Daily Quiz'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space24),

                    // Today's Best Scores
                    Text(
                      "Today's Best Scores",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.space12),

                    _ScoreCard(
                      rank: 1,
                      name: 'Rajesh K.',
                      score: '45 sec',
                      medal: '🥇',
                    ),
                    const SizedBox(height: AppTheme.space8),
                    _ScoreCard(
                      rank: 2,
                      name: 'Priya S.',
                      score: '52 sec',
                      medal: '🥈',
                    ),
                    const SizedBox(height: AppTheme.space8),
                    _ScoreCard(
                      rank: 3,
                      name: 'You',
                      score: '67 sec',
                      medal: '🥉',
                    ),
                    const SizedBox(height: AppTheme.space24),

                    ScaleButton(
                      onTap: () {
                        // Navigate to leaderboard
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Center(
                          child: Text(
                            'View Full Leaderboard',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Banner Ad at the bottom
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final double reward;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.description,
    required this.reward,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    '+₹${reward.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int rank;
  final String name;
  final String score;
  final String medal;

  const _ScoreCard({
    required this.rank,
    required this.name,
    required this.score,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    return ZenCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            score,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
