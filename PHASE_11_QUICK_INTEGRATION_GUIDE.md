# Phase 11 Screen Integration Quick Reference

**For:** Developers integrating Phase 11 features into remaining screens  
**Screens Done:** Tasks ✓ Withdrawal ✓ Ads ✓ TicTacToe ✓  
**Screens TODO:** MemoryMatch, Quiz, Spin, etc.

---

## 🔧 Copy-Paste Ready Patterns

### Pattern A: Deduplication in Earning Events

**When to use:** Tasks, Ads, Games - any earning transaction

```dart
// 1. Add imports
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/error_states.dart';

// 2. In your method when earning is triggered:
Future<void> _recordEarning(String action, double amount) async {
  final user = fb_auth.FirebaseAuth.instance.currentUser;
  if (user == null) {
    StateSnackbar.showError(context, 'Not logged in');
    return;
  }

  try {
    // Get services
    final dedup = Provider.of<RequestDeduplicationService>(
      context, 
      listen: false,
    );
    final fingerprint = Provider.of<DeviceFingerprintService>(
      context, 
      listen: false,
    );
    final firestore = FirestoreService();

    // Get fingerprint
    final deviceFingerprint = await fingerprint.getDeviceFingerprint();

    // Generate request ID
    final requestId = dedup.generateRequestId(
      user.uid,
      action,
      {'amount': amount, 'timestamp': DateTime.now().millisecondsSinceEpoch},
    );

    // Check cache
    final cached = dedup.getFromLocalCache(requestId);
    if (cached?.success == true) {
      StateSnackbar.showWarning(context, 'Already processed!');
      return;
    }

    // Record to Firestore (CHANGE THIS CALL BASED ON SCREEN)
    // For tasks: await firestore.recordTaskCompletion(...)
    // For ads: await firestore.recordAdView(...)
    // For games: await firestore.recordGameResult(...)
    
    // Cache the result
    await dedup.recordRequest(
      requestId: requestId,
      requestHash: requestId.hashCode.toString(),
      success: true,
      transactionId: '${action}_${DateTime.now().millisecondsSinceEpoch}',
    );

    StateSnackbar.showSuccess(context, 'Earned ₹${amount.toStringAsFixed(2)}');
    
  } catch (e) {
    StateSnackbar.showError(context, 'Error: $e');
  }
}
```

---

### Pattern B: Fee Breakdown Display

**When to use:** Withdrawal, payment screens

```dart
// 1. Add imports
import '../../services/fee_calculation_service.dart';
import '../../widgets/error_states.dart';

// 2. In build method, add state variable:
// late TextEditingController _amountController;
// In initState: _amountController = TextEditingController();
// In dispose: _amountController.dispose();

// 3. Add TextField with onChanged:
TextField(
  controller: _amountController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(hintText: 'Enter amount'),
  onChanged: (_) => setState(() {}), // Redraw on amount change
)

// 4. Show fee breakdown when amount is entered:
if (_amountController.text.isNotEmpty)
  _buildFeeBreakdown(context),

// 5. Add helper method:
Widget _buildFeeBreakdown(BuildContext context) {
  final feeService = Provider.of<FeeCalculationService>(
    context, 
    listen: false,
  );
  final amount = double.tryParse(_amountController.text) ?? 0;
  
  // Validate first
  final (isValid, error) = feeService.validateWithdrawalAmount(amount);
  if (!isValid) {
    return ErrorStateWidget(
      title: 'Invalid Amount',
      message: error,
      icon: Icons.warning_amber,
    );
  }

  // Get breakdown
  final breakdown = feeService.getFeeBreakdown(amount);

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _breakdownRow('Amount', breakdown['grossAmount']!, bold: true),
          const SizedBox(height: 8),
          _breakdownRow('Fee (5%)', breakdown['fee']!, color: Colors.red),
          const Divider(height: 16),
          _breakdownRow(
            'You Get',
            breakdown['netAmount']!,
            bold: true,
            color: Colors.green,
          ),
        ],
      ),
    ),
  );
}

Widget _breakdownRow(
  String label,
  String value, {
  Color? color,
  bool bold = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
    ],
  );
}
```

---

### Pattern C: Error Handling with StateSnackbar

**When to use:** Any place you had ScaffoldMessenger.showSnackBar

```dart
// ❌ OLD (Don't use):
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Error occurred')),
);

// ✅ NEW (Use this):
import '../../widgets/error_states.dart';

// In your code:
StateSnackbar.showSuccess(context, 'Success message');
StateSnackbar.showWarning(context, 'Warning message');
StateSnackbar.showError(context, 'Error message');
```

---

## 📋 Step-by-Step Checklist for New Screen

### For MemoryMatchScreen (or any new game):

- [ ] **Step 1:** Add 3 imports (dedup, fingerprint, error_states)
- [ ] **Step 2:** Find where game result is recorded (game win callback)
- [ ] **Step 3:** Copy deduplication pattern into that callback
- [ ] **Step 4:** Change firestore call to `.recordGameResult()` with requestId + fingerprint
- [ ] **Step 5:** Replace old error messages with `StateSnackbar.show*()` calls
- [ ] **Step 6:** Test: Play game twice, verify second attempt shows "already processed"
- [ ] **Step 7:** Run `flutter analyze` - verify 0 errors
- [ ] **Step 8:** Commit and push

---

## 🎯 Firestore Method Signatures

### For Recording Earnings:

```dart
// Task completion
await firestore.recordTaskCompletion(
  userId,
  taskId, 
  reward,
  requestId: requestId,           // NEW: for dedup
  deviceFingerprint: fingerprint, // NEW: for fraud detection
);

// Game result
await firestore.recordGameResult(
  userId,
  gameId,
  won,      // true/false
  reward,
  requestId: requestId,
  deviceFingerprint: fingerprint,
);

// Ad view
await firestore.recordAdView(
  userId,
  adType,
  reward,
  requestId: requestId,
  deviceFingerprint: fingerprint,
);

// Note: All methods automatically set type: 'earning' 
//       (Firestore rules require this)
```

---

## 🧪 How to Test Your Integration

### Test 1: Deduplication Works

1. Complete task/ad/game once → See success ✓
2. Immediately try again → See "already processed" ⚠️
3. Wait 30+ seconds, try again → See success ✓ (cache expired)

### Test 2: Firestore Shows Both Fields

1. Go to Firebase Console → Firestore
2. Find transactions collection
3. Click on a recent transaction
4. Verify you see:
   - `requestId` field (looks like "req_userid_action_hash")
   - `deviceFingerprint` field (64-char SHA-256 hex)
   - `type` field = "earning"

### Test 3: Fee Calculation Works

1. Enter ₹100 → See breakdown: ₹100 → -₹5 → ₹95
2. Enter ₹50 → See error: "Minimum is ₹100"
3. Enter ₹100,000 → See error: "Maximum is ₹10,000"

### Test 4: Error Messages Show

1. Complete task while offline → See error message
2. Withdrawal with insufficient balance → See error message
3. Complete successfully → See success message

---

## 📊 Service Availability

### RequestDeduplicationService
- Location: `lib/services/request_deduplication_service.dart`
- Methods: 
  - `generateRequestId(userId, action, params)` → String
  - `getFromLocalCache(requestId)` → RequestRecord?
  - `recordRequest(requestId, requestHash, success, transactionId, error)`
- Already in: MultiProvider (main.dart)

### DeviceFingerprintService
- Location: `lib/services/device_fingerprint_service.dart`
- Methods:
  - `getDeviceFingerprint()` → Future<String>
  - `getDeviceInfo()` → Future<Map>
- Already in: MultiProvider (main.dart)

### FeeCalculationService
- Location: `lib/services/fee_calculation_service.dart`
- Methods:
  - `validateWithdrawalAmount(amount)` → (bool, String)
  - `getFeeBreakdown(amount)` → Map<String, String>
- Already in: MultiProvider (main.dart)

### StateSnackbar
- Location: `lib/widgets/error_states.dart`
- Methods:
  - `StateSnackbar.showSuccess(context, message)`
  - `StateSnackbar.showWarning(context, message)`
  - `StateSnackbar.showError(context, message)`
- Provides: Consistent green/orange/red feedback

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Forgetting onChanged on TextField
```dart
// DON'T:
TextField(controller: _amountController, ...)
// If you only enter amount once, fee breakdown won't show

// DO:
TextField(
  controller: _amountController,
  onChanged: (_) => setState(() {}), // This is important!
  ...
)
```

### ❌ Mistake 2: Using old ScaffoldMessenger
```dart
// DON'T:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Done')),
);

// DO:
StateSnackbar.showSuccess(context, 'Done');
```

### ❌ Mistake 3: Forgetting requestId in Firestore calls
```dart
// DON'T:
await firestore.recordTaskCompletion(userId, taskId, reward);
// This bypasses deduplication!

// DO:
await firestore.recordTaskCompletion(
  userId,
  taskId,
  reward,
  requestId: requestId,           // ✓ Include this
  deviceFingerprint: fingerprint, // ✓ And this
);
```

### ❌ Mistake 4: Not checking cache first
```dart
// DON'T:
final requestId = dedup.generateRequestId(...);
await firestore.recordTransaction(...); // Direct record

// DO:
final requestId = dedup.generateRequestId(...);
if (dedup.getFromLocalCache(requestId) != null) return;
await firestore.recordTransaction(...);
```

---

## 🚀 Integration Priority

Based on impact and difficulty:

1. **High Impact, Low Effort:**
   - MemoryMatch game → Use game pattern
   - Quiz game → Use game pattern

2. **Medium Impact, Medium Effort:**
   - Spin screen → New pattern (involves luck)
   - Referral screen → Reference pattern

3. **Low Priority (Can Wait):**
   - Bonus points → Usually automated
   - Leaderboard → Read-only view

---

## 📞 Quick Help

**Q: How do I know if deduplication is working?**  
A: Check Firestore Console after each action. You should see `requestId` field in transaction.

**Q: Can I see the device fingerprint?**  
A: Yes! In Settings screen, add: `await fingerprint.getDeviceFingerprint()` displays first 16 chars.

**Q: What if I get "already processed" incorrectly?**  
A: The cache TTL is 30 seconds. Wait 30+ seconds and try again. Or clear cache in development.

**Q: How do I test on multiple devices?**  
A: Each device will have different fingerprint. Same user on Device A vs Device B will have different requestIds.

**Q: Is the fee 5% everywhere?**  
A: Yes, 5% is hardcoded in FeeCalculationService. To change, update fee_calculation_service.dart:
```dart
const double _FEE_PERCENTAGE = 0.05; // Change this to 0.10 for 10%
```

---

## ✅ Final Checklist Before Commit

- [ ] Imports added (dedup, fingerprint, error_states)
- [ ] Code follows one of the patterns above
- [ ] `flutter analyze` returns "No issues found!"
- [ ] Error messages use StateSnackbar
- [ ] Firestore calls include requestId + fingerprint
- [ ] Cache is checked before recording
- [ ] All optional parameters have defaults
- [ ] Tests pass locally
- [ ] Git diff shows reasonable changes (not too many)

---

**Ready to integrate more screens?** Follow these patterns and you'll have consistent, secure, fraud-resistant earnings! 🚀
