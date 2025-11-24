import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/earning_card.dart';
import '../../widgets/progress_bar.dart';
import '../../services/ad_service.dart';
import '../leaderboard_screen.dart';
import '../transaction_history_screen.dart';
import '../tasks/tasks_screen.dart';
import '../games/games_screen.dart';
import '../games/spin_screen.dart';
import '../ads/watch_ads_screen.dart';
import '../withdrawal/withdrawal_screen.dart';
import '../referral/referral_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AdService _adService;

  @override
  void initState() {
    super.initState();
    _adService = AdService();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('EarnQuest'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<UserProvider, TaskProvider>(
        builder: (context, userProvider, taskProvider, _) {
          if (userProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (userProvider.user.userId.isEmpty) {
            return const Center(
              child: Text('Please sign in to continue'),
            );
          }

          return Column(
            children: [
              Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Card
                        BalanceCard(
                          balance: userProvider.user.availableBalance,
                          onWithdraw: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WithdrawalScreen(),
                              ),
                            );
                          },
                          canWithdraw: userProvider.user.availableBalance >= 50,
                        ),
                        const SizedBox(height: AppTheme.space24),

                        // Streak Badge
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            border: Border.all(
                              color: AppTheme.tertiaryColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: AppTheme.space12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userProvider.user.streak} Day Streak',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    'Keep earning daily!',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space24),

                        // Daily Progress
                        ProgressBar(
                          current: taskProvider.dailyEarnings,
                          max: taskProvider.dailyCap,
                          label: "Today's Progress",
                        ),
                        const SizedBox(height: AppTheme.space24),

                        // Earning Categories
                        Text(
                          'Earn More',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppTheme.space16),

                        // 2x2 Grid of Earning Cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppTheme.space12,
                          mainAxisSpacing: AppTheme.space12,
                          childAspectRatio: 0.95,
                          children: [
                            EarningCard(
                              title: 'Tasks',
                              subtitle: '3 tasks left',
                              reward: 0.30,
                              icon: '📋',
                              onTap: () {
                                _showInterstitialThenNavigate(
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TasksScreen(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            EarningCard(
                              title: 'Games',
                              subtitle: '6 plays left',
                              reward: 0.48,
                              icon: '🎮',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GamesScreen(),
                                  ),
                                );
                              },
                            ),
                            EarningCard(
                              title: 'Spin Wheel',
                              subtitle: 'Ready to spin',
                              reward: 0.50,
                              icon: '🎰',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SpinScreen(),
                                  ),
                                );
                              },
                            ),
                            EarningCard(
                              title: 'Watch Ads',
                              subtitle: '5 ads available',
                              reward: 0.15,
                              icon: '📺',
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
                          ],
                        ),
                        const SizedBox(height: AppTheme.space24),

                        // Quick Links Section
                        Text(
                          'Quick Links',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppTheme.space12),

                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Text(
                                  '🏆',
                                  style: TextStyle(fontSize: 24),
                                ),
                                title: const Text('Leaderboard'),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LeaderboardScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                color: AppTheme.surfaceVariant,
                                height: 1,
                                indent: AppTheme.space56,
                              ),
                              ListTile(
                                leading: const Text(
                                  '👥',
                                  style: TextStyle(fontSize: 24),
                                ),
                                title: const Text('Invite Friends'),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ReferralScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                color: AppTheme.surfaceVariant,
                                height: 1,
                                indent: AppTheme.space56,
                              ),
                              ListTile(
                                leading: const Text(
                                  '📊',
                                  style: TextStyle(fontSize: 24),
                                ),
                                title: const Text('My Stats'),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                color: AppTheme.surfaceVariant,
                                height: 1,
                                indent: AppTheme.space56,
                              ),
                              ListTile(
                                leading: const Text(
                                  '💳',
                                  style: TextStyle(fontSize: 24),
                                ),
                                title: const Text('Transaction History'),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TransactionHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space32),
                      ],
                    ),
                  ),
                ),
                // Banner Ad at the bottom
                _buildBannerAd(),
              ],
            );
          },
        ),
    );
  }

  // Build banner ad widget using Google's native BannerAd
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

  // Show interstitial ad then navigate
  void _showInterstitialThenNavigate(VoidCallback onNavigate) async {
    // Show interstitial ad with 40% probability to avoid ad fatigue
    if (DateTime.now().millisecondsSinceEpoch % 10 < 4) {
      await _adService.showInterstitialAd();
    }
    // Always navigate
    onNavigate();
  }
}
