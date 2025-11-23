# EarnQuest - Micro-Earning Flutter App

A complete Flutter application for a sustainable micro-earning platform that rewards users through mini-games, tasks, and ads.

## 📋 Project Overview

EarnQuest is a production-ready Flutter app (for iOS and Android) designed to:
- Allow users to earn real money through engaging mini-games and simple tasks
- Generate sustainable revenue through AdMob ads (4-5x multiplier model)
- Maintain 7-day retention above 35% with gamification features
- Support up to 10,000 monthly active users on free tier infrastructure

**Target Audience:** Indian users aged 18-35
**Target Launch:** 90 days
**Estimated DAU in 6 months:** 10,000 users

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher
- Android Studio (for Android development) or Xcode (for iOS development)
- Firebase account with Blaze plan
- Google AdMob account
- Cloudflare Workers account

### Installation Steps

1. **Clone the repository**
   ```bash
   cd cashflow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Download Manrope fonts** (Required)
   - Download from [Google Fonts](https://fonts.google.com/specimen/Manrope)
   - Extract and place in `assets/fonts/`:
     - `Manrope-Regular.ttf` (weight: 400)
     - `Manrope-Medium.ttf` (weight: 500)
     - `Manrope-SemiBold.ttf` (weight: 600)
     - `Manrope-Bold.ttf` (weight: 700)

4. **Set up Firebase** (Optional - Required for production)
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── constants/
│   │   └── app_constants.dart   # App-wide constants & configurations
│   ├── theme/
│   │   └── app_theme.dart       # Material 3 Design System & Colors
│   └── utils/
│       └── app_utils.dart       # Utility functions & helpers
├── models/
│   ├── user_model.dart          # User data model
│   ├── task_model.dart          # Task data model
│   ├── leaderboard_model.dart   # Leaderboard entry model
│   └── withdrawal_model.dart    # Withdrawal request model
├── providers/
│   ├── user_provider.dart       # User state management
│   └── task_provider.dart       # Task state management
├── services/
│   ├── auth_service.dart        # Firebase authentication
│   ├── firestore_service.dart   # Firestore database operations
│   └── ad_service.dart          # Google AdMob integration
├── screens/
│   ├── auth/
│   │   └── login_screen.dart    # Login/SignUp screen
│   ├── home/
│   │   └── home_screen.dart     # Main home screen
│   ├── tasks/
│   │   └── tasks_screen.dart    # Available tasks
│   ├── games/
│   │   └── games_screen.dart    # Mini-games (Tic-Tac-Toe, Memory Match)
│   ├── spin/
│   │   └── spin_screen.dart     # Daily spin wheel
│   ├── leaderboard/
│   │   └── leaderboard_screen.dart  # Global leaderboard
│   └── withdrawal/
│       └── withdrawal_screen.dart   # Withdrawal management
└── widgets/
    ├── balance_card.dart        # Balance display card
    ├── earning_card.dart        # Earning opportunity card
    └── progress_bar.dart        # Daily progress bar

assets/
├── images/                      # App images (placeholder)
├── animations/                  # Lottie animations (placeholder)
└── fonts/
    ├── Manrope-Regular.ttf
    ├── Manrope-Medium.ttf
    ├── Manrope-SemiBold.ttf
    └── Manrope-Bold.ttf
```

---

## 🎨 Design System

### Color Palette (Material 3 - Dark Theme)
- **Primary:** `#6C63FF` (Vibrant Purple)
- **Secondary:** `#00D9C0` (Teal)
- **Tertiary:** `#FFB800` (Gold)
- **Background:** `#0F0F14` (Dark)
- **Surface:** `#1C1C23` (Card Background)
- **Success:** `#00E676` (Green)
- **Error:** `#FF5252` (Red)
- **Warning:** `#FFA726` (Orange)

### Typography
- **Font Family:** Manrope (400, 500, 600, 700 weights)
- **Display Large:** 32px, Bold, 1.2 line height
- **Headline Small:** 20px, SemiBold
- **Body Medium:** 14px, Regular, 1.5 line height
- **Label Large:** 12px, SemiBold

### Spacing System
- `space4` = 4px
- `space8` = 8px
- `space12` = 12px
- `space16` = 16px
- `space24` = 24px
- `space32` = 32px

---

## 💰 Monetization Configuration

### Daily Earning Limits
```dart
maxDailyEarnings: ₹1.50
maxTasksPerDay: 3
maxGamesPerDay: 6
maxAdsPerDay: 15
maxSpinsPerDay: 1
```

### Reward Structure
```dart
Task Rewards:
  - Survey: ₹0.10
  - Social Share: ₹0.10
  - App Rating: ₹0.10

Game Rewards:
  - Tic-Tac-Toe Win: ₹0.08
  - Memory Match: ₹0.08

Ad Rewards:
  - Rewarded Video: ₹0.03
  - Interstitial: ₹0.02

Spin Rewards: ₹0.05, ₹0.10, ₹0.20, ₹0.50, ₹1.00
```

### Withdrawal Settings
```dart
minWithdrawalAmount: ₹50.00
maxWithdrawalPerRequest: ₹500.00
minAccountAgeDays: 7
processingTime: 24-48 hours
```

---

## 🔧 Backend Integration

### Firebase Setup
1. **Firestore Collections:**
   - `users/{userId}` - User profiles & balances
   - `transactions/{transactionId}` - Earning records
   - `withdrawals/{withdrawalId}` - Withdrawal requests
   - `leaderboard/{userId}` - Ranking data
   - `daily_spins/{userId}` - Spin history

2. **Firebase Auth:**
   - Email/Password authentication
   - Google Sign-In integration
   - Password reset functionality

### Cloudflare Workers API
Base URL: `https://earnquest.workers.dev`

**Key Endpoints:**
- `POST /api/earn/task` - Record task completion
- `POST /api/earn/game` - Record game result
- `POST /api/earn/ad` - Record ad view
- `POST /api/spin` - Execute daily spin
- `GET /api/leaderboard` - Fetch rankings
- `POST /api/withdrawal/request` - Request withdrawal
- `GET /api/user/stats` - Get user statistics

### AdMob Integration
- **Rewarded Ads:** Primary monetization (₹80-150 per 1000 impressions)
- **Interstitial Ads:** Secondary (₹40-80 per 1000)
- **Native Ads:** Placement ads (₹20-50 per 1000)
- **App Open Ads:** Launch ads

**Note:** Update Ad Unit IDs in `lib/core/constants/app_constants.dart`

---

## 🎮 Features

### ✅ Implemented
- [x] Material 3 Design System (Dark theme)
- [x] Bottom Navigation (Home, Tasks, Games, Spin)
- [x] User authentication flow UI
- [x] Home screen with balance & earning cards
- [x] Tasks screen with 3 daily tasks
- [x] Games screen with Tic-Tac-Toe (AI opponent)
- [x] Daily spin wheel UI
- [x] Leaderboard screen
- [x] Withdrawal request screen
- [x] State management (Provider)
- [x] Constants & utilities
- [x] AppTheme system

### 🔄 To Be Implemented
- [ ] Firebase authentication
- [ ] Firestore database integration
- [ ] Google AdMob ads
- [ ] Payment gateway integration (Razorpay/PayU)
- [ ] Cloudflare Workers backend
- [ ] Device fingerprinting & fraud detection
- [ ] Push notifications (FCM)
- [ ] Analytics (Firebase Analytics + custom events)
- [ ] Offline caching (Hive)
- [ ] Memory Match game
- [ ] User profile screen
- [ ] Referral system
- [ ] In-app notifications

---

## 📊 Key Metrics & Goals

### KPIs
| Metric | Target |
|--------|--------|
| DAU/MAU Ratio | >25% |
| D1/D7/D30 Retention | 40% / 25% / 12% |
| ARPU | ₹12-15/month |
| Revenue Multiplier | 4-5x |
| Ad Fill Rate | >90% |
| Daily Session Length | 12-18 mins |
| Withdrawal Completion Rate | >80% |

### Technical Targets
- Support 10,000 DAU on free tier
- Firebase: 50,000 reads/day quota
- Cloudflare: 100,000 requests/day quota
- Ad impressions: 15+ per DAU
- Response time: <200ms avg

---

## 🛡️ Security & Anti-Fraud

### Implemented Safeguards
1. **Daily earning caps** - Max ₹1.50/day
2. **Withdrawal thresholds** - Min ₹50
3. **Account age requirement** - Min 7 days
4. **Rate limiting** - Per-user & per-IP limits
5. **Device fingerprinting** - Fraud detection

### Fraud Rules
```dart
- Task completion < 5 seconds → Flag
- Max 1 task/minute
- Max 3 bonus ads/15 minutes
- Max 2 accounts per device
- >5 accounts from same WiFi → Review
- >3 failed withdrawals → Lock account
```

---

## 📱 Dependencies

### Core Framework
- `flutter: sdk: flutter`
- `cupertino_icons: ^1.0.8`

### Firebase
- `firebase_core: ^3.7.0`
- `firebase_auth: ^5.2.0`
- `cloud_firestore: ^5.4.0`
- `firebase_analytics: ^12.2.0`

### State Management
- `provider: ^6.2.2`

### Storage
- `shared_preferences: ^2.3.2`
- `hive: ^2.2.3`
- `hive_flutter: ^1.1.0`

### Ads & Analytics
- `google_mobile_ads: ^5.1.0`
- `google_sign_in: ^6.2.1`

### UI & Animations
- `lottie: ^3.2.0`
- `fl_chart: ^0.69.0`
- `confetti: ^0.7.0`

### Utilities
- `http: ^1.2.2`
- `intl: ^0.20.1`
- `uuid: ^4.0.0`
- `device_info_plus: ^10.1.2`
- `connectivity_plus: ^6.0.1`
- `go_router: ^14.6.0`

---

## 🚀 Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Firebase Hosting (Web - Optional)
```bash
flutter build web --release
firebase deploy
```

---

## 📝 Environment Variables

Create `.env` file (not in git):
```
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
GOOGLE_ADMOB_APP_ID=your_admob_app_id
CLOUDFLARE_WORKER_URL=your_worker_url
RAZORPAY_KEY_ID=your_razorpay_key
```

---

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests & linting
4. Submit a PR

```bash
flutter analyze
flutter test
```

---

## 📄 License

This project is proprietary. All rights reserved.

---

## 👨‍💻 Support

For issues, feature requests, or questions:
- Create an issue in the repository
- Contact: support@earnquest.app

---

## 🗺️ Roadmap

### Phase 1 (MVP - Week 1-12)
- ✅ UI/UX implementation
- Firebase & Firestore setup
- Authentication system
- Task & game mechanics
- Basic ad integration

### Phase 2 (Week 13-16)
- Payment gateway integration
- Leaderboard & rankings
- Referral system
- Email notifications
- Analytics tracking

### Phase 3 (Week 17-24)
- Push notifications (FCM)
- Advanced fraud detection
- Content moderation
- Multi-language support
- Performance optimization

### Phase 4 (Scaling)
- Backend optimization
- Database sharding
- CDN integration
- API rate limiting
- Load balancing

---

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Material Design 3](https://m3.material.io/)
- [AdMob Integration](https://developers.google.com/admob)
- [Cloudflare Workers](https://developers.cloudflare.com/workers/)

---

**Last Updated:** November 22, 2025
**Version:** 1.0.0 (MVP)
