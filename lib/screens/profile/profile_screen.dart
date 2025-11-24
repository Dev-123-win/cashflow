import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';

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
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
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
                Container(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
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
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space12),
                      if (currentUser?.metadata.creationTime != null)
                        Text(
                          'Member since ${_formatDate(currentUser!.metadata.creationTime)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space32),
                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppTheme.space16,
                  crossAxisSpacing: AppTheme.space16,
                  children: [
                    _buildStatCard(
                      context,
                      '₹${user.totalEarnings.toStringAsFixed(2)}',
                      'Total Earned',
                      '💰',
                    ),
                    _buildStatCard(
                      context,
                      '${user.currentStreak}',
                      'Day Streak',
                      '🔥',
                    ),
                    _buildStatCard(
                      context,
                      '₹${user.monthlyEarnings.toStringAsFixed(2)}',
                      'This Month',
                      '📊',
                    ),
                    _buildStatCard(
                      context,
                      '₹${user.availableBalance.toStringAsFixed(2)}',
                      'Available',
                      '💳',
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space32),
                // Achievements Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
      {'icon': '🎮', 'name': 'Game Starter', 'earned': true},
      {'icon': '🏆', 'name': 'Victory!', 'earned': true},
      {'icon': '🧠', 'name': 'Quiz Master', 'earned': false},
      {'icon': '🎴', 'name': 'Memory Genius', 'earned': true},
      {'icon': '🔥', 'name': '7 Day Streak', 'earned': false},
      {'icon': '💰', 'name': 'First 100', 'earned': false},
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.space12,
      crossAxisSpacing: AppTheme.space12,
      children: achievements.map((achievement) {
        final earned = achievement['earned'] as bool;
        return Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: earned
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: earned ? AppTheme.primaryColor : AppTheme.textTertiary,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                achievement['icon'] as String,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                achievement['name'] as String,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: earned
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (earned)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space4),
                  child: Icon(
                    Icons.check_circle,
                    size: 12,
                    color: AppTheme.successColor,
                  ),
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
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: AppTheme.space12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
