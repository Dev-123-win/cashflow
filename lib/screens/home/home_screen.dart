import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:confetti/confetti.dart';

import 'package:lottie/lottie.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/parallax_balance_card.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../services/ad_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../transaction_history_screen.dart';
import '../tasks/tasks_screen.dart';
import '../games/games_screen.dart';
import '../games/spin_screen.dart';
import '../ads/watch_ads_screen.dart';
import '../withdrawal/withdrawal_screen.dart';

import '../notification_screen.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AdService _adService;
  late ConfettiController _confettiController;
  String _userRank = '...';

  @override
  void initState() {
    super.initState();
    _adService = AdService();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadData();
    _fetchRank();
  }

  Future<void> _fetchRank() async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final leaderboard = await CloudflareWorkersService().getLeaderboard(
        limit: 100,
      );
      final index = leaderboard.indexWhere(
        (entry) => entry['userId'] == user.uid,
      );

      if (mounted) {
        setState(() {
          if (index != -1) {
            _userRank = '#${index + 1}';
          } else {
            _userRank = '100+';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching rank: $e');
    }
  }

  void _loadData() {
    // Initialize user from Firebase
    Future.microtask(() {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        context.read<UserProvider>().initializeUser(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final tertiaryColor = AppColors.accent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text('EarnQuest', style: theme.textTheme.headlineSmall),
                actions: [
                  ScaleButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.05,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  ScaleButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SpinScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.05,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.casino_outlined),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                ],
              ),

              // Main Content
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                sliver: SliverToBoxAdapter(
                  child: Selector<UserProvider, bool>(
                    selector: (_, provider) => provider.isLoading,
                    builder: (context, isLoading, child) {
                      if (isLoading) {
                        return Column(
                          children: [
                            const ShimmerLoading.rectangular(
                              height: 200,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(AppDimensions.radiusL),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space24),
                            Row(
                              children: [
                                Expanded(
                                  child: const ShimmerLoading.rectangular(
                                    height: 100,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(AppDimensions.radiusM),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space12),
                                Expanded(
                                  child: const ShimmerLoading.rectangular(
                                    height: 100,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(AppDimensions.radiusM),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Parallax Balance Card with Confetti
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _confettiController.play();
                            },
                            child: Selector<UserProvider, int>(
                              selector: (_, provider) => provider.user.coins,
                              builder: (context, coins, _) {
                                return ParallaxBalanceCard(
                                  coins: coins,
                                  onWithdraw: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const WithdrawalScreen(),
                                      ),
                                    );
                                  },
                                  canWithdraw:
                                      coins >= 50000, // 50,000 Coins = ₹50
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space24),

                          // Daily Goal Card
                          Consumer<TaskProvider>(
                            builder: (context, taskProvider, _) {
                              return _buildDailyGoalCard(context, taskProvider);
                            },
                          ),
                          const SizedBox(height: AppDimensions.space16),

                          // Streak & Leaderboard
                          Row(
                            children: [
                              Expanded(
                                child: ZenCard(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Lottie.asset(
                                            AppAssets.streakFire,
                                            height: 24,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Streak',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.space4,
                                      ),
                                      Selector<UserProvider, int>(
                                        selector: (_, provider) =>
                                            provider.user.streak,
                                        builder: (context, streak, _) {
                                          return Text(
                                            '$streak Days',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space12),
                              Expanded(
                                child: ZenCard(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LeaderboardScreen(),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.emoji_events_outlined,
                                            size: 24,
                                            color: tertiaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Rank',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.space4,
                                      ),
                                      Text(
                                        _userRank,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space24),

                          // Bento Grid for Earning Options
                          Text(
                            'Start Earning',
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
                                child: _buildAnimatedBentoTile(
                                  context,
                                  title: 'Daily Tasks',
                                  subtitle: 'Complete tasks to earn',
                                  lottieAsset: AppAssets.giftBoxOpen,
                                  color: const Color(0xFF6C63FF),
                                  onTap: () {
                                    _showInterstitialThenNavigate(
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TasksScreen(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              StaggeredGridTile.count(
                                crossAxisCellCount: 1,
                                mainAxisCellCount: 1,
                                child: _buildBentoTile(
                                  context,
                                  title: 'Play Games',
                                  subtitle: 'Fun & Earn',
                                  icon: Icons.sports_esports_outlined,
                                  color: const Color(0xFF00D9C0),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const GamesScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              StaggeredGridTile.count(
                                crossAxisCellCount: 1,
                                mainAxisCellCount: 1,
                                child: _buildBentoTile(
                                  context,
                                  title: 'Spin Wheel',
                                  subtitle: 'Try Luck',
                                  icon: Icons.casino_outlined,
                                  color: const Color(0xFFFFB800),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SpinScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              StaggeredGridTile.count(
                                crossAxisCellCount: 2,
                                mainAxisCellCount: 0.8,
                                child: _buildBentoTile(
                                  context,
                                  title: 'Watch Ads',
                                  subtitle: 'Quick earnings',
                                  icon: Icons.play_circle_outline,
                                  color: const Color(0xFFFF5252),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const WatchAdsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space24),

                          // Quick Links
                          Text(
                            'Quick Links',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppDimensions.space16),
                          ZenCard(
                            child: Column(
                              children: [
                                _buildQuickLink(
                                  context,
                                  icon: Icons.emoji_events_outlined,
                                  title: 'Leaderboard',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LeaderboardScreen(),
                                    ),
                                  ),
                                ),
                                const Divider(),
                                _buildQuickLink(
                                  context,
                                  icon: Icons.history,
                                  title: 'History',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TransactionHistoryScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 100,
                          ), // Space for Floating Dock
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF6C63FF),
                Color(0xFF00D9C0),
                Color(0xFFFFB800),
              ],
            ),
          ),

          // Banner Ad
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BannerAdWidget(),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildBentoTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppDimensions.space16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBentoTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String lottieAsset,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Lottie.asset(lottieAsset, height: 50, repeat: true),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLink(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.space8),
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDailyGoalCard(BuildContext context, TaskProvider taskProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    final progress = (taskProvider.dailyEarnings / taskProvider.dailyCap).clamp(
      0.0,
      1.0,
    );
    final percentage = (progress * 100).toInt();

    return ScaleButton(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              Color(0xFF8B85FF), // Lighter shade
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Goal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(taskProvider.dailyCap - taskProvider.dailyEarnings).toInt()} Coins left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percentage%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space20),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.black.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInterstitialThenNavigate(VoidCallback onNavigate) async {
    if (DateTime.now().millisecondsSinceEpoch % 10 < 4) {
      await _adService.showInterstitialAd();
    }
    onNavigate();
  }
}
