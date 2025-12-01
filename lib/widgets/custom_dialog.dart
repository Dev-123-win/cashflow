import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? emoji;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;
  final Color? accentColor;
  final bool showConfetti;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.emoji,
    this.actions,
    this.showCloseButton = false,
    this.accentColor,
    this.showConfetti = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppColors.primary;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child:
          Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(
                    color: effectiveAccentColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveAccentColor.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  child: Stack(
                    children: [
                      // Animated gradient background
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                effectiveAccentColor.withValues(alpha: 0.05),
                                Colors.transparent,
                                effectiveAccentColor.withValues(alpha: 0.03),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.space24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Emoji with animated glow effect
                            if (emoji != null) ...[
                              Container(
                                    padding: const EdgeInsets.all(
                                      AppDimensions.space16,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          effectiveAccentColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          effectiveAccentColor.withValues(
                                            alpha: 0.05,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      emoji!,
                                      style: const TextStyle(fontSize: 56),
                                    ),
                                  )
                                  .animate(
                                    onPlay: (controller) => controller.repeat(),
                                  )
                                  .shimmer(
                                    duration: 2000.ms,
                                    color: effectiveAccentColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  )
                                  .animate()
                                  .scale(
                                    duration: 400.ms,
                                    curve: Curves.elasticOut,
                                  ),
                              const SizedBox(height: AppDimensions.space16),
                            ],

                            // Title with gradient text effect
                            ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      isLight
                                          ? AppColors.textPrimaryLight
                                          : AppColors.textPrimaryDark,
                                      (isLight
                                              ? AppColors.textPrimaryLight
                                              : AppColors.textPrimaryDark)
                                          .withValues(alpha: 0.8),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: -0.3, end: 0, duration: 400.ms),

                            const SizedBox(height: AppDimensions.space16),

                            // Divider with gradient
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    effectiveAccentColor.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ).animate().scaleX(
                              begin: 0,
                              end: 1,
                              duration: 500.ms,
                              curve: Curves.easeOut,
                            ),

                            const SizedBox(height: AppDimensions.space16),

                            // Content
                            DefaultTextStyle(
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(
                                        color: isLight
                                            ? AppColors.textSecondaryLight
                                            : AppColors.textSecondaryDark,
                                        height: 1.5,
                                      ),
                                  child: content,
                                )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 200.ms)
                                .slideY(begin: 0.2, end: 0),

                            // Actions
                            if (actions != null) ...[
                              const SizedBox(height: AppDimensions.space24),
                              _buildActions(context, effectiveAccentColor),
                            ],

                            // Close button
                            if (showCloseButton && actions == null) ...[
                              const SizedBox(height: AppDimensions.space24),
                              _buildCloseButton(context, effectiveAccentColor),
                            ],
                          ],
                        ),
                      ),

                      // Top accent line
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child:
                            Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        effectiveAccentColor,
                                        effectiveAccentColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .scaleX(begin: 0, end: 1, duration: 600.ms)
                                .shimmer(duration: 2000.ms, delay: 600.ms),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),
    );
  }

  Widget _buildActions(BuildContext context, Color accentColor) {
    return Wrap(
      spacing: AppDimensions.space12,
      runSpacing: AppDimensions.space12,
      alignment: WrapAlignment.center,
      children: actions!.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;

        return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: action,
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: (400 + index * 100).ms)
            .slideY(
              begin: 0.5,
              end: 0,
              duration: 400.ms,
              delay: (400 + index * 100).ms,
            );
      }).toList(),
    );
  }

  Widget _buildCloseButton(BuildContext context, Color accentColor) {
    return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor.withValues(alpha: 0.1),
              foregroundColor: accentColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 400.ms)
        .slideY(begin: 0.5, end: 0, duration: 400.ms, delay: 400.ms);
  }
}

// Success Dialog Variant
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? extraContent;
  final List<Widget>? actions;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.extraContent,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return CustomDialog(
      title: title,
      emoji: '🎉',
      accentColor: AppColors.success,
      showConfetti: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isLight
                  ? AppColors.textSecondaryLight
                  : AppColors.textSecondaryDark,
            ),
          ),
          if (extraContent != null) ...[
            const SizedBox(height: AppDimensions.space16),
            extraContent!,
          ],
        ],
      ),
      actions: actions,
    );
  }
}

// Error Dialog Variant
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return CustomDialog(
      title: title,
      emoji: '⚠️',
      accentColor: AppColors.error,
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
        ),
      ),
      actions: [
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Retry'),
          ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Info Dialog Variant
class InfoDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const InfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      emoji: 'ℹ️',
      accentColor: AppColors.primary,
      content: content,
      actions: actions,
    );
  }
}

// Warning Dialog Variant
class WarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  final String confirmText;

  const WarningDialog({
    super.key,
    required this.title,
    required this.message,
    this.onConfirm,
    this.confirmText = 'Confirm',
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return CustomDialog(
      title: title,
      emoji: '⚡',
      accentColor: AppColors.warning,
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
        ),
      ),
      actions: [
        if (onConfirm != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm!();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(confirmText),
          ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
