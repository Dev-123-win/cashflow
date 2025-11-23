# Phase 11: Screen Integration Guide

## Overview
This guide shows how to integrate Phase 11 security and UX improvements into your screens with copy-paste code patterns.

---

## 1. Task Completion Screen Integration

### Pattern: Record task with deduplication

```dart
import 'package:provider/provider.dart';
import 'package:cashflow/services/request_deduplication_service.dart';
import 'package:cashflow/services/device_fingerprint_service.dart';
import 'package:cashflow/services/firestore_service.dart';
import 'package:cashflow/widgets/error_states.dart';

class TaskCompletionHandler {
  static Future<void> submitTaskCompletion(
    BuildContext context,
    String taskId,
    double reward,
  ) async {
    final dedup = Provider.of<RequestDeduplicationService>(context, listen: false);
    final fingerprint = Provider.of<DeviceFingerprintService>(context, listen: false);
    final firestore = FirestoreService();
    
    try {
      // 1. Get device fingerprint
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();
      
      // 2. Get current user ID (from your auth)
      final userId = 'current_user_id'; // Replace with actual userId
      
      // 3. Generate unique request ID
      final requestId = dedup.generateRequestId(
        userId: userId,
        action: 'task_completion_$taskId',
        deviceFingerprint: deviceFingerprint,
      );
      
      // 4. Check if already processed (prevents duplicates)
      if (await dedup.isDuplicate(requestId)) {
        StateSnackbar.showWarning(
          context,
          'Task already completed! Check your balance.',
        );
        return;
      }
      
      // 5. Record in Firestore with requestId
      await firestore.recordTaskCompletion(
        userId,
        taskId,
        reward,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );
      
      // 6. Mark as processed in local cache
      await dedup.recordRequest(requestId);
      
      // 7. Show success
      StateSnackbar.showSuccess(
        context,
        'Task completed! +₹${reward.toInt()}',
      );
      
    } catch (e) {
      StateSnackbar.showError(context, 'Failed: $e');
    }
  }
}
```

---

## 2. Game Result Screen Integration

### Pattern: Submit game result with error recovery

```dart
class GameResultScreen extends StatefulWidget {
  final String gameId;
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
    // Use StateBuilder to handle loading/error/empty states
    return StateBuilder<void>(
      isLoading: _isSubmitting,
      error: _error,
      data: true, // Dummy data, we only care about states
      onRetry: _submitResult,
      loadingMessage: 'Submitting your result...',
      builder: (context, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result icon
            Icon(
              widget.won ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: widget.won ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            
            // Result text
            Text(
              widget.won ? 'You Won! 🎉' : 'Game Over',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            
            if (widget.won) ...[
              const SizedBox(height: 12),
              Text(
                '+₹${widget.reward.toInt()}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitResult,
              child: Text(widget.won ? 'Claim Reward' : 'Continue'),
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
      final dedup = Provider.of<RequestDeduplicationService>(
        context,
        listen: false,
      );
      final fingerprint = Provider.of<DeviceFingerprintService>(
        context,
        listen: false,
      );
      final firestore = FirestoreService();

      // Get device fingerprint
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();
      final userId = 'current_user_id'; // Replace with actual userId

      // Generate request ID
      final requestId = dedup.generateRequestId(
        userId: userId,
        action: 'game_result_${widget.gameId}',
        deviceFingerprint: deviceFingerprint,
      );

      // Check for duplicates
      if (await dedup.isDuplicate(requestId)) {
        throw Exception('Result already submitted');
      }

      // Submit to Firestore
      await firestore.recordGameResult(
        userId,
        widget.gameId,
        widget.won,
        widget.reward,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );

      // Mark processed
      await dedup.recordRequest(requestId);

      // Success
      StateSnackbar.showSuccess(
        context,
        'Result submitted! +₹${widget.reward.toInt()}',
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
```

---

## 3. Withdrawal Screen Integration

### Pattern: Show fee breakdown and process withdrawal

```dart
import 'package:provider/provider.dart';
import 'package:cashflow/services/fee_calculation_service.dart';

class WithdrawalScreen extends StatefulWidget {
  @override
  _WithdrawalScreenState createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feeService = Provider.of<FeeCalculationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Balance'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount (₹100 - ₹10,000)',
                labelText: 'Amount',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Fee breakdown (if amount entered)
            if (_amountController.text.isNotEmpty)
              _buildFeeBreakdown(feeService),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showConfirmationDialog(context, feeService),
                child: const Text('Review & Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeBreakdown(FeeCalculationService feeService) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final breakdown = feeService.getFeeBreakdown(amount);
    
    // Validate amount
    final (isValid, error) = feeService.validateWithdrawalAmount(amount);

    if (!isValid) {
      return ErrorStateWidget(
        title: 'Invalid Amount',
        message: error,
        icon: Icons.warning_amber,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breakdownRow(
              'Amount Requested',
              breakdown['grossAmount']!,
              bold: true,
            ),
            const SizedBox(height: 8),
            _breakdownRow(
              'Withdrawal Fee (5%)',
              breakdown['fee']!,
              color: Colors.red,
            ),
            const Divider(height: 16),
            _breakdownRow(
              'You Will Receive',
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
        Text(
          label,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    FeeCalculationService feeService,
  ) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final breakdown = feeService.getFeeBreakdown(amount);

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please review your withdrawal details:'),
            const SizedBox(height: 16),
            _breakdownRow('Amount', breakdown['grossAmount']!),
            _breakdownRow('Fee', breakdown['fee']!, color: Colors.red),
            Divider(),
            _breakdownRow(
              'You Receive',
              breakdown['netAmount']!,
              bold: true,
              color: Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processWithdrawal(amount);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal(double amount) async {
    // Implement actual withdrawal logic here
    StateSnackbar.showSuccess(
      context,
      'Withdrawal request submitted! You will receive ${amount - (amount * 0.05)} soon.',
    );
  }
}
```

---

## 4. Task List Screen Integration

### Pattern: Show error/loading/empty states

```dart
import 'package:cashflow/widgets/error_states.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _isLoading = false;
  String? _error;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch tasks from Firestore
      // _tasks = await firestore.getTasks();
      // For now, simulating empty state
      _tasks = [];
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use StateBuilder to handle all states automatically
    return Scaffold(
      appBar: AppBar(title: const Text('Available Tasks')),
      body: StateBuilder<List<Task>>(
        isLoading: _isLoading,
        error: _error,
        data: _tasks.isEmpty ? null : _tasks,
        onRetry: _loadTasks,
        loadingMessage: 'Loading tasks...',
        emptyTitle: 'No tasks available',
        emptyMessage: 'Check back later for more tasks to complete.',
        emptyIcon: Icons.assignment_outlined,
        builder: (context, tasks) {
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onComplete: () => TaskCompletionHandler.submitTaskCompletion(
                  context,
                  task.id,
                  task.reward,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 5. Ad Watch Screen Integration

### Pattern: Record ad view with deduplication

```dart
class AdViewScreen extends StatefulWidget {
  final String adType;
  final double reward;

  @override
  _AdViewScreenState createState() => _AdViewScreenState();
}

class _AdViewScreenState extends State<AdViewScreen> {
  bool _adWatched = false;

  void _onAdComplete() async {
    final dedup = Provider.of<RequestDeduplicationService>(context, listen: false);
    final fingerprint = Provider.of<DeviceFingerprintService>(context, listen: false);
    final firestore = FirestoreService();

    try {
      // Get fingerprint
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();
      final userId = 'current_user_id'; // Replace with actual userId

      // Generate request ID
      final requestId = dedup.generateRequestId(
        userId: userId,
        action: 'ad_view_${widget.adType}',
        deviceFingerprint: deviceFingerprint,
      );

      // Check duplicate
      if (await dedup.isDuplicate(requestId)) {
        StateSnackbar.showWarning(context, 'Ad reward already claimed');
        return;
      }

      // Record ad view
      await firestore.recordAdView(
        userId,
        widget.adType,
        widget.reward,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );

      // Mark processed
      await dedup.recordRequest(requestId);

      setState(() => _adWatched = true);
      StateSnackbar.showSuccess(context, '+₹${widget.reward.toInt()} earned!');
      
    } catch (e) {
      StateSnackbar.showError(context, 'Failed to claim reward');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _adWatched ? Icons.check_circle : Icons.play_arrow,
              size: 80,
              color: _adWatched ? Colors.green : Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              _adWatched ? 'Ad Watched!' : 'Watch Ad',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _adWatched ? null : _onAdComplete,
              child: Text(_adWatched ? 'Reward Claimed' : 'Watch Ad (+₹${widget.reward.toInt()})'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. Settings/Debug Screen

### Pattern: Show device fingerprint and cache stats

```dart
class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _fingerprint;
  Map<String, dynamic>? _cacheStats;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final fingerprint = Provider.of<DeviceFingerprintService>(
      context,
      listen: false,
    );
    final dedup = Provider.of<RequestDeduplicationService>(context, listen: false);

    final fp = await fingerprint.getDeviceFingerprint();
    final stats = await dedup.getCacheStats();

    setState(() {
      _fingerprint = fp;
      _cacheStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device Info Section
          _buildSection(
            'Device Information',
            [
              _buildRow('Device ID (first 16 chars)', _fingerprint?.substring(0, 16) ?? 'Loading...'),
            ],
          ),
          const SizedBox(height: 24),

          // Cache Stats Section
          if (_cacheStats != null)
            _buildSection(
              'Deduplication Cache',
              [
                _buildRow(
                  'Valid Entries',
                  _cacheStats!['validEntries'].toString(),
                ),
                _buildRow(
                  'Expired Entries',
                  _cacheStats!['expiredEntries'].toString(),
                ),
                _buildRow(
                  'Total',
                  _cacheStats!['totalEntries'].toString(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

---

## Integration Checklist

- [ ] Add Provider dependencies for RequestDeduplicationService
- [ ] Add Provider dependencies for DeviceFingerprintService
- [ ] Add Provider dependencies for FeeCalculationService
- [ ] Integrate error/loading/empty state handlers in all list screens
- [ ] Add requestId/deviceFingerprint to task completion
- [ ] Add requestId/deviceFingerprint to game results
- [ ] Add requestId/deviceFingerprint to ad views
- [ ] Add fee breakdown UI to withdrawal screen
- [ ] Add withdrawal confirmation dialog
- [ ] Monitor Firestore quota usage
- [ ] Test deduplication (submit twice, verify only counts once)
- [ ] Test device fingerprinting across devices

---

**Next Step:** Copy these patterns into your screen files and replace placeholder IDs with actual user IDs from your auth system.
