import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../services/request_deduplication_service.dart';
import '../../services/device_fingerprint_service.dart';
import '../../services/cloudflare_workers_service.dart';
import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';
import '../../widgets/scale_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';
import '../../widgets/zen_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [];
  String? _deviceId;
  final Set<String> _loadingTaskIds = {};

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
    // Load sample tasks - in a real app these might come from a backend config
    setState(() {
      _tasks.clear();
    });
  }

  Future<void> _launchTaskAction(String taskId, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _handleTaskTap(
    String taskId,
    String title,
    double reward,
    String actionUrl,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user.completedTaskIds.contains(taskId)) {
      return; // Already completed
    }

    if (_loadingTaskIds.contains(taskId)) return;

    setState(() {
      _loadingTaskIds.add(taskId);
    });

    try {
      // 1. Launch external action
      await _launchTaskAction(taskId, actionUrl);

      // 2. Wait for user to return (simulate time spent)
      // In a real app, we might use AppLifecycleState to detect return
      await Future.delayed(const Duration(seconds: 5));

      // 3. Complete task
      if (mounted) {
        await _completeTask(taskId, title, reward);
      }
    } catch (e) {
      if (mounted) {
        StateSnackbar.showError(context, 'Task failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTaskIds.remove(taskId);
        });
      }
    }
  }

  Future<void> _completeTask(String taskId, String title, double reward) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      StateSnackbar.showError(context, 'User not logged in');
      return;
    }

    if (_deviceId == null) {
      StateSnackbar.showWarning(context, 'Getting device info...');
      return;
    }

    final dedup = Provider.of<RequestDeduplicationService>(
      context,
      listen: false,
    );
    final fingerprint = Provider.of<DeviceFingerprintService>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

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

    try {
      final deviceFingerprint = await fingerprint.getDeviceFingerprint();
      final requestId = dedup.generateRequestId(user.uid, 'task_completion', {
        'taskId': taskId,
        'reward': reward,
      });

      // Check local dedup
      final cachedRecord = dedup.getFromLocalCache(requestId);
      if (cachedRecord != null && cachedRecord.success) {
        if (mounted) {
          StateSnackbar.showWarning(context, 'Task already completed!');
        }
        return;
      }

      // Check user profile (double check)
      if (userProvider.user.completedTaskIds.contains(taskId)) {
        if (mounted) {
          StateSnackbar.showWarning(context, 'Task already completed!');
        }
        return;
      }

      // Call Backend
      // We use the cloudflare service to record task earning which handles validation
      final result = await cloudflareService.recordTaskEarning(
        userId: user.uid,
        taskId: taskId,
        deviceId: deviceFingerprint,
      );

      if (result['success'] == true) {
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
          // Refresh user to update completedTaskIds
          await userProvider.refreshUser();
        }
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        StateSnackbar.showError(context, 'Failed: ${e.toString()}');
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
                    Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        final knownTaskIds = [
                          'survey_1',
                          'share_1',
                          'rating_1',
                        ];
                        final completedToday = knownTaskIds
                            .where(
                              (id) => userProvider.user.completedTaskIds
                                  .contains(id),
                            )
                            .length;
                        final totalTasks = knownTaskIds.length;

                        final earned = completedToday * 0.10;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$completedToday/$totalTasks tasks completed',
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
                                value: totalTasks > 0
                                    ? (completedToday / totalTasks).clamp(
                                        0.0,
                                        1.0,
                                      )
                                    : 0,
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

              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return Column(
                    children: [
                      _TaskCard(
                        title: 'Daily Survey',
                        description: 'Answer 5 quick questions',
                        duration: '1 min',
                        reward: 0.10,
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF6C63FF),
                        isCompleted: userProvider.user.completedTaskIds
                            .contains('survey_1'),
                        isLoading: _loadingTaskIds.contains('survey_1'),
                        onTap: () => _handleTaskTap(
                          'survey_1',
                          'Daily Survey',
                          0.10,
                          'https://google.com',
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      _TaskCard(
                        title: 'Share & Earn',
                        description: 'Share app with friends',
                        duration: '30 sec',
                        reward: 0.10,
                        icon: Icons.share_outlined,
                        color: const Color(0xFF00D9C0),
                        isCompleted: userProvider.user.completedTaskIds
                            .contains('share_1'),
                        isLoading: _loadingTaskIds.contains('share_1'),
                        onTap: () => _handleTaskTap(
                          'share_1',
                          'Share & Earn',
                          0.10,
                          'https://whatsapp.com',
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      _TaskCard(
                        title: 'Rate Us',
                        description: 'Rate us on Play Store',
                        duration: '1 min',
                        reward: 0.10,
                        icon: Icons.star_outline,
                        color: const Color(0xFFFFB800),
                        isCompleted: userProvider.user.completedTaskIds
                            .contains('rating_1'),
                        isLoading: _loadingTaskIds.contains('rating_1'),
                        onTap: () => _handleTaskTap(
                          'rating_1',
                          'Rate Us',
                          0.10,
                          'market://details?id=com.example.cashflow',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppTheme.space32),

              // Completed Today
              Text(
                'Completed Today',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.space12),

              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final knownTaskIds = ['survey_1', 'share_1', 'rating_1'];
                  final completedTasks = knownTaskIds
                      .where(
                        (id) => userProvider.user.completedTaskIds.contains(id),
                      )
                      .toList();

                  if (completedTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(AppAssets.emptyTasks, height: 200),
                          const SizedBox(height: 16),
                          Text(
                            'No completed tasks yet',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: completedTasks
                        .map(
                          (taskId) => Padding(
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
                                        _getTaskTitle(taskId),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        'Earned ₹0.10',
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

  String _getTaskTitle(String taskId) {
    switch (taskId) {
      case 'survey_1':
        return 'Daily Survey';
      case 'share_1':
        return 'Share & Earn';
      case 'rating_1':
        return 'Rate Us';
      default:
        return 'Task';
    }
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
  final bool isCompleted;
  final bool isLoading;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.duration,
    required this.reward,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isCompleted,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: isCompleted || isLoading ? null : onTap,
      child: ZenCard(
        color: isCompleted
            ? AppTheme.surfaceVariant.withValues(alpha: 0.5)
            : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      icon,
                      color: isCompleted ? Colors.grey : color,
                      size: 24,
                    ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted ? AppTheme.textSecondary : null,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    isCompleted ? 'Completed' : description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (!isCompleted) ...[
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
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space8,
                            vertical: AppTheme.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
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
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: AppTheme.successColor)
            else
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
