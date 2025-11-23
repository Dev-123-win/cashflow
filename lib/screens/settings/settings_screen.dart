import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReminders = true;
  bool _streakAlerts = true;
  bool _withdrawalNotifications = true;
  bool _showOnLeaderboard = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Notifications'),
            _buildToggleSetting(
              context,
              'Daily Reminders',
              'Get reminded to earn daily',
              _dailyReminders,
              (value) => setState(() => _dailyReminders = value),
            ),
            _buildToggleSetting(
              context,
              'Streak Alerts',
              'Remind me to maintain my streak',
              _streakAlerts,
              (value) => setState(() => _streakAlerts = value),
            ),
            _buildToggleSetting(
              context,
              'Withdrawal Updates',
              'Notify me about withdrawals',
              _withdrawalNotifications,
              (value) => setState(() => _withdrawalNotifications = value),
            ),
            const SizedBox(height: AppTheme.space32),
            _buildSectionTitle(context, 'Privacy'),
            _buildToggleSetting(
              context,
              'Show on Leaderboard',
              'Display my earnings publicly',
              _showOnLeaderboard,
              (value) => setState(() => _showOnLeaderboard = value),
            ),
            const SizedBox(height: AppTheme.space32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppTheme.space24,
        0,
        AppTheme.space12,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AuthService().signOut();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
