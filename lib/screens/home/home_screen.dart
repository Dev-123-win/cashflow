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
import '../leaderboard/leaderboard_screen.dart';
import '../transaction_history_screen.dart';
import '../tasks/tasks_screen.dart';
import '../games/games_screen.dart';
import '../games/spin_screen.dart';
import '../ads/watch_ads_screen.dart';
import '../withdrawal/withdrawal_screen.dart';
import '../referral/referral_screen.dart';
import '../notification_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AdService _adService;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _adService = AdService();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadData();
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
                          builder: (context) => const SettingsScreen(),
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
                      child: const Icon(Icons.settings_outlined),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                ],
              ),

              // Main Content
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.space16),
                sliver: SliverToBoxAdapter(
                  child: Consumer2<UserProvider, TaskProvider>(
                    builder: (context, userProvider, taskProvider, _) {
                      if (userProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
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
                            child: ParallaxBalanceCard(
                              balance: userProvider.user.availableBalance,
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
                                  userProvider.user.availableBalance >= 50,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),

                          // Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: ZenCard(
                                  onTap: () {},
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
                                      Text(
                                        '${userProvider.user.streak} Days',
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
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: ZenCard(
                                  onTap: () {},
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🎯 Daily Goal',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: AppTheme.space4),
                                      Text(
                                        '${(taskProvider.dailyEarnings / taskProvider.dailyCap * 100).toInt()}%',
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
                                  icon: Icons.people_outline,
                                  title: 'Refer Friends',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ReferralScreen(),
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

  void _showInterstitialThenNavigate(VoidCallback onNavigate) async {
    if (DateTime.now().millisecondsSinceEpoch % 10 < 4) {
      await _adService.showInterstitialAd();
    }
    onNavigate();
  }
}
