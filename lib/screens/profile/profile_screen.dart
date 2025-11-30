import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).toStringAsFixed(0)} weeks ago';
    }
    return '${(difference.inDays / 30).toStringAsFixed(0)} months ago';
  }

  void _logout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          ScaleButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppTheme.space12),
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_outlined, color: Colors.white),
            ),
          ),
          ScaleButton(
            onTap: () => _logout(context),
            child: Container(
              margin: const EdgeInsets.only(right: AppTheme.space16),
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.user;
          final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
          final initials = user.displayName.isNotEmpty
              ? user.displayName
                    .split(' ')
                    .map((e) => e[0])
                    .join()
                    .toUpperCase()
              : user.email.isNotEmpty
              ? user.email[0].toUpperCase()
              : '?';

          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Header Section with Glassmorphism
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Gradient
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    // Decorative Circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Profile Content
                    Column(
                      children: [
                        const SizedBox(height: 100),
                        // Avatar
                        Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut)
                            .fadeIn(),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : 'User',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: AppTheme.space16),
                        if (currentUser?.metadata.creationTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space12,
                              vertical: AppTheme.space4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Member since ${_formatDate(currentUser!.metadata.creationTime)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ).animate().fadeIn(delay: 400.ms).scale(),
                      ],
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppTheme.space16,
                        crossAxisSpacing: AppTheme.space16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildStatCard(
                            context,
                            '${(user.totalEarnings * 1000).toInt()}',
                            'Total Coins',
                            Icons.monetization_on_rounded,
                            const Color(0xFFFFD700),
                            delay: 500,
                          ),
                          _buildStatCard(
                            context,
                            '${user.currentStreak}',
                            'Day Streak',
                            Icons.local_fire_department_rounded,
                            const Color(0xFFFF5252),
                            delay: 600,
                          ),
                          _buildStatCard(
                            context,
                            '${(user.monthlyEarnings * 1000).toInt()}',
                            'This Month',
                            Icons.calendar_month_rounded,
                            const Color(0xFF6C63FF),
                            delay: 700,
                          ),
                          _buildStatCard(
                            context,
                            '${user.coins}',
                            'Available',
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF00D9C0),
                            delay: 800,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space32),

                      // Achievements Section
                      Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 900.ms).slideX(),
                      const SizedBox(height: AppTheme.space16),
                      _buildAchievementsGrid(context),
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    // Mock achievements data
    final achievements = [
      {
        'icon': Icons.games_rounded,
        'name': 'Game Starter',
        'earned': true,
        'color': Colors.blue,
      },
      {
        'icon': Icons.emoji_events_rounded,
        'name': 'Victory!',
        'earned': true,
        'color': Colors.amber,
      },
      {
        'icon': Icons.psychology_rounded,
        'name': 'Quiz Master',
        'earned': false,
        'color': Colors.purple,
      },
      {
        'icon': Icons.grid_view_rounded,
        'name': 'Memory Genius',
        'earned': true,
        'color': Colors.teal,
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'name': '7 Day Streak',
        'earned': false,
        'color': Colors.red,
      },
      {
        'icon': Icons.monetization_on_rounded,
        'name': 'First 100',
        'earned': false,
        'color': Colors.green,
      },
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.space12,
      crossAxisSpacing: AppTheme.space12,
      children: achievements.asMap().entries.map((entry) {
        final index = entry.key;
        final achievement = entry.value;
        final earned = achievement['earned'] as bool;
        final color = achievement['color'] as Color;

        return ZenCard(
              padding: const EdgeInsets.all(AppTheme.space12),
              color: earned
                  ? color.withValues(alpha: 0.1)
                  : AppTheme.surfaceColor,
              border: earned
                  ? Border.all(color: color.withValues(alpha: 0.3))
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    achievement['icon'] as IconData,
                    size: 32,
                    color: earned ? color : AppTheme.textTertiary,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    achievement['name'] as String,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: earned ? color : AppTheme.textSecondary,
                      fontWeight: earned ? FontWeight.bold : FontWeight.normal,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: (1000 + (index * 100)).ms)
            .scale(delay: (1000 + (index * 100)).ms);
      }).toList(),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color, {
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppTheme.surfaceVariant, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, delay: delay.ms);
  }
}
