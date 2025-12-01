import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../core/theme/colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool hasBorder;
  final BoxBorder? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.hasBorder = true,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final defaultColor = isLight
        ? AppColors.surfaceLight
        : AppColors.surfaceDark;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: border ?? (hasBorder ? Border.all(color: borderColor) : null),
        boxShadow: [
          if (isLight &&
              onTap !=
                  null) // Only show shadow for interactive cards in light mode
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppDimensions.space16),
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}
