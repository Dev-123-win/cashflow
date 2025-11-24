import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Daily earning progress indicator widget
class DailyCapIndicatorWidget extends StatelessWidget {
  final double currentEarnings;
  final double dailyCap;
  final bool showWarning;

  const DailyCapIndicatorWidget({
    super.key,
    required this.currentEarnings,
    required this.dailyCap,
    this.showWarning = true,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (currentEarnings / dailyCap).clamp(0.0, 1.0);
    final remaining = (dailyCap - currentEarnings).clamp(0.0, dailyCap);
    final isNearCap = remaining < 0.25;
    final isAtCap = remaining <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      color: isAtCap
          ? AppTheme.errorColor.withValues(alpha: 0.1)
          : isNearCap
          ? AppTheme.warningColor.withValues(alpha: 0.1)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and remaining amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Earnings',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '₹${currentEarnings.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isAtCap
                                      ? AppTheme.errorColor
                                      : isNearCap
                                      ? AppTheme.warningColor
                                      : AppTheme.successColor,
                                ),
                          ),
                          TextSpan(
                            text: ' / ₹${dailyCap.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppTheme.darkTextTertiary
                                      : AppTheme.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAtCap)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: const Text(
                      'Maxed Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: LinearProgressIndicator(
                value: progressPercent,
                minHeight: 8,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkSurfaceVariant
                    : AppTheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAtCap
                      ? AppTheme.errorColor
                      : isNearCap
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            // Remaining info
            if (!isAtCap)
              Text(
                'Remaining: ₹${remaining.toStringAsFixed(2)} | Resets at 12:00 AM',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ),
            if (isAtCap)
              Text(
                'You\'ve reached today\'s earning limit. Come back tomorrow to earn more!',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
