import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';

class EarningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double reward;
  final String icon;
  final VoidCallback onTap;
  final bool locked;
  final String? lockReason;

  const EarningCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.icon,
    required this.onTap,
    this.locked = false,
    this.lockReason,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textTertiary = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: locked ? surfaceVariant : surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: locked ? textTertiary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                if (locked) Icon(Icons.lock, color: textTertiary, size: 20),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: locked ? textTertiary : textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '+₹${reward.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: locked ? textTertiary : primaryColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
