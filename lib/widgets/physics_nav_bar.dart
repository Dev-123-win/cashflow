import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';

/// Physics-Based Navigation Bar
///
/// Features:
/// - Smooth spring physics animations
/// - Haptic feedback on interaction
/// - Premium gradient indicators
/// - Scale animations on tap
/// - Simple yet elegant design
class PhysicsNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> icons;
  final List<String> labels;

  const PhysicsNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.icons,
    required this.labels,
  });

  @override
  State<PhysicsNavBar> createState() => _PhysicsNavBarState();
}

class _PhysicsNavBarState extends State<PhysicsNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final secondaryColor = isDark ? AppColors.accentDark : AppColors.accent;

    return Container(
      height: 70,
      margin: const EdgeInsets.all(AppDimensions.space16),
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
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.icons.length, (index) {
            return _buildNavItem(index, isDark, primaryColor, secondaryColor);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final isSelected = widget.currentIndex == index;
    final isPressed = _pressedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressedIndex = index);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _pressedIndex = null);
          widget.onTap(index);
        },
        onTapCancel: () {
          setState(() => _pressedIndex = null);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with scale animation
              AnimatedScale(
                scale: isPressed ? 0.85 : (isSelected ? 1.1 : 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withValues(alpha: 0.2),
                              secondaryColor.withValues(alpha: 0.1),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    widget.icons[index],
                    color: isSelected
                        ? primaryColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.3,
                ),
                child: Text(widget.labels[index]),
              ),
              const SizedBox(height: 2),
              // Active indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isSelected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
