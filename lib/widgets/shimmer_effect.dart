import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that applies an animated shimmer effect to its child
/// Perfect for gold/premium elements to give them a luxurious feel
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFFFD700), // Gold
    this.highlightColor = const Color(0xFFFFFFFF), // White highlight
    this.enabled = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                math.max(0.0, _controller.value - 0.3),
                _controller.value,
                math.min(1.0, _controller.value + 0.3),
              ],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A container with a metallic shimmer effect
/// Ideal for premium cards, badges, and rewards
class ShimmerContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final List<Color>? gradientColors;
  final Duration shimmerDuration;

  const ShimmerContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradientColors,
    this.shimmerDuration = const Duration(milliseconds: 2000),
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ??
        [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFFFA500), // Orange
          const Color(0xFFFFD700), // Gold
        ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ShimmerEffect(
        duration: shimmerDuration,
        baseColor: colors.first,
        highlightColor: Colors.white,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A text widget with shimmer effect
/// Perfect for highlighting premium features or rewards
class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration shimmerDuration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    super.key,
    required this.text,
    this.style,
    this.shimmerDuration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFFFD700),
    this.highlightColor = const Color(0xFFFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      duration: shimmerDuration,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Text(
        text,
        style:
            style ??
            const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
      ),
    );
  }
}
