import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/error_states.dart';
import '../../widgets/scale_button.dart';
import '../../widgets/zen_card.dart';
import '../../widgets/shimmer_loading.dart';

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

    // Check backend health
    final cloudflareService = CloudflareWorkersService();
    final isBackendHealthy = await cloudflareService.healthCheck();
    if (!isBackendHealthy) {
      if (mounted) {
        StateSnackbar.showError(
          context,
          'Cannot connect to server. Please try again later.',
        );
      }
      return;
    }

    setState(() => _isLoading = true);

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

      final deviceFingerprint = await fingerprint.getDeviceFingerprint();
      final requestId = dedup.generateRequestId(user.uid, 'task_completion', {
        'taskId': taskId,
        'reward': reward,
      });

      final cachedRecord = dedup.getFromLocalCache(requestId);
      if (cachedRecord != null && cachedRecord.success) {
        if (mounted) {
          StateSnackbar.showWarning(context, 'Task already completed!');
        }
        return;
      }

      await firestore.recordTaskCompletion(
        user.uid,
        taskId,
        reward,
        requestId: requestId,
        deviceFingerprint: deviceFingerprint,
      );

      await dedup.recordRequest(
        requestId: requestId,
        requestHash: requestId.hashCode.toString(),
        success: true,
        transactionId: '$taskId:${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        StateSnackbar.showSuccess(
          context,
          'Task completed! +₹${reward.toStringAsFixed(2)}',
        );
        setState(() {});
      }
    } catch (e) {
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
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Section
              ZenCard(
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

                        return Column(
                          children: [
                            Row(
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
                            ),
                            const SizedBox(height: AppTheme.space12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusS,
                              ),
                              child: LinearProgressIndicator(
                                value: (completedCount / totalTasks).clamp(
                                  0.0,
                                  1.0,
                                ),
                                minHeight: 8,
                                backgroundColor: AppTheme.surfaceVariant,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.successColor,
                                ),
                              ),
                            ),
                          ],
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

              _isLoading
                  ? const Column(
                      children: [
                        ShimmerLoading.rectangular(height: 80),
                        SizedBox(height: AppTheme.space12),
                        ShimmerLoading.rectangular(height: 80),
                        SizedBox(height: AppTheme.space12),
                        ShimmerLoading.rectangular(height: 80),
                      ],
                    )
                  : Column(
                      children: [
                        _TaskCard(
                          title: 'Daily Survey',
                          description: 'Answer 5 quick questions',
                          duration: '1 min',
                          reward: 0.10,
                          icon: Icons.assignment_outlined,
                          color: const Color(0xFF6C63FF),
                          onTap: () =>
                              _completeTask('survey_1', 'Daily Survey', 0.10),
                        ),
                        const SizedBox(height: AppTheme.space12),
                        _TaskCard(
                          title: 'Share & Earn',
                          description: 'Share app with friends',
                          duration: '30 sec',
                          reward: 0.10,
                          icon: Icons.share_outlined,
                          color: const Color(0xFF00D9C0),
                          onTap: () =>
                              _completeTask('share_1', 'Share & Earn', 0.10),
                        ),
                        const SizedBox(height: AppTheme.space12),
                        _TaskCard(
                          title: 'Rate Us',
                          description: 'Rate us on Play Store',
                          duration: '1 min',
                          reward: 0.10,
                          icon: Icons.star_outline,
                          color: const Color(0xFFFFB800),
                          onTap: () =>
                              _completeTask('rating_1', 'Rate Us', 0.10),
                        ),
                      ],
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
                    return ZenCard(
                      child: Center(
                        child: Text(
                          'No completed tasks yet',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
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
                            child: ZenCard(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppTheme.space8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successColor,
                                      size: 20,
                                    ),
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
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        'Earned ₹${task.reward.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
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
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.duration,
    required this.reward,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: ZenCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        duration,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space8,
                          vertical: AppTheme.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Text(
                          '+₹${reward.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
