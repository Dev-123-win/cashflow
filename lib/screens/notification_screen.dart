import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/colors.dart';
import '../core/constants/dimensions.dart';
import '../models/notification_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/app_assets.dart';
import '../services/notification_storage_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationStorageService _storageService =
      NotificationStorageService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _storageService.getNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    await _storageService.markAllAsRead();
  }

  Future<void> _clearAll() async {
    await _storageService.clearAll();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All'),
                    content: const Text(
                      'Are you sure you want to delete all notifications?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAll();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppAssets.emptyNotifications,
                    height: 200,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.space16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: notification.isRead
              ? Colors.transparent
              : primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getIconColor(
                notification.type,
                isDark,
              ).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(notification.type),
              color: _getIconColor(notification.type, isDark),
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(notification.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'earning':
        return Icons.monetization_on;
      case 'reminder':
        return Icons.alarm;
      case 'system':
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type, bool isDark) {
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;

    switch (type) {
      case 'earning':
        return AppColors.success;
      case 'reminder':
        return AppColors.warning;
      case 'system':
      default:
        return primaryColor;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
