import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';

/// Premium Floating Dock Navigation Bar
///
/// Features:
/// - Smooth animations with spring physics
/// - Haptic feedback on interaction
/// - Gradient active state
/// - Floating labels on long press
/// - Ripple effects
/// - Scale animations
class FloatingDock extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> icons;
  final List<String> labels;

  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.labels,
  });

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      margin: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12,
            vertical: AppDimensions.space8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.icons.length, (index) {
              return _buildNavItem(index, isDark, surfaceVariant, primaryColor, secondaryColor);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark, Color surfaceVariant, Color primaryColor, Color secondaryColor) {
    final isSelected = widget.currentIndex == index;
    final isHovered = _hoveredIndex == index;
    final isFab = index == 2; // Center item is FAB

    return GestureDetector(
      onTap: () {
        // Haptic feedback
        HapticFeedback.lightImpact();
        widget.onTap(index);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        setState(() => _hoveredIndex = index);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _hoveredIndex == index) {
            setState(() => _hoveredIndex = null);
          }
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Main button
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(
              horizontal: isFab ? AppDimensions.space8 : AppDimensions.space4,
            ),
            padding: EdgeInsets.all(
              isFab
                  ? 16.0
                  : isSelected
                  ? 14.0
                  : AppDimensions.space12,
            ),
            decoration: BoxDecoration(
              gradient: isFab
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
                    )
                  : isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.3),
                        secondaryColor.withValues(alpha: 0.2),
                      ],
                    )
                  : null,
              color: !isFab && isHovered && !isSelected
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                isFab ? AppDimensions.radiusXL : AppDimensions.radiusL,
              ),
              boxShadow: isFab
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
              border: !isFab && isSelected
                  ? Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            transform: isFab
                ? Matrix4.translationValues(0, -20, 0)
                : Matrix4.identity(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animations
                Icon(
                      widget.icons[index],
                      color: isFab
                          ? Colors.white
                          : isSelected
                          ? primaryColor
                          : Theme.of(context).colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                      size: isFab ? 32 : (isSelected ? 26 : 24),
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    )
                    .shimmer(
                      duration: 1500.ms,
                      color: isFab
                          ? Colors.white.withValues(alpha: 0.5)
                          : primaryColor.withValues(alpha: 0.3),
                    ),

                // Active indicator dot (Hidden for FAB)
                if (isSelected && !isFab)
                  Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              secondaryColor,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 300.ms,
                        curve: Curves.elasticOut,
                      ),
              ],
            ),
          ),

          // Floating label tooltip
          if (isHovered)
            Positioned(
              bottom: isFab ? 50 : 70,
              left: 0,
              right: 0,
              child: Center(
                child:
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space12,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                secondaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.labels[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideY(
                          begin: 0.5,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        )
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        ),
              ),
            ),

          // Ripple effect on tap
          if (isSelected)
            Positioned.fill(
              child:
                  Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            isFab ? AppDimensions.radiusXL : AppDimensions.radiusL,
                          ),
                          border: Border.all(
                            color: isFab
                                ? Colors.white.withValues(alpha: 0.3)
                                : primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        transform: isFab
                            ? Matrix4.translationValues(0, -20, 0)
                            : Matrix4.identity(),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeOut(duration: 1500.ms)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 1500.ms,
                      ),
            ),
        ],
      ),
    );
  }
}
