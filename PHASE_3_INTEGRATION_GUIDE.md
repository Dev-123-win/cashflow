# Phase 3: Integration - Step-by-Step Guide

**Status:** Phase 3 In Progress  
**Goal:** Connect frontend screens with backend services and Firebase  
**Timeline:** 48 hours (2 days)

---

## 📋 Phase 3 Checklist

### Step 1: Prepare Environment (15 min)
- [ ] Run `flutter pub get` to install dependencies
- [ ] Verify no major errors in IDE
- [ ] Check firebase_options.dart exists

### Step 2: Update main.dart ✅
- [x] Add Firebase initialization
- [x] Add Google Mobile Ads initialization
- [x] Verify imports

### Step 3: Update Providers ✅
- [x] UserProvider connected to Firestore streams
- [x] TaskProvider connected to earning records
- [x] All methods support Firebase operations

### Step 4: Add Device Utils ✅
- [x] Create device_utils.dart
- [x] Implement getDeviceId() method
- [x] Add device model and OS version helpers

### Step 5: Integration Code (Next)
- [ ] Update HomeScreen with real user data
- [ ] Update TasksScreen with earning integration
- [ ] Update GamesScreen with game recording
- [ ] Update SpinScreen with spinner logic
- [ ] Update WithdrawalScreen with withdrawal requests

### Step 6: Testing (Next)
- [ ] Test Firebase connectivity
- [ ] Test real-time user data sync
- [ ] Test earning recording
- [ ] End-to-end test task completion

---

## 🚀 Current Progress

```
✅ main.dart updated with Firebase init
✅ UserProvider connected to Firestore
✅ TaskProvider with earning methods
✅ Device utilities created
🔄 Screen integration (IN PROGRESS)
📋 Testing (NEXT)
```

---

## 📱 Code Examples for Integration

### Example 1: TasksScreen - Task Completion

Add this to your TasksScreen:

```dart
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../services/cloudflare_workers_service.dart';
import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';

class _TasksScreenState extends State<TasksScreen> {
  final _api = CloudflareWorkersService();
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    _deviceId = await DeviceUtils.getDeviceId();
  }

  Future<void> _completeTask(String taskId, double reward) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (_deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting device info...')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing task completion...'),
          ],
        ),
      ),
    );

    try {
      // Record task earning to backend API
      final result = await _api.recordTaskEarning(
        userId: user.uid,
        taskId: taskId,
        deviceId: _deviceId!,
      );

      // Update local state
      final userProvider = context.read<UserProvider>();
      await userProvider.updateBalance(result['earned'] as double);

      // Record in Firebase via provider
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.completeTask(user.uid, taskId, reward);

      Navigator.pop(context); // Close loading dialog

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task completed! Earned ₹${result['earned']} | Balance: ₹${result['newBalance']}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh UI
      setState(() {});
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update your task card callback:
  // _TaskCard(
  //   title: 'Daily Survey',
  //   description: 'Answer 5 quick questions',
  //   duration: '1 min',
  //   reward: 0.10,
  //   icon: '📝',
  //   onTap: () => _completeTask('survey_1', 0.10),
  // ),
}
```

---

### Example 2: GamesScreen - Game Result

```dart
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../services/cloudflare_workers_service.dart';
import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';

class _GamesScreenState extends State<GamesScreen> {
  final _api = CloudflareWorkersService();
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    _deviceId = await DeviceUtils.getDeviceId();
  }

  Future<void> _recordGameResult(
    String gameId,
    bool won,
    double reward,
  ) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _deviceId == null) return;

    try {
      // Record to backend API
      final result = await _api.recordGameResult(
        userId: user.uid,
        gameId: gameId,
        won: won,
        score: 0, // Your game score
        deviceId: _deviceId!,
      );

      // Update local state
      if (won) {
        final userProvider = context.read<UserProvider>();
        await userProvider.updateBalance(result['earned'] as double);

        final taskProvider = context.read<TaskProvider>();
        await taskProvider.recordGameResult(
          user.uid,
          gameId,
          won,
          reward,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game won! Earned ₹${result['earned']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game lost. Better luck next time!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Use in game completion callback
  // _recordGameResult('tictactoe', true, 0.08);
}
```

---

### Example 3: SpinScreen - Daily Spin

```dart
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../services/cloudflare_workers_service.dart';
import '../../services/ad_service.dart';
import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';

class _SpinScreenState extends State<SpinScreen> {
  final _api = CloudflareWorkersService();
  final _adService = AdService();
  String? _deviceId;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    _deviceId = await DeviceUtils.getDeviceId();
  }

  Future<void> _executeSpin() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _deviceId == null) return;

    if (_spinning) return;

    setState(() => _spinning = true);

    try {
      // Show rewarded ad first
      final adShown = await _adService.showRewardedAd(
        onRewardEarned: (reward) {
          debugPrint('Ad reward earned: $reward');
        },
      );

      if (!adShown) {
        // User closed ad without watching
        setState(() => _spinning = false);
        return;
      }

      // Execute spin after ad
      final result = await _api.executeSpin(
        userId: user.uid,
        deviceId: _deviceId!,
      );

      // Update state
      final reward = result['reward'] as double;
      final userProvider = context.read<UserProvider>();
      await userProvider.updateBalance(reward);

      final taskProvider = context.read<TaskProvider>();
      await taskProvider.recordSpinResult(user.uid, reward);

      // Show reward dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Spin Result'),
            content: Text('You won ₹${reward.toStringAsFixed(2)}!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _spinning = false);
    }
  }

  // Use in spin button:
  // ElevatedButton(
  //   onPressed: _spinning ? null : _executeSpin,
  //   child: Text(_spinning ? 'Spinning...' : 'Daily Spin'),
  // );
}
```

---

### Example 4: WithdrawalScreen - Request Withdrawal

```dart
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../services/cloudflare_workers_service.dart';
import '../../core/utils/device_utils.dart';

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _api = CloudflareWorkersService();
  String? _deviceId;
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    _deviceId = await DeviceUtils.getDeviceId();
  }

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

    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null || _deviceId == null) return;

    setState(() => _processing = true);

    try {
      final result = await _api.requestWithdrawal(
        userId: user.uid,
        amount: amount,
        upiId: _upiController.text,
        deviceId: _deviceId!,
      );

      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal requested: ${result['withdrawalId']}. Processing in 24-48 hours.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _amountController.clear();
      _upiController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _processing = false);
    }
  }

  // Use in submit button:
  // ElevatedButton(
  //   onPressed: _processing ? null : _submitWithdrawal,
  //   child: Text(_processing ? 'Processing...' : 'Request Withdrawal'),
  // );
}
```

---

### Example 5: HomeScreen - Real-time Balance

```dart
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize user from Firebase
    Future.microtask(() {
      final userProvider = context.read<UserProvider>();
      // Initialize with logged-in user's ID
      final userId = /* Get from FirebaseAuth */;
      if (userId.isNotEmpty) {
        userProvider.initializeUser(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;

        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (user.userId.isEmpty) {
          return const Center(child: Text('User not logged in'));
        }

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Display real-time balance
                BalanceCard(
                  balance: user.availableBalance,
                  onWithdraw: () {
                    // Navigate to withdrawal screen
                  },
                ),

                // Display streak
                StreamBuilder(
                  // This updates automatically from Firestore stream
                  builder: (context, snapshot) {
                    return Text(
                      'Current Streak: ${user.currentStreak}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    );
                  },
                ),

                // Your other widgets
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## 📝 Integration Checklist

Before moving to each screen, ensure:

### TasksScreen
- [ ] Import necessary packages
- [ ] Add _getDeviceId() in initState
- [ ] Implement _completeTask() method
- [ ] Update _TaskCard onTap callbacks
- [ ] Test task completion end-to-end

### GamesScreen  
- [ ] Import necessary packages
- [ ] Add _getDeviceId() in initState
- [ ] Implement _recordGameResult() method
- [ ] Update game completion callbacks
- [ ] Test game recording

### SpinScreen
- [ ] Import necessary packages
- [ ] Add _getDeviceId() in initState
- [ ] Implement _executeSpin() method
- [ ] Call AdService before spin
- [ ] Update spin button callback
- [ ] Test spin with reward

### WithdrawalScreen
- [ ] Import necessary packages
- [ ] Add _getDeviceId() in initState
- [ ] Implement _submitWithdrawal() method
- [ ] Add form validation
- [ ] Update submit button callback
- [ ] Test withdrawal request

### HomeScreen
- [ ] Initialize UserProvider on load
- [ ] Use Consumer for real-time updates
- [ ] Display balance and stats
- [ ] Handle loading state
- [ ] Show error messages

---

## 🧪 Testing Each Integration

### Test Task Completion
1. Go to Tasks screen
2. Click "Complete Task"
3. Verify loading dialog shows
4. Check Firebase console for transaction
5. Verify balance updates in real-time
6. Check CloudflareWorkersService logs

### Test Game Result
1. Go to Games screen
2. Play Tic-Tac-Toe game
3. Win the game
4. Verify earnings record
5. Check balance update
6. Verify game result in Firebase

### Test Spin
1. Go to Spin screen
2. Click "Daily Spin"
3. Verify rewarded ad shows
4. Wait for ad completion
5. Verify spin executes
6. Check reward in dialog
7. Verify balance updates

### Test Withdrawal
1. Go to Withdrawal screen
2. Enter amount (minimum ₹50)
3. Enter valid UPI ID
4. Click submit
5. Verify withdrawal request created
6. Check Firebase for withdrawal document
7. Verify user balance deducted

---

## 🐛 Troubleshooting

### Firebase Not Initializing
- Verify google-services.json exists
- Run `flutterfire configure` again
- Check firebase_options.dart is correct

### Providers Not Updating
- Verify UserProvider.initializeUser() is called
- Check Firestore rules allow read access
- Verify user is logged in

### API Calls Failing
- Verify CloudflareWorker is running locally or deployed
- Check network connectivity
- Verify user ID and device ID are valid

### Real-time Updates Not Working
- Verify Firestore stream is connected
- Check user document exists in Firestore
- Verify Firestore security rules

---

## ✅ Success Criteria

Phase 3 is complete when:
- ✅ Firebase initializes without errors
- ✅ User data syncs in real-time
- ✅ Tasks record earnings correctly
- ✅ Games record results correctly
- ✅ Spin wheel works with rewards
- ✅ Withdrawal requests are created
- ✅ Balance updates in real-time
- ✅ All screens integrate with backend

---

**Next Step:** Implement the code examples above, one screen at a time, testing each integration before moving to the next.

**Estimated Time:** 48 hours (2-3 days)

Good luck! 🚀
