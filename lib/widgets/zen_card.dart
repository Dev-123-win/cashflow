import 'package:flutter/material.dart';
import '../core/constants/dimensions.dart';

class ZenCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final bool isGlass; // Restored isGlass field

  const ZenCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.border, // Added to constructor
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardTheme.color;

    Widget cardContent = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppDimensions.space16),
      decoration: isGlass
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            )
          : BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: border, // Applied border
              boxShadow: elevation != null && elevation! > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: elevation! * 4,
                        offset: Offset(0, elevation! * 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }
}
