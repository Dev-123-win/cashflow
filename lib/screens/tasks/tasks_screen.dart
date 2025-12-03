import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../models/task_model.dart';

import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';
import '../../widgets/scale_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';
import '../../widgets/zen_card.dart';
import '../../services/task_service.dart';
import '../../services/cloudflare_workers_service.dart';

import '../../widgets/native_ad_widget.dart';
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
    int reward,
    String actionUrl,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user.completedTaskIds.contains(taskId)) {
      return; // Already completed
    }

    if (_loadingTaskIds.contains(taskId)) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    // Show BottomSheet
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to earn', style: theme.textTheme.headlineSmall),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
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

  Future<void> _completeTask(String taskId, String title, int reward) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      StateSnackbar.showError(context, 'User not logged in');
      return;
    }

    if (_deviceId == null) {
      StateSnackbar.showWarning(context, 'Getting device info...');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactionId =
        'task_${DateTime.now().millisecondsSinceEpoch}_$taskId';

    try {
      // 1. Optimistic Update with transaction tracking
      userProvider.addOptimisticCoins(reward, transactionId, 'task');

      // 2. Call Backend API (routes through Cloudflare Worker)
      final cloudflareService = CloudflareWorkersService();
      final result = await cloudflareService
          .recordTaskEarning(
            userId: user.uid,
            taskId: taskId,
            deviceId: _deviceId!,
            requestId: transactionId,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Request timed out'),
          );

      // 3. Confirm with backend balance
      if (result['success'] == true) {
        final newBalance = result['newBalance'];
        if (newBalance != null) {
          userProvider.confirmOptimisticCoins(transactionId, newBalance);
        }

        // Update completed task IDs in local state
        userProvider.updateLocalState(
          completedTaskIds: [...userProvider.user.completedTaskIds, taskId],
          completedTasks: userProvider.user.completedTasks + 1,
        );
      }

      if (mounted) {
        StateSnackbar.showSuccess(
          context,
          'Task completed! You earned $reward Coins.',
        );
      }
    } catch (e) {
      debugPrint('Error completing task: $e');
      // Rollback optimistic update on error
      userProvider.rollbackOptimisticCoins(transactionId);
      if (mounted) {
        StateSnackbar.showError(context, 'Failed to complete task');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.space16),
                itemCount: 6,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: ShimmerLoading.rectangular(height: 80),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadTasks,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Available Tasks',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        'Complete tasks to earn Coins',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space24),

                      // Task List
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          final completedIds =
                              userProvider.user.completedTaskIds;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              final isCompleted = completedIds.contains(
                                task.id,
                              );
                              final isLoading = _loadingTaskIds.contains(
                                task.id,
                              );

                              return Column(
                                children: [
                                  _TaskCard(
                                    title: task.title,
                                    description: task.description,
                                    duration: '2 min', // Placeholder
                                    reward: task.reward,
                                    iconUrl: task.icon,
                                    color: primaryColor,
                                    isCompleted: isCompleted,
                                    isLoading: isLoading,
                                    onTap: () => _handleTaskTap(
                                      task.id,
                                      task.title,
                                      task.reward,
                                      task.actionUrl,
                                    ),
                                  ),
                                  // Insert Native Ad after every 3rd task
                                  if ((index + 1) % 3 == 0)
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        bottom: AppDimensions.space12,
                                      ),
                                      child: NativeAdWidget(),
                                    ),
                                  const SizedBox(height: AppDimensions.space12),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: AppDimensions.space32),

                      // Completed Today
                      Text(
                        'Completed Today',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          final completedIds =
                              userProvider.user.completedTaskIds;
                          final completedTasks = _tasks
                              .where((task) => completedIds.contains(task.id))
                              .toList();

                          if (completedTasks.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    AppAssets.emptyTasks,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No completed tasks yet',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                    ),
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
                                      bottom: AppDimensions.space12,
                                    ),
                                    child: ZenCard(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(
                                              AppDimensions.space8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: AppColors.success,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppDimensions.space12,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task.title,
                                                style:
                                                    theme.textTheme.titleMedium,
                                              ),
                                              Text(
                                                'Earned ${task.reward} Coins',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: textSecondary,
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
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String duration;
  final int reward;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ScaleButton(
      onTap: isCompleted || isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space12),
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: isCompleted
              ? surfaceVariant.withValues(alpha: 0.5)
              : surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: isCompleted
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isCompleted ? Colors.transparent : surfaceVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                            memCacheWidth: 72,
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
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted ? textSecondary : null,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    isCompleted ? 'Completed' : description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(height: AppDimensions.space8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: textSecondary),
                        const SizedBox(width: AppDimensions.space4),
                        Text(
                          duration,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space8,
                            vertical: AppDimensions.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            '+$reward Coins',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
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
              const Icon(Icons.check_circle, color: AppColors.success)
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary),
          ],
        ),
      ),
    );
  }
}
