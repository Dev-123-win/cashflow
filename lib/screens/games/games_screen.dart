import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/ad_service.dart';
import './tictactoe_screen.dart';
import './memory_match_screen.dart';
import './quiz_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  late final AdService _adService;

  @override
  void initState() {
    super.initState();
    _adService = AdService();
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

    // Navigate to game screen
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
      appBar: AppBar(title: const Text('Games'), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Play & Earn',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Consumer2<UserProvider, TaskProvider>(
                            builder: (context, userProvider, taskProvider, _) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${taskProvider.completedTasks}/6 games today',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '₹${taskProvider.dailyEarnings.toStringAsFixed(2)} earned',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: AppTheme.successColor,
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

                    // Available Games
                    Text(
                      'Available Games',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.space12),

                    // Tic Tac Toe Game Card
                    _GameCard(
                      title: 'Tic-Tac-Toe',
                      description: 'Beat the AI to win!',
                      reward: 0.50,
                      icon: '❌⭕',
                      status: 'Ready to play',
                      onTap: () => _navigateToGame('tictactoe', 'Tic-Tac-Toe'),
                    ),
                    const SizedBox(height: AppTheme.space12),

                    // Memory Match Game Card
                    _GameCard(
                      title: 'Memory Match',
                      description: 'Find all pairs quickly!',
                      reward: 0.50,
                      icon: '🧠',
                      status: 'Ready to play',
                      onTap: () =>
                          _navigateToGame('memory_match', 'Memory Match'),
                    ),
                    const SizedBox(height: AppTheme.space12),

                    // Quiz Game Card
                    _GameCard(
                      title: 'Daily Quiz',
                      description: 'Answer 5 questions!',
                      reward: 0.75,
                      icon: '🧠',
                      status: 'Ready to play',
                      onTap: () => _navigateToGame('quiz', 'Daily Quiz'),
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
                    const SizedBox(height: AppTheme.space12),
                    _ScoreCard(
                      rank: 2,
                      name: 'Priya S.',
                      score: '52 sec',
                      medal: '🥈',
                    ),
                    const SizedBox(height: AppTheme.space12),
                    _ScoreCard(
                      rank: 3,
                      name: 'You',
                      score: '67 sec',
                      medal: '🥉',
                    ),
                    const SizedBox(height: AppTheme.space24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to leaderboard
                        },
                        child: const Text('View Leaderboard'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Banner Ad at the bottom
            _buildBannerAd(),
          ],
        ),
      ),
    );
  }

  // Build banner ad widget
  Widget _buildBannerAd() {
    return Container(
      alignment: Alignment.center,
      width: AdSize.banner.width.toDouble(),
      height: AdSize.banner.height.toDouble(),
      child: _adService.getBannerAd() != null
          ? AdWidget(ad: _adService.getBannerAd()!)
          : Container(
              color: AppTheme.surfaceColor,
              child: const Center(
                child: Text('Loading ad...', style: TextStyle(fontSize: 12)),
              ),
            ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final double reward;
  final String icon;
  final String status;
  final VoidCallback onTap;

  // ignore: unused_element_parameter
  const _GameCard({
    required this.title,
    required this.description,
    required this.reward,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '+₹${reward.toStringAsFixed(2)} per ${title.split(' ').first.toLowerCase()}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppTheme.successColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space8,
                            vertical: AppTheme.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                          ),
                          child: Text(
                            status,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.titleLarge),
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
