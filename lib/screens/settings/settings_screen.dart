import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
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
            const SizedBox(height: AppDimensions.space32),
            _buildSectionTitle(context, 'Privacy'),
            _buildToggleSetting(
              context,
              'Show on Leaderboard',
              'Display my earnings publicly',
              _showOnLeaderboard,
              (value) => setState(() => _showOnLeaderboard = value),
            ),
            const SizedBox(height: AppDimensions.space32),
            _buildSectionTitle(context, 'About'),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
              ),
              tileColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: primaryColor),
              ),
              title: Text('About App', style: theme.textTheme.labelLarge),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAboutDialog(context),
            ),
            const SizedBox(height: AppDimensions.space32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppDimensions.space24,
        0,
        AppDimensions.space12,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryColor,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: primaryColor,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Logout',
        emoji: '👋',
        content: const Text(
          'Are you sure you want to logout?',
          textAlign: TextAlign.center,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AuthService().signOut();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(AppAssets.appIconBackground),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: SvgPicture.asset(
                      AppAssets.appIconForeground,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              Text(
                'EarnQuest',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
