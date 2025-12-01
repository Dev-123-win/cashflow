import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final errorColor = AppColors.error;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final tertiaryColor = AppColors.warning;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Arcade Zone', style: theme.textTheme.headlineSmall),
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
                          ? errorColor.withValues(alpha: 0.1)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLimitReached ? errorColor : surfaceVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLimitReached ? Icons.block : Icons.videogame_asset,
                          size: 16,
                          color: isLimitReached ? errorColor : primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$gamesRemaining/20 left',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLimitReached ? errorColor : textPrimary,
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
            padding: const EdgeInsets.all(AppDimensions.space16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Featured: Daily Spin
                _buildFeaturedCard(
                  context,
                  title: 'Daily Lucky Spin',
                  subtitle: 'Win up to 750 Coins daily!',
                  lottieAsset: AppAssets
                      .giftBoxOpen, // Using gift box as placeholder for wheel if needed
                  color: tertiaryColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpinScreen()),
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Games Grid
                Text('Quick Games', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppDimensions.space16),

                StaggeredGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimensions.space12,
                  crossAxisSpacing: AppDimensions.space12,
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
                const SizedBox(height: AppDimensions.space24),

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
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
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
    final successColor = AppColors.success;

    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          reward,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.play_circle_fill, color: textSecondary),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusS,
                          ),
                        ),
                        child: Text(
                          reward,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: successColor,
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
