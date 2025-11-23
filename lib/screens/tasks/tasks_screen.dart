import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/firestore_service.dart';
import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/error_states.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [];
  String? _deviceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initializeDeviceId();
  }

  Future<void> _initializeDeviceId() async {
    try {
      _deviceId = await DeviceUtils.getDeviceId();
      debugPrint('Device ID: $_deviceId');
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  void _loadTasks() {
    // Load sample tasks
    setState(() {
      _tasks.clear();
    });
  }

  Future<void> _completeTask(String taskId, String title, double reward) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        StateSnackbar.showError(context, 'User not logged in');
      }
      return;
    }

    if (_deviceId == null) {
      if (mounted) {
        StateSnackbar.showWarning(context, 'Getting device info...');
      }
      return;
    }

    setState(() => _isLoading = true);

    // Show loading dialog
    if (mounted) {
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
    }

    try {
      // Get deduplication and fingerprinting services
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

      // Generate unique request ID for deduplication
      final requestId = dedup.generateRequestId(user.uid, 'task_completion', {
        'taskId': taskId,
        'reward': reward,
      });

      // Check if already processed (prevents duplicate earnings)
      final cachedRecord = dedup.getFromLocalCache(requestId);
      if (cachedRecord != null && cachedRecord.success) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          StateSnackbar.showWarning(
            context,
            'Task already completed! Check your balance.',
          );
        }
        return;
      }

      // Record task completion via Firestore with deduplication fields
      await firestore.recordTaskCompletion(
        user.uid,
        taskId,
        reward,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );

      // Mark as processed in deduplication cache
      await dedup.recordRequest(
        requestId: requestId,
        requestHash: requestId.hashCode.toString(),
        success: true,
        transactionId: '$taskId:${DateTime.now().millisecondsSinceEpoch}',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success
      if (mounted) {
        StateSnackbar.showSuccess(
          context,
          'Task completed! +₹${reward.toStringAsFixed(2)}',
        );

        // Refresh UI
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error completing task: $e');
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        StateSnackbar.showError(context, 'Failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Tasks'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Section
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Progress',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Consumer2<UserProvider, TaskProvider>(
                      builder: (context, userProvider, taskProvider, _) {
                        final completedCount = taskProvider.completedTasks;
                        final totalTasks = 3;
                        final earned = taskProvider.dailyEarnings;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedCount/$totalTasks tasks completed',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '₹${earned.toStringAsFixed(2)} earned',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.successColor),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Consumer<TaskProvider>(
                      builder: (context, taskProvider, _) {
                        final progress = (taskProvider.completedTasks / 3)
                            .clamp(0.0, 1.0);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppTheme.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.successColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Available Tasks
              Text(
                'Available Tasks',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.space12),

              // Daily Survey Task
              _TaskCard(
                title: 'Daily Survey',
                description: 'Answer 5 quick questions',
                duration: '1 min',
                reward: 0.10,
                icon: '📝',
                isLoading: _isLoading,
                onTap: () => _completeTask('survey_1', 'Daily Survey', 0.10),
              ),
              const SizedBox(height: AppTheme.space12),

              // Social Share Task
              _TaskCard(
                title: 'Share & Earn',
                description: 'Share app with friends',
                duration: '30 sec',
                reward: 0.10,
                icon: '📱',
                isLoading: _isLoading,
                onTap: () => _completeTask('share_1', 'Share & Earn', 0.10),
              ),
              const SizedBox(height: AppTheme.space12),

              // Rating Task
              _TaskCard(
                title: 'Rate Us',
                description: 'Rate us on Play Store',
                duration: '1 min',
                reward: 0.10,
                icon: '⭐',
                isLoading: _isLoading,
                onTap: () => _completeTask('rating_1', 'Rate Us', 0.10),
              ),
              const SizedBox(height: AppTheme.space32),

              // Completed Today
              Text(
                'Completed Today',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.space12),

              Consumer<TaskProvider>(
                builder: (context, taskProvider, _) {
                  final completedTasks = taskProvider.tasks
                      .where((t) => t.completed)
                      .toList();

                  if (completedTasks.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          'No completed tasks yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: completedTasks
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.space12,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.space16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      Text(
                                        'Earned ₹${task.reward.toStringAsFixed(2)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String duration;
  final double reward;
  final String icon;
  final VoidCallback onTap;
  final bool isLoading;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.duration,
    required this.reward,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          duration,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Text(
                          '+₹${reward.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppTheme.successColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.arrow_forward, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
