import 'package:flutter/material.dart';

/// Shared Axis transition for page navigation
/// Provides depth-based transitions along the Z-axis
class SharedAxisPageTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType transitionType;

  SharedAxisPageTransition({
    required this.page,
    this.transitionType = SharedAxisTransitionType.scaled,
    super.settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _buildTransition(
             child,
             animation,
             secondaryAnimation,
             transitionType,
           );
         },
         transitionDuration: const Duration(milliseconds: 400),
         reverseTransitionDuration: const Duration(milliseconds: 400),
       );

  static Widget _buildTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    SharedAxisTransitionType type,
  ) {
    switch (type) {
      case SharedAxisTransitionType.scaled:
        return _buildScaledTransition(child, animation, secondaryAnimation);
      case SharedAxisTransitionType.horizontal:
        return _buildHorizontalTransition(child, animation, secondaryAnimation);
      case SharedAxisTransitionType.vertical:
        return _buildVerticalTransition(child, animation, secondaryAnimation);
    }
  }

  static Widget _buildScaledTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // Incoming page: scale up and fade in
    final incomingScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final incomingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Outgoing page: scale down and fade out
    final outgoingScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInCubic),
      ),
    );

    final outgoingFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final isForward =
            animation.status == AnimationStatus.forward ||
            animation.status == AnimationStatus.completed;

        return FadeTransition(
          opacity: isForward ? incomingFadeAnimation : outgoingFadeAnimation,
          child: ScaleTransition(
            scale: isForward ? incomingScaleAnimation : outgoingScaleAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget _buildHorizontalTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final incomingSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final outgoingSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.3, 0.0)).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInCubic,
          ),
        );

    final incomingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0)),
    );

    final outgoingFadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
    );

    return Stack(
      children: [
        // Outgoing page
        SlideTransition(
          position: outgoingSlideAnimation,
          child: FadeTransition(opacity: outgoingFadeAnimation, child: child),
        ),
        // Incoming page
        SlideTransition(
          position: incomingSlideAnimation,
          child: FadeTransition(opacity: incomingFadeAnimation, child: child),
        ),
      ],
    );
  }

  static Widget _buildVerticalTransition(
    Widget child,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final incomingSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final outgoingSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -0.3)).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInCubic,
          ),
        );

    return Stack(
      children: [
        // Outgoing page
        SlideTransition(position: outgoingSlideAnimation, child: child),
        // Incoming page
        SlideTransition(position: incomingSlideAnimation, child: child),
      ],
    );
  }
}

enum SharedAxisTransitionType {
  scaled, // Z-axis (depth)
  horizontal, // X-axis
  vertical, // Y-axis
}

/// Extension to easily navigate with shared axis transitions
extension SharedAxisNavigation on BuildContext {
  Future<T?> pushWithSharedAxis<T>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
  }) {
    return Navigator.of(
      this,
    ).push<T>(SharedAxisPageTransition<T>(page: page, transitionType: type));
  }

  Future<T?> pushReplacementWithSharedAxis<T, TO>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      SharedAxisPageTransition<T>(page: page, transitionType: type),
      result: result,
    );
  }
}
