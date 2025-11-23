import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: locked ? AppTheme.surfaceVariant : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: locked ? AppTheme.textTertiary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
                if (locked)
                  const Icon(
                    Icons.lock,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: locked ? AppTheme.textTertiary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '+₹${reward.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: locked ? AppTheme.textTertiary : AppTheme.primaryColor,
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
