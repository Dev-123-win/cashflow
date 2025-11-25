import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom scroll physics that provides haptic feedback during scrolling
/// Gives a tactile "tick" feel similar to iOS pickers
class HapticScrollPhysics extends BouncingScrollPhysics {
  final double hapticThreshold;

  const HapticScrollPhysics({
    super.parent,
    this.hapticThreshold = 50.0, // Trigger haptic every 50 pixels
  });

  @override
  HapticScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HapticScrollPhysics(
      parent: buildParent(ancestor),
      hapticThreshold: hapticThreshold,
    );
  }
}

/// Mixin to add haptic feedback to tab selection
mixin TabHapticFeedback on State {
  int? _lastSelectedIndex;

  /// Call this in your tab selection callback
  void triggerTabHaptic(int newIndex) {
    if (_lastSelectedIndex != newIndex) {
      HapticFeedback.mediumImpact();
      _lastSelectedIndex = newIndex;
    }
  }
}

/// Enhanced haptic patterns for different interactions
class HapticPatterns {
  /// Light tap feedback (buttons, list items)
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Medium feedback (tab switches, toggles)
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy feedback (important actions, confirmations)
  static void heavyTap() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback (scrolling, picking)
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Success pattern (task completion, earning money)
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Error pattern (failed action, validation error)
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }

  /// Celebration pattern (big win, achievement)
  static Future<void> celebration() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }
}

/// A wrapper widget that adds haptic feedback to scrollable widgets
class HapticScrollView extends StatelessWidget {
  final Widget child;
  final double hapticThreshold;

  const HapticScrollView({
    super.key,
    required this.child,
    this.hapticThreshold = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        physics: HapticScrollPhysics(hapticThreshold: hapticThreshold),
      ),
      child: child,
    );
  }
}
