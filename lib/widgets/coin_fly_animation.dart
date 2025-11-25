import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that animates a coin flying from a source position to a target position
/// Used to provide visual feedback when users earn money
class CoinFlyAnimation extends StatefulWidget {
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback onComplete;
  final String amount;

  const CoinFlyAnimation({
    super.key,
    required this.startPosition,
    required this.endPosition,
    required this.onComplete,
    required this.amount,
  });

  @override
  State<CoinFlyAnimation> createState() => _CoinFlyAnimationState();
}

class _CoinFlyAnimationState extends State<CoinFlyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create a curved path from start to end with a parabolic arc
    _positionAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: widget.startPosition,
          end: Offset(
            (widget.startPosition.dx + widget.endPosition.dx) / 2,
            math.min(widget.startPosition.dy, widget.endPosition.dy) - 100,
          ),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(
            (widget.startPosition.dx + widget.endPosition.dx) / 2,
            math.min(widget.startPosition.dy, widget.endPosition.dy) - 100,
          ),
          end: widget.endPosition,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Scale animation: start small, grow, then shrink
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Rotation for visual interest
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: math.pi * 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Fade out at the end
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 4),
                      Text(
                        widget.amount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper class to manage coin fly animations
class CoinFlyAnimationManager {
  static OverlayEntry? _currentOverlay;

  /// Show a coin flying from source to target
  static void showCoinFly({
    required BuildContext context,
    required Offset startPosition,
    required Offset endPosition,
    required String amount,
  }) {
    // Remove any existing animation
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => CoinFlyAnimation(
        startPosition: startPosition,
        endPosition: endPosition,
        amount: amount,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }
}
