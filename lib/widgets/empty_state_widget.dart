import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Generic empty state widget for lists/content areas
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;
  final Color iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionButtonText,
    this.onActionPressed,
    this.iconColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: AppTheme.space24),

          // Title
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),

          if (actionButtonText != null && onActionPressed != null) ...[
            const SizedBox(height: AppTheme.space24),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionButtonText!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state for no tasks
class NoTasksEmptyState extends StatelessWidget {
  final VoidCallback? onStartEarning;

  const NoTasksEmptyState({super.key, this.onStartEarning});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No tasks available',
      subtitle: 'Check back later for more earning opportunities.',
      icon: Icons.assignment_outlined,
      actionButtonText: 'Explore other options',
      onActionPressed: onStartEarning,
    );
  }
}

/// Empty state for no games
class NoGamesEmptyState extends StatelessWidget {
  const NoGamesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Games coming soon',
      subtitle: 'We\'re preparing exciting games for you to earn more!',
      icon: Icons.sports_esports_outlined,
    );
  }
}

/// Empty state for no leaderboard entries
class NoLeaderboardEmptyState extends StatelessWidget {
  const NoLeaderboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Leaderboard empty',
      subtitle: 'Start earning to appear on the leaderboard!',
      icon: Icons.leaderboard_outlined,
    );
  }
}

/// Empty state for no withdrawals
class NoWithdrawalsEmptyState extends StatelessWidget {
  const NoWithdrawalsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No withdrawal history',
      subtitle: 'Earn money and request a withdrawal!',
      icon: Icons.account_balance_wallet_outlined,
    );
  }
}
