import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_assets.dart';
import '../../providers/user_provider.dart';

import '../../widgets/scale_button.dart';
import '../../widgets/banner_ad_widget.dart';
import '../games/spin_screen.dart';
import '../games/tictactoe_screen.dart';
import '../games/memory_match_screen.dart';
import '../games/quiz_screen.dart';

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Arcade Zone',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            actions: [
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final gamesPlayed = userProvider.user.gamesPlayedToday;
                  final gamesRemaining = 20 - gamesPlayed;
                  final isLimitReached = gamesPlayed >= 20;

                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLimitReached
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLimitReached
                            ? AppTheme.errorColor
                            : AppTheme.surfaceVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLimitReached ? Icons.block : Icons.videogame_asset,
                          size: 16,
                          color: isLimitReached
                              ? AppTheme.errorColor
                              : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$gamesRemaining/20 left',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isLimitReached
                                    ? AppTheme.errorColor
                                    : AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.space16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Featured: Daily Spin
                _buildFeaturedCard(
                  context,
                  title: 'Daily Lucky Spin',
                  subtitle: 'Win up to 750 Coins daily!',
                  lottieAsset: AppAssets
                      .giftBoxOpen, // Using gift box as placeholder for wheel if needed
                  color: AppTheme.tertiaryColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpinScreen()),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Games Grid
                Text(
                  'Quick Games',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.space16),

                StaggeredGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppTheme.space12,
                  crossAxisSpacing: AppTheme.space12,
                  children: [
                    StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: 1.3,
                      child: _buildGameCard(
                        context,
                        title: 'Tic-Tac-Toe',
                        reward: '60 Coins',
                        icon: Icons.close,
                        color: const Color(0xFF6C63FF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TicTacToeScreen(),
                          ),
                        ),
                      ),
                    ),
                    StaggeredGridTile.count(
                      crossAxisCellCount: 1,
                      mainAxisCellCount: 1.3,
                      child: _buildGameCard(
                        context,
                        title: 'Memory Match',
                        reward: '60 Coins',
                        icon: Icons.grid_view,
                        color: const Color(0xFF00D9C0),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MemoryMatchScreen(),
                          ),
                        ),
                      ),
                    ),
                    StaggeredGridTile.count(
                      crossAxisCellCount: 2,
                      mainAxisCellCount: 0.8,
                      child: _buildGameCard(
                        context,
                        title: 'Daily Quiz',
                        reward: '50 Coins',
                        icon: Icons.psychology,
                        color: const Color(0xFFFFB800),
                        isHorizontal: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // Banner Ad
                const BannerAdWidget(),
                const SizedBox(height: 100), // Bottom padding for dock
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String lottieAsset,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Play Now',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Lottie.asset(lottieAsset, height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String reward,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isHorizontal = false,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: AppTheme.surfaceVariant),
          boxShadow: AppTheme.softShadow,
        ),
        child: isHorizontal
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          reward,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: AppTheme.textSecondary,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Text(
                          reward,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
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
