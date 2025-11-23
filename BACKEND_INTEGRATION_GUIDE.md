# Backend Integration Guide

Complete guide to integrating the Cloudflare Workers backend with the EarnQuest Flutter app.

## Overview

The backend integration consists of:

1. **Cloudflare Workers** - Serverless API backend
2. **FirestoreService** - Direct Firestore database operations
3. **CloudflareWorkersService** - Client-side API wrapper
4. **AdService** - Google AdMob integration
5. **Provider Integration** - State management and real-time sync

## Phase 1: Cloudflare Workers Setup

### 1.1 Installation

```bash
# Navigate to cloudflare-worker directory
cd cloudflare-worker

# Install dependencies
npm install

# Login to Cloudflare
wrangler login
```

### 1.2 Development Testing

```bash
# Start local dev server
npm run dev

# Server runs at http://localhost:8787
```

### 1.3 Testing Endpoints

Open a terminal and test each endpoint:

```bash
# Task earning
curl -X POST http://localhost:8787/api/earn/task \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","taskId":"survey_1","deviceId":"device_1"}'

# Game result
curl -X POST http://localhost:8787/api/earn/game \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","gameId":"tictactoe","won":true,"score":45,"deviceId":"device_1"}'

# Ad view
curl -X POST http://localhost:8787/api/earn/ad \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","adType":"rewarded","deviceId":"device_1"}'

# Daily spin
curl -X POST http://localhost:8787/api/spin \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","deviceId":"device_1"}'

# Get leaderboard
curl http://localhost:8787/api/leaderboard?limit=10

# Get user stats
curl "http://localhost:8787/api/user/stats?userId=test"

# Withdrawal request
curl -X POST http://localhost:8787/api/withdrawal/request \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","amount":100,"upiId":"user@bank","deviceId":"device_1"}'
```

### 1.4 Deployment

```bash
# Deploy to production (earnquest.workers.dev)
npm run deploy:prod

# View logs
wrangler tail
```

## Phase 2: Firebase Setup in Flutter

### 2.1 Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  
  runApp(const MyApp());
}
```

### 2.2 Run flutterfire configure

```bash
# Generate Firebase configuration files
flutterfire configure

# Select your Firebase project when prompted
# This will update lib/firebase_options.dart
```

## Phase 3: Provider Integration

### 3.1 Update UserProvider

Update `lib/providers/user_provider.dart` to sync with Firestore:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  String? _error;
  bool _loading = false;

  User? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;
  StreamSubscription? _userSubscription;

  // Initialize user after login
  Future<void> initializeUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    _loading = true;
    notifyListeners();

    try {
      // Listen to real-time user updates
      _userSubscription = _firestoreService
          .getUserStream(firebaseUser.uid)
          .listen((user) {
            _user = user;
            _error = null;
            notifyListeners();
          });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update balance from earning
  Future<void> updateBalance(double amount) async {
    if (_user == null) return;
    
    try {
      await _firestoreService.updateBalance(_user!.userId, amount);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _userSubscription?.cancel();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
```

### 3.2 Update TaskProvider

Update `lib/providers/task_provider.dart`:

```dart
import '../services/firestore_service.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _loading = false;

  List<TaskModel> get tasks => _tasks;
  bool get loading => _loading;

  final _firestoreService = FirestoreService();

  // Complete task
  Future<void> completeTask(
    String userId,
    String taskId,
    double reward,
  ) async {
    try {
      _loading = true;
      notifyListeners();

      await _firestoreService.recordTaskCompletion(
        userId,
        taskId,
        reward,
      );

      // Update local task status
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index >= 0) {
        _tasks[index] = _tasks[index].copyWith(completed: true);
        notifyListeners();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

## Phase 4: Screen Integration

### 4.1 HomeScreen - Display Ads

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _adService = AdService();
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() async {
    _bannerAd = await _adService.createBannerAd();
    setState(() {});
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // ... existing content
            ),
          ),
          // Banner ad at bottom
          if (_bannerAd != null)
            SizedBox(
              height: 50,
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
```

### 4.2 TasksScreen - Earning Integration

```dart
import '../services/cloudflare_workers_service.dart';
import 'package:device_info_plus/device_info_plus.dart';

class TasksScreen extends StatefulWidget {
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _workersService = CloudflareWorkersService();
  final _deviceInfo = DeviceInfoPlugin();
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  Future<void> _completeTask(String taskId) async {
    if (_deviceId == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    showLoadingDialog(context);

    try {
      // Record with Cloudflare Workers
      final result = await _workersService.recordTaskEarning(
        userId: userId,
        taskId: taskId,
        deviceId: _deviceId!,
      );

      Navigator.pop(context); // Close loading dialog

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Earned ₹${result['earned']} | Balance: ₹${result['newBalance']}',
          ),
        ),
      );

      // Update provider
      final userProvider = context.read<UserProvider>();
      await userProvider.updateBalance(result['earned']);

      // Refresh screen
      setState(() {});
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: ListView.builder(
        itemCount: tasksList.length,
        itemBuilder: (context, index) {
          final task = tasksList[index];
          return TaskCard(
            task: task,
            onTap: () => _completeTask(task.id),
          );
        },
      ),
    );
  }
}
```

### 4.3 SpinScreen - Rewarded Ad + Spin

```dart
class SpinScreen extends StatefulWidget {
  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  final _adService = AdService();
  final _workersService = CloudflareWorkersService();
  bool _spinning = false;

  Future<void> _showRewardedAdAndSpin() async {
    _spinning = true;
    
    // Show rewarded ad first
    final rewarded = await _adService.showRewardedAd(
      onRewardEarned: (int amount) {
        debugPrint('Reward earned: $amount');
      },
    );

    if (!rewarded) {
      _spinning = false;
      return;
    }

    // Then execute spin
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final deviceId = await _getDeviceId();

    try {
      final result = await _workersService.executeSpin(
        userId: userId,
        deviceId: deviceId,
      );

      // Show reward
      _showRewardDialog(result['reward']);

      // Update balance
      final userProvider = context.read<UserProvider>();
      await userProvider.updateBalance(result['reward']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      _spinning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _spinning ? null : _showRewardedAdAndSpin,
          child: Text(
            _spinning ? 'Spinning...' : 'Daily Spin',
          ),
        ),
      ),
    );
  }
}
```

### 4.4 LeaderboardScreen - Real-time Leaderboard

```dart
class LeaderboardScreen extends StatefulWidget {
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _workersService = CloudflareWorkersService();
  late Future<List<Map<String, dynamic>>> _leaderboard;

  @override
  void initState() {
    super.initState();
    _leaderboard = _workersService.getLeaderboard(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leaderboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final leaderboard = snapshot.data ?? [];

          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return LeaderboardTile(
                rank: entry['rank'],
                name: entry['displayName'],
                earnings: entry['totalEarnings'],
              );
            },
          );
        },
      ),
    );
  }
}
```

### 4.5 WithdrawalScreen - Withdrawal Integration

```dart
class WithdrawalScreen extends StatefulWidget {
  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _workersService = CloudflareWorkersService();
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  bool _processing = false;

  Future<void> _submitWithdrawal() async {
    if (_amountController.text.isEmpty || _upiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal: ₹50')),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final deviceId = await _getDeviceId();

      final result = await _workersService.requestWithdrawal(
        userId: userId,
        amount: amount,
        upiId: _upiController.text,
        deviceId: deviceId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Withdrawal request submitted: ${result['withdrawalId']}')),
      );

      _amountController.clear();
      _upiController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _upiController,
              decoration: const InputDecoration(labelText: 'UPI ID'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _processing ? null : _submitWithdrawal,
              child: Text(_processing ? 'Processing...' : 'Request Withdrawal'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Phase 5: Testing

### 5.1 Test Checklist

- [ ] Firebase initialization successful
- [ ] AdMob ads displaying correctly
- [ ] Task completion records in Firestore
- [ ] Balance updates in real-time
- [ ] Game results recorded
- [ ] Daily spin working
- [ ] Leaderboard populating
- [ ] Withdrawal requests submitted
- [ ] Rate limiting working (test rapid requests)
- [ ] Fraud detection active

### 5.2 Manual Testing

```bash
# Run app
flutter run

# Check logs
flutter logs
```

### 5.3 Network Debugging

```bash
# View network requests (Android)
adb shell setprop log.tag.http2 VERBOSE

# View logs
adb logcat | grep http2
```

## Phase 6: Deployment

### 6.1 Build APK

```bash
flutter build apk --release
```

### 6.2 Build iOS

```bash
flutter build ios --release
```

### 6.3 Deploy to Cloudflare Workers

```bash
cd cloudflare-worker
npm run deploy:prod
```

## Troubleshooting

### Firebase Not Initializing

```dart
// Verify in main.dart
print('Firebase initialized: ${Firebase.apps.isNotEmpty}');
```

### Ads Not Showing

- Verify AdMob App ID and Ad Unit IDs in constants
- Check device is not in test mode
- Ensure network connectivity

### API Calls Failing

```bash
# Test endpoint with curl
curl -v https://earnquest.workers.dev/api/earn/task

# Check worker logs
wrangler tail
```

### Rate Limiting Issues

- Wait for rate limit window to reset
- Check rate limit settings in worker code
- Verify device ID is unique per device

## Next Steps

1. Implement payment gateway (Razorpay)
2. Set up webhook handlers for payment confirmations
3. Add analytics event tracking
4. Implement device fingerprinting
5. Set up monitoring and alerts
6. Performance optimization
7. Security audit

---

For more details, see:
- `CLOUDFLARE_WORKERS_SETUP.md` - Worker setup
- `FIREBASE_SETUP.md` - Firebase configuration
- `DEVELOPMENT.md` - Development workflow
