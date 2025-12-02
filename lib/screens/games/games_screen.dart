import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                padding: const EdgeInsets.all(AppDimensions.space16),
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
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimensions.space12),
                          Consumer2<UserProvider, TaskProvider>(
                            builder: (context, userProvider, taskProvider, _) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${taskProvider.completedTasks}/6 games played',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.space12,
                                      vertical: AppDimensions.space4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusS,
                                      ),
                                    ),
                                    child: Text(
                                      '₹${taskProvider.dailyEarnings.toStringAsFixed(2)} earned',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: AppColors.success,
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
                    const SizedBox(height: AppDimensions.space24),

                    // Available Games Grid
                    Text(
                      'Available Games',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    StaggeredGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppDimensions.space12,
                      crossAxisSpacing: AppDimensions.space12,
                      children: [
                        StaggeredGridTile.count(
                          crossAxisCellCount: 2,
                          mainAxisCellCount: 1,
                          child: _GameCard(
                            title: 'Tic-Tac-Toe',
                            description: 'Beat the AI to win!',
                            reward: 80,
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
                            reward: 500,
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
                            reward: 50,
                            icon: Icons.psychology,
                            color: const Color(0xFFFFB800),
                            onTap: () => _navigateToGame('quiz', 'Daily Quiz'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space24),

                    // Today's Best Scores
                    Text(
                      "Today's Best Scores",
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    _ScoreCard(
                      rank: 1,
                      name: 'Rajesh K.',
                      score: '45 sec',
                      medal: '🥇',
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    _ScoreCard(
                      rank: 2,
                      name: 'Priya S.',
                      score: '52 sec',
                      medal: '🥈',
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    _ScoreCard(
                      rank: 3,
                      name: 'You',
                      score: '67 sec',
                      medal: '🥉',
                    ),
                    const SizedBox(height: AppDimensions.space24),

                    ScaleButton(
                      onTap: () {
                        // Navigate to leaderboard
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        decoration: BoxDecoration(
                          color: surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'View Full Leaderboard',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: primaryColor,
                            ),
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
  final int reward;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: surfaceVariant, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space8,
                    vertical: AppDimensions.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/Coin.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$reward',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space16,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: surfaceVariant, width: 1),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            score,
            style: theme.textTheme.labelLarge?.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
