import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';

class FloatingDock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space24),
      decoration: AppTheme.glassMorphism(context, opacity: 0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(icons.length, (index) {
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.seedColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                          icons[index],
                          color: isSelected
                              ? AppTheme.seedColor
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 24,
                        )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                        )
                        .moveY(begin: 0, end: -4),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppTheme.seedColor,
                          shape: BoxShape.circle,
                        ),
                      ).animate().fadeIn().scale(),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
