import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Loading overlay widget for async operations
class LoadingOverlayWidget extends StatelessWidget {
  final String? message;
  final double opacity;
  final bool dismissible;

  const LoadingOverlayWidget({
    super.key,
    this.message,
    this.opacity = 0.7,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: dismissible,
      child: Container(
        color: Colors.black.withValues(alpha: opacity),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppTheme.space16),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state widget
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'Retry',
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorColor.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 64, color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppTheme.space32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space32),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel ?? 'Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton (placeholder while content loads)
class LoadingSkeletonWidget extends StatefulWidget {
  final int itemCount;
  final double? height;
  final double? width;
  final bool isList;

  const LoadingSkeletonWidget({
    super.key,
    this.itemCount = 3,
    this.height,
    this.width,
    this.isList = true,
  });

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDarkMode
        ? AppTheme.darkSurfaceVariant
        : AppTheme.surfaceVariant;

    if (!widget.isList) {
      return FadeTransition(
        opacity: _opacity,
        child: Container(
          height: widget.height ?? 100,
          width: widget.width,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: FadeTransition(
            opacity: _opacity,
            child: Container(
              height: widget.height ?? 100,
              width: widget.width,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Success state widget with animation
class SuccessStateWidget extends StatefulWidget {
  final String title;
  final String message;
  final Duration duration;
  final VoidCallback? onDismiss;

  const SuccessStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<SuccessStateWidget> createState() => _SuccessStateWidgetState();
}

class _SuccessStateWidgetState extends State<SuccessStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    Future.delayed(widget.duration, () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: AppTheme.space32),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
