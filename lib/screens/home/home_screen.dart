import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_theme.dart';
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
import '../referral/referral_screen.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'EarnQuest',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Opacity(
                    opacity: 0.1,
                    child: SvgPicture.asset(
                      AppAssets.topographicLines,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
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
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(Icons.casino_outlined),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                ],
              ),

              // Main Content
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.space16),
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
                                  Radius.circular(AppTheme.radiusL),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space24),
                            Row(
                              children: [
                                Expanded(
                                  child: const ShimmerLoading.rectangular(
                                    height: 100,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(AppTheme.radiusM),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: const ShimmerLoading.rectangular(
                                    height: 100,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(AppTheme.radiusM),
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
                          const SizedBox(height: AppTheme.space24),

                          // Daily Goal Card
                          Consumer<TaskProvider>(
                            builder: (context, taskProvider, _) {
                              return _buildDailyGoalCard(context, taskProvider);
                            },
                          ),
                          const SizedBox(height: AppTheme.space16),

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
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.space4),
                                      Selector<UserProvider, int>(
                                        selector: (_, provider) =>
                                            provider.user.streak,
                                        builder: (context, streak, _) {
                                          return Text(
                                            '$streak Days',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
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
                              const SizedBox(width: AppTheme.space12),
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
                                          const Icon(
                                            Icons.emoji_events_outlined,
                                            size: 24,
                                            color: AppTheme.tertiaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Rank',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.space4),
                                      Text(
                                        _userRank,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
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
                          const SizedBox(height: AppTheme.space24),

                          // Bento Grid for Earning Options
                          Text(
                            'Start Earning',
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
                          const SizedBox(height: AppTheme.space24),

                          // Quick Links
                          Text(
                            'Quick Links',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppTheme.space16),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60), // Space for Banner Ad
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReferralScreen()),
            );
          },
          label: const Text('Invite'),
          icon: const Icon(Icons.person_add_outlined),
          backgroundColor: AppTheme.tertiaryColor,
        ),
      ),
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
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
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
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
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
            Lottie.asset(lottieAsset, height: 50, repeat: true),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDailyGoalCard(BuildContext context, TaskProvider taskProvider) {
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
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'Earn ₹${(taskProvider.dailyCap - taskProvider.dailyEarnings).toStringAsFixed(2)} more to reach your goal!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
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
