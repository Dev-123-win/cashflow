# Digital Zen UI Enhancements - Usage Guide

This guide shows how to use the new Phase 2 UI enhancements in your screens.

## 🌊 Bouncing Scroll Physics

**Already enabled globally** in `main.dart`. All scrollable widgets now have iOS-style rubber band scrolling.

## 💰 Coin Fly Animation

Use when a user earns money:

```dart
import '../widgets/coin_fly_animation.dart';

// In your widget
CoinFlyAnimationManager.showCoinFly(
  context: context,
  startPosition: Offset(100, 200), // Where the action happened
  endPosition: Offset(300, 50),    // Balance card position
  amount: '₹0.10',
);
```

## 🎨 Breathing Gradient Background

Replace `Scaffold` with `BreathingGradientScaffold`:

```dart
import '../widgets/breathing_gradient_scaffold.dart';

BreathingGradientScaffold(
  appBar: AppBar(title: Text('My Screen')),
  body: YourContent(),
)
```

## ✨ Shimmer Effects

### For Premium Containers
```dart
import '../widgets/shimmer_effect.dart';

ShimmerContainer(
  padding: EdgeInsets.all(16),
  child: Text('Premium Feature'),
)
```

### For Gold Text
```dart
ShimmerText(
  text: '₹100',
  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
)
```

## 📳 Haptic Feedback

### Basic Patterns
```dart
import '../utils/haptic_feedback.dart';

// Light tap
HapticPatterns.lightTap();

// Tab switch
HapticPatterns.mediumTap();

// Important action
HapticPatterns.heavyTap();

// Success (double tap)
await HapticPatterns.success();

// Celebration (pattern)
await HapticPatterns.celebration();
```

### Tab Selection
```dart
class MyTabScreen extends StatefulWidget with TabHapticFeedback {
  void _onTabTapped(int index) {
    triggerTabHaptic(index); // Automatic haptic
    setState(() => _selectedIndex = index);
  }
}
```

## 🔄 Page Transitions

### Navigate with Shared Axis
```dart
import '../utils/page_transitions.dart';

// Scaled (Z-axis) - default
context.pushWithSharedAxis(NextScreen());

// Horizontal slide
context.pushWithSharedAxis(
  NextScreen(),
  type: SharedAxisTransitionType.horizontal,
);

// Vertical slide
context.pushWithSharedAxis(
  NextScreen(),
  type: SharedAxisTransitionType.vertical,
);
```

## 🎯 Best Practices

1. **Coin Fly**: Use for all earning events (tasks, games, spin wins)
2. **Shimmer**: Reserve for premium/gold elements only (don't overuse)
3. **Haptics**: Match intensity to action importance
4. **Breathing Gradient**: Use on main screens, not modals/dialogs
5. **Transitions**: Use `scaled` for hierarchical nav, `horizontal` for lateral nav

## 🔧 Performance Tips

- Breathing gradients are optimized but may impact battery on very old devices
- Shimmer effects are lightweight and safe to use liberally
- Haptics are instant and have no performance cost
- Page transitions are GPU-accelerated
