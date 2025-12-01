import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';

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
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      color: isAtCap
          ? AppColors.error.withValues(alpha: 0.1)
          : isNearCap
          ? AppColors.warning.withValues(alpha: 0.1)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
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
                    const SizedBox(height: AppDimensions.space4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '₹${currentEarnings.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isAtCap
                                      ? AppColors.error
                                      : isNearCap
                                      ? AppColors.warning
                                      : AppColors.success,
                                ),
                          ),
                          TextSpan(
                            text: ' / ₹${dailyCap.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
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
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusS,
                      ),
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
            const SizedBox(height: AppDimensions.space12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: LinearProgressIndicator(
                value: progressPercent,
                minHeight: 8,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAtCap
                      ? AppColors.error
                      : isNearCap
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Remaining info
            if (!isAtCap)
              Text(
                'Remaining: ₹${remaining.toStringAsFixed(2)} | Resets at 12:00 AM',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            if (isAtCap)
              Text(
                'You\'ve reached today\'s earning limit. Come back tomorrow to earn more!',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
