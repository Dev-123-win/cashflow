import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/scale_button.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile'),
        actions: [
          ScaleButton(
            onTap: () => _logout(context),
            child: Container(
              margin: const EdgeInsets.only(right: AppTheme.space16),
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
              ),
              child: Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
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
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              children: [
                // Profile Header Card
                ZenCard(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.secondaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: AppTheme.elevatedShadow,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        user.displayName.isNotEmpty ? user.displayName : 'User',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space12),
                      if (currentUser?.metadata.creationTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space12,
                            vertical: AppTheme.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                          ),
                          child: Text(
                            'Member since ${_formatDate(currentUser!.metadata.creationTime)}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppTheme.space16,
                  crossAxisSpacing: AppTheme.space16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      context,
                      '₹${user.totalEarnings.toStringAsFixed(2)}',
                      'Total Earned',
                      Icons.account_balance_wallet,
                      AppTheme.primaryColor,
                    ),
                    _buildStatCard(
                      context,
                      '${user.currentStreak}',
                      'Day Streak',
                      Icons.local_fire_department,
                      const Color(0xFFFF5252),
                    ),
                    _buildStatCard(
                      context,
                      '₹${user.monthlyEarnings.toStringAsFixed(2)}',
                      'This Month',
                      Icons.calendar_today,
                      AppTheme.secondaryColor,
                    ),
                    _buildStatCard(
                      context,
                      '₹${user.availableBalance.toStringAsFixed(2)}',
                      'Available',
                      Icons.savings,
                      AppTheme.successColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space32),

                // Achievements Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                _buildAchievementsGrid(context),
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
        'icon': Icons.games,
        'name': 'Game Starter',
        'earned': true,
        'color': Colors.blue,
      },
      {
        'icon': Icons.emoji_events,
        'name': 'Victory!',
        'earned': true,
        'color': Colors.amber,
      },
      {
        'icon': Icons.psychology,
        'name': 'Quiz Master',
        'earned': false,
        'color': Colors.purple,
      },
      {
        'icon': Icons.grid_view,
        'name': 'Memory Genius',
        'earned': true,
        'color': Colors.teal,
      },
      {
        'icon': Icons.local_fire_department,
        'name': '7 Day Streak',
        'earned': false,
        'color': Colors.red,
      },
      {
        'icon': Icons.monetization_on,
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
      children: achievements.map((achievement) {
        final earned = achievement['earned'] as bool;
        final color = achievement['color'] as Color;

        return ZenCard(
          padding: const EdgeInsets.all(AppTheme.space12),
          color: earned ? color.withValues(alpha: 0.1) : AppTheme.surfaceColor,
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
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return ZenCard(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
