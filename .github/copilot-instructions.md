# EarnQuest - AI Coding Agent Instructions

**Project:** EarnQuest (Flutter Micro-Earning App)  
**Version:** 1.0.0+1  
**Status:** Phase 2 Backend Complete - Integration Ready  
**Updated:** November 2025

---

## 🎯 Project Overview

EarnQuest is a Flutter-based micro-earning application where users earn money through tasks, games, ads, and referrals. The architecture spans a **Flutter frontend** (Provider state management), **Firebase backend** (Auth + Firestore), and a **Cloudflare Workers** API layer handling earning logic and fraud detection.

**Key Metrics:**
- Target earning: ₹0.05-₹1.50/day
- Daily cap enforced per-user
- 7 screens with Material 3 design
- Multi-platform: Android, iOS, Web, Windows, macOS, Linux

---

## 🏗️ Architecture Pattern

### Three-Layer Architecture
```
UI Layer (Screens) → State Layer (Providers) → Service Layer
                                             ↓
                                    Firebase / Cloudflare
```

### Critical Data Flow
1. **User Actions** (UI) → Call Provider methods
2. **Providers** validate & orchestrate → Call Services (Firestore + CloudflareWorkersService)
3. **Services** perform I/O → Notify Providers via `notifyListeners()`
4. **UI rebuilds** via Consumer widgets

**Example: User completes task**
```
TasksScreen → TaskProvider.completeTask() → FirestoreService.recordTaskCompletion() 
  → Cloudflare API (fraud check) → Firestore update → Provider notifies → UI updates
```

### Why Three Layers?
- **Separation of concerns:** UI doesn't call Firebase directly
- **Testability:** Services can be mocked
- **Reusability:** Services used by multiple screens
- **Consistency:** All business logic in providers/services

---

## 📂 Key Directory Structure

```
lib/
├── main.dart                          # Entry point, MultiProvider setup, routing
├── services/                          # Backend I/O layer (15 services)
│   ├── auth_service.dart             # Firebase Auth (singleton)
│   ├── firestore_service.dart        # Firestore CRUD (batching, transactions)
│   ├── cloudflare_workers_service.dart # API wrapper (7 endpoints)
│   ├── ad_service.dart               # AdMob integration (6 ad types)
│   ├── cooldown_service.dart         # Timing between actions
│   └── [device_fingerprint, fee_calc, referral, etc.]
├── providers/                         # State management (Provider pattern)
│   ├── user_provider.dart            # User auth state + balance (streams Firestore)
│   └── task_provider.dart            # Tasks & daily progress (₹1.50 cap logic)
├── screens/                           # UI (7 screens)
│   ├── auth/[login, signup, onboarding, splash]
│   ├── home/home_screen.dart         # Dashboard
│   ├── tasks/tasks_screen.dart       # Task list
│   ├── games/                        # Tic-Tac-Toe with minimax AI
│   ├── spin/spin_screen.dart         # Daily wheel
│   └── withdrawal/withdrawal_screen.dart # UPI withdrawal
├── models/                            # Data classes (4 models)
│   ├── user_model.dart
│   ├── task_model.dart
│   ├── withdrawal_model.dart
│   └── leaderboard_model.dart
├── widgets/                           # Reusable components (15+)
│   ├── balance_card.dart
│   ├── earning_card.dart
│   └── [other composables]
└── core/
    ├── constants/app_constants.dart  # Config: rewards, limits, AdMob IDs
    ├── theme/app_theme.dart         # Material 3 (custom colors, typography)
    └── utils/app_utils.dart         # Helpers
```

**Backend:**
```
cloudflare-worker/
├── src/index.ts                      # 1000+ lines TypeScript
│   ├── 7 API endpoints (/api/earn/task, /api/spin, etc.)
│   ├── Rate limiting (100 req/min/IP, 50 req/min/user)
│   ├── Fraud detection (device fingerprint, velocity)
│   └── Firebase Firestore integration
└── wrangler.toml                     # Cloudflare deployment config
```

---

## 🎯 Critical Patterns & Conventions

### 1. **Provider State Pattern** (Universal)
Every state change flows through Provider:

```dart
// ✅ CORRECT: Through provider
Consumer<UserProvider>(
  builder: (context, userProvider, _) {
    return Text('₹${userProvider.user.availableBalance}');
  },
)

// ❌ WRONG: Direct Firebase access
final user = await FirebaseFirestore.instance.collection('users').doc(userId).get();
```

**Why:** Allows UI to update automatically when state changes, prevents inconsistency.

### 2. **Service Layer Abstraction** (Universal)
Don't call Firebase directly from screens. Use services:

```dart
// ✅ CORRECT
FirestoreService().recordTaskCompletion(userId, taskId, reward);

// ❌ WRONG
FirebaseFirestore.instance.collection('transactions').add({...});
```

**Service responsibilities:**
- Handle Firebase/API calls
- Implement retry logic & error handling
- Manage timeouts (30-second default)
- Return typed results

### 3. **Daily Earning Cap** (Critical Business Logic)
**Enforced in 3 places:**
1. **Client-side (TaskProvider):** `remainingDaily = 1.50 - dailyEarnings`
2. **API-side (Cloudflare):** Transaction fails if daily limit exceeded
3. **Firestore rules:** Prevents direct overwrites

```dart
// TaskProvider tracks daily progress
double get remainingDaily => (_dailyCap - _dailyEarnings).clamp(0, _dailyCap);

// Before completing any task/game/ad
if (reward > remainingDaily) {
  throw Exception('Daily cap reached');
}
```

**Never trust client-side validation alone.**

### 4. **Real-Time Firestore Streaming** (User Balance)
UserProvider uses Firestore streams for real-time balance sync:

```dart
// In UserProvider.initializeUser()
_userSubscription = _firestoreService
    .getUserStream(userId)
    .listen((user) {
      _user = user;
      notifyListeners(); // UI updates automatically
    });
```

**Why:** Multiple devices/sessions stay in sync; backend updates instantly reflect in UI.

### 5. **Cloudflare API Pattern** (Earning Records)
Every earning action → Cloudflare API call:

```dart
// From TaskProvider
await CloudflareWorkersService().recordTaskEarning(
  userId: userId,
  taskId: taskId,
  deviceId: deviceId,  // For fraud detection
);
```

**Why:**
- Central fraud detection (device fingerprinting, rate limiting)
- Atomic transaction with balance update
- Server-side reward validation

### 6. **Error Handling Pattern** (Consistent)
```dart
try {
  // I/O operation
  await _firestoreService.updateBalance(userId, amount);
  _error = null;
} catch (e) {
  _error = 'Failed to update balance: $e';
  debugPrint('Detailed error: $e');
}
notifyListeners();
```

**Pattern:**
- Set `_error` on failure (UI can display)
- Log with `debugPrint()` (visible in debug)
- Always `notifyListeners()` in finally block

---

## 📦 Constants & Configuration

**Edit `lib/core/constants/app_constants.dart` for:**
- Reward amounts (tasks, games, ads, spin)
- Daily limits (max earnings, max actions)
- Cooldown periods (e.g., 30-min game cooldown)
- Withdrawal settings (min/max amounts, age requirements)
- AdMob unit IDs (test IDs configured, use real IDs in production)

```dart
// Example: Adding a new task type
static const Map<String, double> taskRewards = {
  'survey': 0.10,
  'social_share': 0.10,
  'app_rating': 0.10,
  'new_task': 0.15,  // Add here
};
```

---

## 🔄 Common Development Workflows

### Adding a New Screen
1. Create `screens/feature/feature_screen.dart`
2. Use Provider Consumer to access state:
   ```dart
   Consumer<UserProvider>(
     builder: (context, userProvider, _) => Scaffold(...)
   )
   ```
3. Add to navigation in `main.dart` routes and `MainNavigationScreen`
4. Update theme styling from `AppTheme`

### Adding an Earning Action (e.g., Quiz)
1. Add to `AppConstants.taskRewards` (or create `quizRewards`)
2. Create `services/quiz_service.dart` (handle quiz logic)
3. Add `recordQuizResult()` to `FirestoreService`
4. Add `recordQuizResult()` to `TaskProvider` (updates `dailyEarnings`)
5. Create UI in screen, call provider method
6. Add API endpoint in Cloudflare Worker (`/api/earn/quiz`)

### Debugging Balance Issues
1. Check `UserProvider.user.availableBalance` in debug console
2. Verify Firestore `users/{userId}/availableBalance` directly
3. Check Cloudflare logs: `wrangler tail` (shows fraud rejections)
4. Trace flow: Screen → Provider → Service → API → Firestore

### Deploying Backend Changes
```bash
cd cloudflare-worker
npm run deploy:prod  # Deploy to production
wrangler tail        # View live logs
```

---

## 🚀 Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Analyze code (lint check)
flutter analyze

# Format code
dart format lib/

# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Build APK for Android
flutter build apk --release

# Build IPA for iOS
flutter build ios --release

# Run tests
flutter test

# Local Cloudflare Worker development
cd cloudflare-worker && npm run dev
```

---

## 🔐 Security & Fraud Prevention

**Client-Side Checks:**
- Daily earning cap (TaskProvider)
- Cooldown timers (CooldownService)
- Input validation (email, UPI format)

**Server-Side Checks (Cloudflare):**
- Rate limiting (100 req/min/IP, 50 req/min/user)
- Device fingerprinting (detect multiple devices)
- Impossible completion time (task in 1 second = fraud)
- Velocity analysis (too many actions too fast)

**Database Rules (Firestore):**
- Only backend can update balances
- User can only read/update own data
- Timestamp verification

**Pattern in code:**
```dart
// Client-side gate
if (reward > remainingDaily) return;

// But ALWAYS trust server response
final result = await CloudflareWorkersService().recordTaskEarning(...);
// Server might reject even if client-side check passed
```

---

## 🧪 Testing Patterns

### Unit Test Example (Provider)
```dart
test('TaskProvider updates dailyEarnings', () {
  final provider = TaskProvider();
  provider.completeTask('user1', 'task1', 0.10);
  expect(provider.dailyEarnings, 0.10);
  expect(provider.remainingDaily, 1.40);
});
```

### Widget Test Example
```dart
testWidgets('HomeScreen displays balance', (WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<UserProvider>(
      create: (_) => UserProvider()..setUser(testUser),
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  expect(find.text('₹0.00'), findsOneWidget);
});
```

---

## 📊 Code Statistics & Metrics

| Component | Count | Purpose |
|-----------|-------|---------|
| Screens | 7 | Main UX flows |
| Widgets | 15+ | Reusable components |
| Services | 15 | Backend I/O logic |
| Providers | 2 | State management |
| Models | 4 | Data structures |
| Cloudflare Endpoints | 7 | API routes |
| Lines (Frontend) | 1600+ | Dart code |
| Lines (Backend) | 1000+ | TypeScript code |

---

## 🔗 External Dependencies

**Critical (directly used):**
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Backend
- `google_mobile_ads` - Monetization (6 ad types)
- `provider` - State management
- `http` - API calls
- `shared_preferences` - Local storage
- `google_sign_in` - Social login

**UI/UX:**
- `fl_chart` - Charts/graphs
- `lottie` - Animations
- `confetti` - Celebration effects

---

## 📚 Documentation References

| File | Purpose | Read First? |
|------|---------|------------|
| `SETUP.md` | Initial setup | Yes |
| `FIREBASE_SETUP.md` | Firebase config | If backend changes |
| `CLOUDFLARE_WORKERS_SETUP.md` | Worker deployment | If API changes |
| `BACKEND_INTEGRATION_GUIDE.md` | Integration flow | If adding features |
| `DEVELOPMENT.md` | Detailed dev guide | For in-depth help |
| `QUICK_REFERENCE.md` | Command cheat sheet | For quick lookups |

---

## ⚠️ Common Pitfalls

1. **Calling Firebase directly from screens** → Use services
2. **Not checking daily cap** → Always validate `remainingDaily`
3. **Ignoring server response** → Client-side check isn't authoritative
4. **Not using Provider Consumer** → Manual state updates get out of sync
5. **Missing error handling** → Always catch and set `_error`
6. **Hardcoding magic numbers** → Use `AppConstants`
7. **Not testing fraud scenarios** → Test with Cloudflare Worker locally

---

## 🎓 What To Know First

### For Frontend Work:
1. Read `main.dart` to understand routing & provider setup
2. Study `providers/user_provider.dart` (pattern template)
3. Check `core/theme/app_theme.dart` (Material 3 styling)
4. Review `core/constants/app_constants.dart` (all config)

### For Backend Work:
1. Review `cloudflare-worker/src/index.ts` (API structure)
2. Understand `services/cloudflare_workers_service.dart` (Dart wrapper)
3. Study Firestore schema in `services/firestore_service.dart`
4. Check rate limits & fraud detection in Worker code

### For Integration:
1. Trace one earning flow end-to-end (e.g., task completion)
2. Understand real-time Firestore streaming in UserProvider
3. Verify daily cap is enforced at both client & server

---

## 🚀 Next Phase: Phase 3 Integration

**Immediate tasks:**
- Run `flutterfire configure` to link Firebase
- Test end-to-end task completion flow
- Deploy Cloudflare Worker with real Firebase credentials
- Initialize Google AdMob with production ads
- Execute comprehensive fraud detection tests

**Success criteria:**
- User balance updates in real-time
- Daily cap prevents over-earning
- Cloudflare API validates all actions
- No race conditions between devices

---

**Last Updated:** November 2025  
**Maintained By:** Dev-123-win  
**Status:** Production-Ready Infrastructure
