import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';
import '../settings/settings_screen.dart';
import '../../services/achievement_service.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondaryColor = isDark ? AppColors.accentDark : AppColors.accent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              margin: const EdgeInsets.only(right: AppDimensions.space12),
              padding: const EdgeInsets.all(AppDimensions.space8),
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
              margin: const EdgeInsets.only(right: AppDimensions.space16),
              padding: const EdgeInsets.all(AppDimensions.space8),
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
                          colors: [primaryColor, secondaryColor],
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
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut)
                            .fadeIn(),
                        const SizedBox(height: AppDimensions.space16),
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
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: AppDimensions.space16),
                        if (currentUser?.metadata.creationTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space12,
                              vertical: AppDimensions.space4,
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
                  padding: const EdgeInsets.all(AppDimensions.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppDimensions.space16,
                        crossAxisSpacing: AppDimensions.space16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildStatCard(
                            context,
                            AppUtils.formatLargeNumber(
                              (user.totalEarnings * 1000).toInt(),
                            ),
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
                            AppUtils.formatLargeNumber(
                              (user.monthlyEarnings * 1000).toInt(),
                            ),
                            'This Month',
                            Icons.calendar_month_rounded,
                            const Color(0xFF6C63FF),
                            delay: 700,
                          ),
                          _buildStatCard(
                            context,
                            AppUtils.formatLargeNumber(user.coins),
                            'Available',
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF00D9C0),
                            delay: 800,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space32),

                      // Achievements Section
                      Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 900.ms).slideX(),
                      const SizedBox(height: AppDimensions.space16),
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final textTertiary = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return StreamBuilder<List<AchievementUnlock>>(
      stream: AchievementService().getUserAchievements(userId),
      builder: (context, snapshot) {
        // Get list of unlocked achievement IDs
        final unlockedIds = snapshot.hasData
            ? snapshot.data!.map((a) => a.achievementId).toSet()
            : <String>{};

        // Map achievements to display data
        final achievements = AchievementService.allAchievements.map((
          achievement,
        ) {
          final isUnlocked = unlockedIds.contains(achievement.id);

          // Map achievement ID to icon and color
          IconData icon;
          Color color;

          switch (achievement.id) {
            case 'first_game':
              icon = Icons.games_rounded;
              color = Colors.blue;
              break;
            case 'first_win':
              icon = Icons.emoji_events_rounded;
              color = Colors.amber;
              break;
            case 'quiz_master':
              icon = Icons.psychology_rounded;
              color = Colors.purple;
              break;
            case 'memory_genius':
              icon = Icons.grid_view_rounded;
              color = Colors.teal;
              break;
            case 'tic_tac_strategist':
              icon = Icons.extension_rounded;
              color = Colors.indigo;
              break;
            case 'week_streak':
              icon = Icons.local_fire_department_rounded;
              color = Colors.red;
              break;
            case 'month_streak':
              icon = Icons.star_rounded;
              color = Colors.orange;
              break;
            case 'first_100':
            case 'first_500':
            case 'first_1000':
              icon = Icons.monetization_on_rounded;
              color = Colors.green;
              break;
            case 'game_addict':
              icon = Icons.sports_esports_rounded;
              color = Colors.deepPurple;
              break;
            case 'true_winner':
              icon = Icons.emoji_events_rounded;
              color = Colors.yellow;
              break;
            case 'task_master':
              icon = Icons.task_alt_rounded;
              color = Colors.cyan;
              break;
            case 'first_withdrawal':
              icon = Icons.account_balance_wallet_rounded;
              color = Colors.pink;
              break;
            default:
              icon = Icons.emoji_events_rounded;
              color = Colors.grey;
          }

          return {
            'id': achievement.id,
            'icon': icon,
            'name': achievement.name,
            'earned': isUnlocked,
            'color': color,
          };
        }).toList();

        // Show first 6 achievements
        final displayAchievements = achievements.take(6).toList();

        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.space12,
          crossAxisSpacing: AppDimensions.space12,
          children: displayAchievements.asMap().entries.map((entry) {
            final index = entry.key;
            final achievement = entry.value;
            final earned = achievement['earned'] as bool;
            final color = achievement['color'] as Color;

            return ZenCard(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  color: earned ? color.withValues(alpha: 0.1) : surfaceColor,
                  border: earned
                      ? Border.all(color: color.withValues(alpha: 0.3))
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        achievement['icon'] as IconData,
                        size: 32,
                        color: earned ? color : textTertiary,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        achievement['name'] as String,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: earned ? color : textSecondary,
                          fontWeight: earned
                              ? FontWeight.bold
                              : FontWeight.normal,
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
      },
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
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: surfaceVariant, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Row(
            children: [
              if (label.contains('Coins') ||
                  label == 'Available' ||
                  label == 'This Month') ...[
                Image.asset('assets/icons/Coin.png', width: 20, height: 20),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, delay: delay.ms);
  }
}
