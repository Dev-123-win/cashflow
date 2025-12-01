import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';

class ProgressBar extends StatelessWidget {
  final double current;
  final double max;
  final String label;

  const ProgressBar({
    super.key,
    required this.current,
    required this.max,
    required this.label,
  });

  Color get progressColor {
    final percentage = (current / max) * 100;
    if (percentage < 50) return AppColors.success;
    if (percentage < 80) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (current / max).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '₹${current.toStringAsFixed(2)}/₹${max.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}
