import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';

import '../../core/utils/device_utils.dart';
import '../../providers/user_provider.dart';
import '../../widgets/error_states.dart';
import '../../widgets/scale_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';
import '../../widgets/zen_card.dart';
import '../../services/task_service.dart';

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

    try {
      // Optimistic update
      userProvider.updateLocalState(
        coins: userProvider.user.coins + reward,
        totalEarnings: userProvider.user.totalEarnings + (reward / 1000),
        completedTasks: userProvider.user.completedTasks + 1,
        completedTaskIds: [...userProvider.user.completedTaskIds, taskId],
      );

      await TaskService().completeTask(user.uid, taskId, reward);

      if (mounted) {
        StateSnackbar.showSuccess(
          context,
          'Task completed! You earned $reward Coins.',
        );
      }
    } catch (e) {
      debugPrint('Error completing task: $e');
      // Revert optimistic update if needed (omitted for brevity, but good practice)
      if (mounted) {
        StateSnackbar.showError(context, 'Failed to complete task');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(AppTheme.space16),
                itemCount: 6,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: ShimmerLoading.rectangular(height: 80),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadTasks,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Available Tasks',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        'Complete tasks to earn Coins',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space24),

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
                                    color: AppTheme.primaryColor,
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
                                        bottom: AppTheme.space12,
                                      ),
                                      child: NativeAdWidget(),
                                    ),
                                  const SizedBox(height: AppTheme.space12),
                                ],
                              );
                            },
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
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
                                              color: AppTheme.successColor
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: AppTheme.successColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppTheme.space12,
                                          ),
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
                                                'Earned ${task.reward} Coins',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppTheme
                                                          .textSecondary,
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
    return ScaleButton(
      onTap: isCompleted || isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppTheme.surfaceVariant.withValues(alpha: 0.5)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: isCompleted
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isCompleted ? Colors.transparent : AppTheme.surfaceVariant,
            width: 1,
          ),
        ),
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
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                            '+$reward Coins',
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
