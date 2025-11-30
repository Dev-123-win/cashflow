# Enhanced Dialog System - Usage Guide

## Overview

The enhanced dialog system provides beautiful, animated dialogs with gradient effects, glow animations, and specialized variants for different use cases.

## Features

✨ **Smooth Animations** - Scale, fade, slide, and shimmer effects  
🎨 **Gradient Backgrounds** - Subtle gradient overlays with accent colors  
💫 **Emoji Glow Effect** - Animated shimmer on emoji icons  
🌈 **Customizable Accents** - Per-dialog color themes  
📦 **Pre-built Variants** - Success, Error, Info, Warning dialogs

---

## Dialog Variants

### 1. **CustomDialog** (Base Component)

The main dialog component with full customization.

#### Usage:

```dart
showDialog(
  context: context,
  builder: (context) => CustomDialog(
    title: 'Welcome!',
    emoji: '🎉',
    accentColor: AppTheme.primaryColor, // Optional
    content: Text('This is a beautiful dialog'),
    actions: [
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Got it!'),
      ),
    ],
  ),
);
```

#### Properties:

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `title` | String | ✅ | Dialog title |
| `content` | Widget | ✅ | Main content widget |
| `emoji` | String? | ❌ | Emoji icon (displays with glow effect) |
| `actions` | List<Widget>? | ❌ | Action buttons |
| `showCloseButton` | bool | ❌ | Show auto close button (default: false) |
| `accentColor` | Color? | ❌ | Accent color for borders/effects |
| `showConfetti` | bool | ❌ | Enable confetti (future feature) |

---

### 2. **SuccessDialog**

Pre-configured for success messages with green accent.

#### Usage:

```dart
showDialog(
  context: context,
  builder: (context) => SuccessDialog(
    title: 'Reward Claimed!',
    message: 'You earned 80 Coins successfully',
    extraContent: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+80 Coins',
        style: TextStyle(
          color: AppTheme.successColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    actions: [
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Awesome!'),
      ),
    ],
  ),
);
```

**Features:**
- 🎉 Emoji
- Green accent color
- Success-themed styling

---

### 3. **ErrorDialog**

Pre-configured for error messages with red accent.

#### Usage:

```dart
showDialog(
  context: context,
  builder: (context) => ErrorDialog(
    title: 'Oops!',
    message: 'Failed to process your request. Please try again.',
    onRetry: () {
      // Retry logic here
      _retryAction();
    },
  ),
);
```

**Features:**
- ⚠️ Emoji
- Red accent color
- Optional retry button
- Auto-close button

---

### 4. **InfoDialog**

Pre-configured for informational messages.

#### Usage:

```dart
showDialog(
  context: context,
  builder: (context) => InfoDialog(
    title: 'How to Play',
    content: Column(
      crossAxisSize: CrossAxisSize.start,
      children: [
        Text('• Mark your position with X'),
        SizedBox(height: 8),
        Text('• AI will respond with O'),
        SizedBox(height: 8),
        Text('• Get 3 in a row to win'),
      ],
    ),
    actions: [
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Got it!'),
      ),
    ],
  ),
);
```

**Features:**
- ℹ️ Emoji
- Primary color accent
- Info-themed styling

---

### 5. **WarningDialog**

Pre-configured for warning messages with confirmation.

#### Usage:

```dart
showDialog(
  context: context,
  builder: (context) => WarningDialog(
    title: 'Confirm Action',
    message: 'Are you sure you want to delete your account? This action cannot be undone.',
    confirmText: 'Delete Account',
    onConfirm: () {
      // Confirmed action
      _deleteAccount();
    },
  ),
);
```

**Features:**
- ⚡ Emoji
- Orange accent color
- Confirm/Cancel buttons
- Warning-themed styling

---

## Migration Examples

### Before (Old Dialog):

```dart
showDialog(
  context: context,
  builder: (context) => CustomDialog(
    title: 'You Won!',
    emoji: '🎉',
    content: Text('Congratulations! Claim your reward.'),
    actions: [
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Claim'),
      ),
    ],
  ),
);
```

### After (Enhanced Dialog):

```dart
showDialog(
  context: context,
  builder: (context) => SuccessDialog(
    title: 'You Won!',
    message: 'Congratulations! Claim your reward.',
    extraContent: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars, color: AppTheme.tertiaryColor, size: 32),
          SizedBox(width: 12),
          Text(
            '80 Coins',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    ),
    actions: [
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _claimReward();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
        ),
        child: Text('Claim Reward 📺'),
      ),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Later'),
      ),
    ],
  ),
);
```

---

## Animation Details

### Entry Animation:
1. **Scale**: 0.8 → 1.0 (400ms, easeOutBack curve)
2. **Fade In**: 0 → 1 (300ms)

### Emoji Animation:
1. **Scale**: Elastic bounce (400ms)
2. **Shimmer**: Continuous 2s loop with accent color

### Title Animation:
1. **Fade In**: 300ms
2. **Slide Up**: -30% → 0 (400ms)

### Divider Animation:
1. **Scale X**: 0 → 1 (500ms, easeOut)

### Content Animation:
1. **Fade In**: 400ms with 200ms delay
2. **Slide Up**: 20% → 0

### Actions Animation:
- Staggered animations
- Each button animates 100ms after the previous
- Fade + Slide combo

### Top Accent Line:
1. **Scale X**: 0 → 1 (600ms)
2. **Shimmer**: Starts after 600ms, 2s loop

---

## Customization Tips

### Custom Accent Colors:

```dart
// Purple themed dialog
CustomDialog(
  title: 'Special Offer',
  accentColor: Color(0xFF9C27B0),
  emoji: '💎',
  content: Text('Limited time offer!'),
  actions: [
    ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF9C27B0),
      ),
      child: Text('Claim'),
    ),
  ],
)
```

### Rich Content:

```dart
CustomDialog(
  title: 'Daily Streak',
  emoji: '🔥',
  accentColor: AppTheme.warningColor,
  content: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final isActive = index < currentStreak;
          return Icon(
            Icons.check_circle,
            color: isActive 
              ? AppTheme.successColor 
              : Colors.grey.shade300,
            size: 32,
          );
        }),
      ),
      SizedBox(height: 16),
      Text(
        '$currentStreak Day Streak!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
  actions: [
    ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Keep it up!'),
    ),
  ],
)
```

---

## Best Practices

1. **Use Semantic Variants**: Choose SuccessDialog, ErrorDialog, etc. for standard use cases
2. **Limit Actions**: Maximum 3 buttons for better UX
3. **Keep Emoji Simple**: Single emoji works best
4. **Match Accent Colors**: Use theme colors for consistency
5. **Barrrier Dismissible**: Set to `false` for critical dialogs

---

## Complete Example

```dart
import 'package:flutter/material.dart';
import '../widgets/custom_dialog.dart';
import '../core/theme/app_theme.dart';

class GameScreen extends StatelessWidget {
  void _showGameResult(BuildContext context, bool won) {
    if (won) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(
          title: 'Victory!',
          message: 'You beat the AI and earned rewards!',
          extraContent: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor.withValues(alpha: 0.2),
                  AppTheme.successColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events, 
                  color: AppTheme.tertiaryColor, 
                  size: 48
                ),
                SizedBox(height: 12),
                Text(
                  '+80 Coins',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _claimReward();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: EdgeInsets.symmetric(
                  horizontal: 32, 
                  vertical: 16
                ),
              ),
              child: Text('Claim Reward 📺'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _playAgain();
              },
              child: Text('Play Again'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => InfoDialog(
          title: 'Nice Try!',
          content: Column(
            children: [
              Text(
                'The AI won this round, but keep practicing!',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Come back tomorrow for more chances to earn.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _playAgain();
              },
              child: Text('Try Again'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }
  }

  void _claimReward() {
    // Logic to claim reward
  }

  void _playAgain() {
    // Logic to restart game
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showGameResult(context, true),
          child: Text('Show Victory Dialog'),
        ),
      ),
    );
  }
}
```

---

## Troubleshooting

**Dialog doesn't animate:**
- Ensure `flutter_animate` package is in `pubspec.yaml`
- Run `flutter pub get`

**Colors look off:**
- Check `AppTheme` has all required color constants
- Verify `accentColor` is provided or defaults to `primaryColor`

**Buttons overflow:**
- Use `Wrap` for actions (already handled in CustomDialog)
- Limit to 3 buttons maximum
- Consider stacking vertically for 4+ buttons

---

**Enjoy your enhanced dialogs! 🎉**
