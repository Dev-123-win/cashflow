import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: 'Earnings Added',
      description: 'You earned ₹0.10 from completing a task',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      icon: '💰',
      read: false,
    ),
    NotificationItem(
      title: 'Referral Bonus',
      description: 'Your friend Rajesh signed up. You earned ₹0.50!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: '👥',
      read: false,
    ),
    NotificationItem(
      title: 'Withdrawal Processed',
      description: 'Your ₹50 withdrawal has been completed',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      icon: '✅',
      read: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to notification settings
            },
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: notification.read
              ? Colors.transparent
              : AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                notification.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: notification.read
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

class NotificationItem {
  final String title;
  final String description;
  final DateTime timestamp;
  final String icon;
  final bool read;

  NotificationItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.read,
  });
}
