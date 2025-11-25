import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

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
      padding: padding ?? const EdgeInsets.all(AppTheme.space16),
      decoration: isGlass
          ? AppTheme.glassMorphism(context)
          : BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: border, // Applied border
              boxShadow: elevation != null && elevation! > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: elevation! * 4,
                        offset: Offset(0, elevation! * 2),
                      ),
                    ]
                  : AppTheme.softShadow,
            ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }
}
