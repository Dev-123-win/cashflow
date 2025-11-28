import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../services/task_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/native_ad_widget.dart';
import '../../providers/task_provider.dart';
import '../../widgets/shimmer_loading.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<Task> _tasks = [];
  String? _deviceId;
  final Set<String> _loadingTaskIds = {};
  DateTime? _pausedTime;
  String? _pendingTaskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTasks();
    _initializeDeviceId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkTaskCompletion();
    }
  }

  Future<void> _checkTaskCompletion() async {
    if (_pendingTaskId == null || _pausedTime == null) return;

    final timeSpent = DateTime.now().difference(_pausedTime!);
    final taskId = _pendingTaskId!;
    _pendingTaskId = null;
    _pausedTime = null;

    // Require at least 5 seconds spent outside the app
    if (timeSpent.inSeconds >= 5) {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      await _completeTask(taskId, task.title, task.reward);
    } else {
      if (mounted) {
        StateSnackbar.showWarning(
          context,
          'You didn\'t complete the task! Please try again.',
        );
        setState(() {
          _loadingTaskIds.remove(taskId);
        });
      }
    }
  }

  Future<void> _initializeDeviceId() async {
    try {
      _deviceId = await DeviceUtils.getDeviceId();
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final tasks = await TaskService().getTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _launchTaskAction(String taskId, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      _pendingTaskId = taskId; // Mark task as pending verification
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
      setState(() {
        _loadingTaskIds.remove(taskId);
      });
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

    // Show BottomSheet
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to earn',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildStep(context, 1, 'Click "Start Task" to open the link.'),
            _buildStep(
              context,
              2,
              'Complete the action (e.g., install app, sign up).',
            ),
            _buildStep(context, 3, 'Return to EarnQuest to get your reward.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startTask(taskId, actionUrl);
                },
                child: const Text('Start Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _startTask(String taskId, String actionUrl) async {
    setState(() {
      _loadingTaskIds.add(taskId);
    });

    // Launch external action - verification happens in didChangeAppLifecycleState
    await _launchTaskAction(taskId, actionUrl);
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
          // Manually update local state to avoid a read
          userProvider.updateLocalState(
            availableBalance: userProvider.user.availableBalance + reward,
            totalEarnings: userProvider.user.totalEarnings + reward,
            completedTasks: userProvider.user.completedTasks + 1,
            completedTaskIds: [...userProvider.user.completedTaskIds, taskId],
          );

          // Check for Ad Break
          await AdService().checkAdBreak();
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
                    Consumer2<UserProvider, TaskProvider>(
                      builder: (context, userProvider, taskProvider, _) {
                        final completedToday = userProvider.user.completedTasks;
                        final totalTasks = _tasks.length;
                        final earned = taskProvider.dailyEarnings;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$completedToday tasks completed',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '₹${earned.toStringAsFixed(2)} earned',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppTheme.successColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
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
                                backgroundColor: AppTheme.surfaceVariant,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                                minHeight: 6,
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
                  if (_isLoading) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppTheme.space12),
                      itemBuilder: (context, index) =>
                          const ShimmerLoading.rectangular(
                            height: 80,
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(AppTheme.radiusM),
                              ),
                            ),
                          ),
                    );
                  }

                  if (_tasks.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Tasks',
                      message:
                          'No tasks available right now. Check back later!',
                      icon: Icons.assignment_turned_in_outlined,
                    );
                  }

                  final availableTasks = _tasks.where((task) {
                    return !userProvider.user.completedTaskIds.contains(
                      task.id,
                    );
                  }).toList();

                  if (availableTasks.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'All Done!',
                      message: 'All tasks completed! Great job! 🎉',
                      icon: Icons.check_circle_outline,
                    );
                  }

                  return Column(
                    children: [
                      ...availableTasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.space12,
                              ),
                              child: _TaskCard(
                                title: task.title,
                                description: task.description,
                                duration: task.duration,
                                reward: task.reward,
                                iconUrl: task.icon,
                                color: Colors.blue, // Default color
                                isCompleted: false,
                                isLoading: _loadingTaskIds.contains(task.id),
                                onTap: () => _handleTaskTap(
                                  task.id,
                                  task.title,
                                  task.reward,
                                  task.actionUrl,
                                ),
                              ),
                            ),
                            // Insert Native Ad after every 3rd task
                            if ((index + 1) % 3 == 0)
                              const Padding(
                                padding: EdgeInsets.only(
                                  bottom: AppTheme.space12,
                                ),
                                child: NativeAdWidget(), // Placeholder for now
                              ),
                          ],
                        );
                      }),
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
                  final completedIds = userProvider.user.completedTaskIds;
                  final completedTasks = _tasks
                      .where((task) => completedIds.contains(task.id))
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
  final String? iconUrl;
  final Color color;
  final VoidCallback onTap;
  final bool isCompleted;
  final bool isLoading;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.duration,
    required this.reward,
    this.iconUrl,
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
                  : (iconUrl != null && iconUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: iconUrl!,
                            width: 24,
                            height: 24,
                            memCacheWidth: 72, // 3x for high density screens
                            memCacheHeight: 72,
                            placeholder: (context, url) =>
                                const Icon(Icons.image),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )
                        : Icon(
                            Icons.assignment, // Default icon
                            color: isCompleted ? Colors.grey : color,
                            size: 24,
                          )),
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
