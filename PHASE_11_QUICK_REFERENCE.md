# Phase 11: Quick Integration Reference

## 🚀 Quick Start - Adding Deduplication to Your Code

### Pattern 1: Task Completion with Deduplication

```dart
// In your task completion handler:
import 'package:provider/provider.dart';
import 'package:cashflow/services/request_deduplication_service.dart';
import 'package:cashflow/services/device_fingerprint_service.dart';
import 'package:cashflow/services/firestore_service.dart';

Future<void> completeTask(String taskId, double reward) async {
  final context = this.context; // Your BuildContext
  final dedup = Provider.of<RequestDeduplicationService>(context, listen: false);
  final fingerprint = Provider.of<DeviceFingerprintService>(context, listen: false);
  final firestore = FirestoreService();

  try {
    // 1. Get device fingerprint
    final deviceFingerprint = await fingerprint.getDeviceFingerprint();

    // 2. Generate unique request ID
    final requestId = dedup.generateRequestId(
      userId: userId,
      action: 'task_completion_$taskId',
      deviceFingerprint: deviceFingerprint,
    );

    // 3. Check if already processed (BEFORE submitting)
    if (await dedup.isDuplicate(requestId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task already completed!')),
      );
      return;
    }

    // 4. Record transaction in Firestore (with requestId)
    await firestore.recordTaskCompletion(
      taskId: taskId,
      reward: reward,
      requestId: requestId,  // ✨ IMPORTANT
      deviceFingerprint: deviceFingerprint,
    );

    // 5. Mark as processed in local cache
    await dedup.recordRequest(requestId);

    // 6. Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task completed! +₹$reward')),
    );
  } catch (e) {
    print('Error completing task: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to complete task')),
    );
  }
}
```

---

## 💰 Pattern 2: Showing Withdrawal Fee Breakdown

```dart
// In your withdrawal confirmation screen:
import 'package:provider/provider.dart';
import 'package:cashflow/services/fee_calculation_service.dart';

class WithdrawalConfirmationDialog extends StatelessWidget {
  final double amount;

  @override
  Widget build(BuildContext context) {
    final feeService = Provider.of<FeeCalculationService>(context);
    final breakdown = feeService.getFeeBreakdown(amount);

    return AlertDialog(
      title: Text('Confirm Withdrawal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _breakdownRow('Amount Requested', breakdown['grossAmount']!),
          _breakdownRow('Withdrawal Fee (5%)', breakdown['fee']!, color: Colors.red),
          Divider(height: 16),
          _breakdownRow(
            'You Will Receive',
            breakdown['netAmount']!,
            color: Colors.green,
            bold: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            processWithdrawal(amount);
          },
          child: Text('Confirm'),
        ),
      ],
    );
  }

  Widget _breakdownRow(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📱 Pattern 3: Game Result with State Management

```dart
// In your game result screen:
import 'package:cashflow/widgets/error_states.dart';

class GameResultScreen extends StatefulWidget {
  final bool won;
  final double reward;

  @override
  _GameResultScreenState createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  bool _isSubmitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return StateBuilder<void>(
      isLoading: _isSubmitting,
      error: _error,
      data: true, // Dummy data, we only care about loading/error
      onRetry: _submitResult,
      loadingMessage: 'Submitting your result...',
      builder: (context, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.won ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: widget.won ? Colors.green : Colors.red,
            ),
            SizedBox(height: 16),
            Text(widget.won ? 'You Won!' : 'Game Over'),
            if (widget.won) ...[
              SizedBox(height: 8),
              Text('+₹${widget.reward.toInt()}'),
            ],
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitResult,
              child: Text('Claim Reward'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitResult() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final dedup = Provider.of<RequestDeduplicationService>(context, listen: false);
      final fingerprint = Provider.of<DeviceFingerprintService>(context, listen: false);
      final firestore = FirestoreService();

      // Get fingerprint
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();

      // Generate request ID
      final requestId = dedup.generateRequestId(
        userId: userId,
        action: 'game_result_${widget.gameType}',
        deviceFingerprint: deviceFingerprint,
      );

      // Check duplicate
      if (await dedup.isDuplicate(requestId)) {
        throw Exception('Result already submitted');
      }

      // Submit to Firestore
      await firestore.recordGameResult(
        gameType: widget.gameType,
        result: widget.won ? 'win' : 'loss',
        reward: widget.reward,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );

      // Mark processed
      await dedup.recordRequest(requestId);

      // Success
      StateSnackbar.showSuccess(context, 'Result submitted! +₹${widget.reward.toInt()}');
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      StateSnackbar.showError(context, _error!);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
```

---

## 🔍 Pattern 4: Checking Device Info (Debug)

```dart
// In your debug/settings screen:
Future<void> showDeviceInfo() async {
  final fingerprintService = Provider.of<DeviceFingerprintService>(context, listen: false);
  
  final fingerprint = await fingerprintService.getDeviceFingerprint();
  final deviceInfo = await fingerprintService.getDeviceInfo();

  print('Device Fingerprint: $fingerprint');
  print('Device Info: $deviceInfo');

  // Show in debug screen:
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Device Info'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform: ${deviceInfo['platform']}'),
            Text('Model: ${deviceInfo['device'] ?? 'N/A'}'),
            Text('Fingerprint: $fingerprint'),
          ],
        ),
      ),
    ),
  );
}
```

---

## ❌ Common Mistakes to Avoid

### ❌ WRONG: Not checking duplicate first
```dart
// DON'T DO THIS:
await firestore.recordEarning(amount); // ❌ Can be called twice!
await dedup.recordRequest(requestId);
```

### ✅ CORRECT: Check duplicate before submit
```dart
// DO THIS:
if (!await dedup.isDuplicate(requestId)) { // ✅ Check first!
  await firestore.recordEarning(amount, requestId);
  await dedup.recordRequest(requestId);
}
```

---

### ❌ WRONG: Forgetting to pass requestId to Firestore
```dart
// DON'T DO THIS:
await firestore.recordEarning(amount); // ❌ No requestId!
```

### ✅ CORRECT: Always include requestId in Firestore
```dart
// DO THIS:
await firestore.recordEarning(amount, requestId: requestId); // ✅ Matches rules validation
```

---

### ❌ WRONG: Showing error without retry
```dart
// DON'T DO THIS:
if (error != null) {
  return Text('Error: $error'); // ❌ No way to recover
}
```

### ✅ CORRECT: Use ErrorStateWidget with retry
```dart
// DO THIS:
if (error != null) {
  return ErrorStateWidget(
    title: 'Failed to load',
    message: error,
    onRetry: () => loadData(), // ✅ User can try again
  );
}
```

---

## 📊 Firestore Rules Field Updates

All transaction documents MUST now include:

```dart
{
  // Existing fields
  'userId': userId,
  'type': 'earning|withdrawal|refund',
  'amount': 10,
  'timestamp': FieldValue.serverTimestamp(),
  'status': 'completed',

  // ✨ NEW FIELDS (Required)
  'requestId': 'sha256_hash_here',           // Required - prevents duplicates
  'deviceFingerprint': 'sha256_hash_here',   // Required - fraud detection
}
```

---

## 🧪 Testing Requests

### Test 1: Verify Deduplication Works
```dart
// Submit same request twice
final requestId = dedup.generateRequestId(userId, 'test_action', fingerprint);

// First submit should work
await firestore.recordEarning(10, requestId);
await dedup.recordRequest(requestId);

// Second submit should be blocked
expect(await dedup.isDuplicate(requestId), true); // ✅ Should be true
```

### Test 2: Verify Fee Calculation
```dart
final feeService = FeeCalculationService();
expect(feeService.calculateWithdrawalFee(100), 5);      // 5%
expect(feeService.calculateWithdrawalFee(1000), 50);    // Capped at max
expect(feeService.calculateWithdrawalFee(50), 1);       // Min fee
```

### Test 3: Verify Device Fingerprint Is Consistent
```dart
final fpService = DeviceFingerprintService();
final fp1 = await fpService.getDeviceFingerprint();
final fp2 = await fpService.getDeviceFingerprint();
expect(fp1, fp2); // ✅ Should be same (cached)
```

---

## 📞 Service Reference

### RequestDeduplicationService
```dart
// Methods
String generateRequestId(
  {required String userId, 
   required String action, 
   required String deviceFingerprint}
);

Future<bool> isDuplicate(String requestId);
Future<void> recordRequest(String requestId);
Future<List<String>> getCachedRequests();
Future<void> clearExpiredEntries();
Future<Map<String, dynamic>> getCacheStats();
```

### FeeCalculationService  
```dart
// Methods
double calculateWithdrawalFee(double amount);
double calculateNetAmount(double amount);
Map<String, String> getFeeBreakdown(double amount);
(bool isValid, String? error) validateWithdrawalAmount(double amount);
double estimateMonthlyRevenue({required int activeUsers, required double avgWithdrawalAmount});
List<Map<String, String>> getFeeExamples();
```

### DeviceFingerprintService
```dart
// Methods
Future<String> getDeviceFingerprint();
Future<Map<String, String>> getDeviceInfo();
void clearCache();
```

---

## 🎯 Priority Implementation Order

1. **CRITICAL:** Update `FirestoreService` to include `requestId` and `deviceFingerprint`
2. **HIGH:** Integrate deduplication into task completion handler
3. **HIGH:** Integrate deduplication into game result submission
4. **HIGH:** Update withdrawal flow to show fee breakdown
5. **MEDIUM:** Add error states to all screens
6. **MEDIUM:** Add loading states during API calls
7. **NICE:** Add empty states for zero results

---

**Last Updated:** Phase 11
**Status:** Ready for Integration
