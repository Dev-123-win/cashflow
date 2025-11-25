import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A scaffold with a subtly animated gradient background that "breathes"
/// Creates an ambient, living feel to the UI
class BreathingGradientScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const BreathingGradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  State<BreathingGradientScaffold> createState() =>
      _BreathingGradientScaffoldState();
}

class _BreathingGradientScaffoldState extends State<BreathingGradientScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Slow, infinite breathing animation
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      appBar: widget.appBar,
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Color.lerp(
                                const Color(0xFF0A0E27),
                                const Color(0xFF1A1E37),
                                _animation.value,
                              )!,
                              Color.lerp(
                                const Color(0xFF1A1E37),
                                const Color(0xFF2A2E47),
                                _animation.value,
                              )!,
                            ]
                          : [
                              Color.lerp(
                                const Color(0xFFF5F7FA),
                                const Color(0xFFE8EBF0),
                                _animation.value,
                              )!,
                              Color.lerp(
                                const Color(0xFFE8EBF0),
                                const Color(0xFFD8DBE0),
                                _animation.value,
                              )!,
                            ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Subtle animated orbs for depth
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: BreathingOrbsPainter(
                    progress: _animation.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // Actual content
          widget.body,
        ],
      ),
    );
  }
}

/// Custom painter for subtle animated orbs in the background
class BreathingOrbsPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  BreathingOrbsPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Orb 1 - Top right
    final orb1Color = isDark
        ? Color.lerp(
            const Color(0xFF6C63FF).withValues(alpha: 0.05),
            const Color(0xFF6C63FF).withValues(alpha: 0.1),
            progress,
          )!
        : Color.lerp(
            const Color(0xFF6C63FF).withValues(alpha: 0.03),
            const Color(0xFF6C63FF).withValues(alpha: 0.06),
            progress,
          )!;

    paint.color = orb1Color;
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + (math.sin(progress * math.pi * 2) * 20),
        size.height * 0.2 + (math.cos(progress * math.pi * 2) * 20),
      ),
      150 + (progress * 30),
      paint,
    );

    // Orb 2 - Bottom left
    final orb2Color = isDark
        ? Color.lerp(
            const Color(0xFF00D9C0).withValues(alpha: 0.05),
            const Color(0xFF00D9C0).withValues(alpha: 0.1),
            progress,
          )!
        : Color.lerp(
            const Color(0xFF00D9C0).withValues(alpha: 0.03),
            const Color(0xFF00D9C0).withValues(alpha: 0.06),
            progress,
          )!;

    paint.color = orb2Color;
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + (math.cos(progress * math.pi * 2) * 20),
        size.height * 0.8 + (math.sin(progress * math.pi * 2) * 20),
      ),
      120 + (progress * 25),
      paint,
    );

    // Orb 3 - Center
    final orb3Color = isDark
        ? Color.lerp(
            const Color(0xFFFFB800).withValues(alpha: 0.03),
            const Color(0xFFFFB800).withValues(alpha: 0.07),
            progress,
          )!
        : Color.lerp(
            const Color(0xFFFFB800).withValues(alpha: 0.02),
            const Color(0xFFFFB800).withValues(alpha: 0.04),
            progress,
          )!;

    paint.color = orb3Color;
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + (math.sin(progress * math.pi * 2 + math.pi) * 15),
        size.height * 0.5 + (math.cos(progress * math.pi * 2 + math.pi) * 15),
      ),
      100 + (progress * 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(BreathingOrbsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
