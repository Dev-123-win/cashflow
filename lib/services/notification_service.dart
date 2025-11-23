import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // Request user permission for notifications
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User declined notification permission');
      }

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Handle background message
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageOpenedApp(message);
      });
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
      // Show a snackbar or dialog with the notification
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(message.notification!.body ?? ''),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Handle background messages (static)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Handling a background message: ${message.messageId}');
  }

  // Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    // Navigate to appropriate screen based on notification type
  }

  // Send daily reminder notification
  Future<void> sendDailyReminder(String userId) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'daily_reminder',
        'title': 'Time to Earn! 💰',
        'body': 'Complete games and tasks to earn money today',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': {'screen': 'games', 'action': 'play_game'},
      });
    } catch (e) {
      debugPrint('Error sending daily reminder: $e');
    }
  }

  // Send achievement notification
  Future<void> sendAchievementNotification(
    String userId,
    String achievementName,
    String icon,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'achievement',
        'title': 'Achievement Unlocked! 🏆',
        'body': 'You earned: $achievementName',
        'icon': icon,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': {
          'screen': 'profile',
          'action': 'view_achievements',
          'achievementName': achievementName,
        },
      });
    } catch (e) {
      debugPrint('Error sending achievement notification: $e');
    }
  }

  // Send withdrawal status notification
  Future<void> sendWithdrawalNotification(
    String userId,
    String status, // 'pending', 'approved', 'rejected'
    double amount,
  ) async {
    try {
      String title = 'Withdrawal $status';
      String body = '';
      String icon = '';

      switch (status) {
        case 'pending':
          title = 'Withdrawal Submitted ⏳';
          body = 'Your ₹$amount withdrawal request has been submitted';
          icon = '⏳';
          break;
        case 'approved':
          title = 'Withdrawal Approved ✅';
          body = '₹$amount will be transferred to your account within 24 hours';
          icon = '✅';
          break;
        case 'rejected':
          title = 'Withdrawal Rejected ❌';
          body = '₹$amount withdrawal was rejected. Please try again.';
          icon = '❌';
          break;
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'withdrawal_status',
        'status': status,
        'title': title,
        'body': body,
        'icon': icon,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': {'screen': 'withdrawal', 'action': 'view_status'},
      });
    } catch (e) {
      debugPrint('Error sending withdrawal notification: $e');
    }
  }

  // Send streak milestone notification
  Future<void> sendStreakMilestoneNotification(
    String userId,
    int streakDays,
  ) async {
    try {
      String message = '';
      String emoji = '🔥';

      if (streakDays == 7) {
        message = 'You\'ve got a 7-day earning streak! Keep it up!';
      } else if (streakDays == 14) {
        message = 'Amazing! 14-day streak! You\'re on fire!';
      } else if (streakDays == 30) {
        message = 'Outstanding! 30-day streak! You\'re a legend!';
      } else if (streakDays % 7 == 0) {
        message = 'Great work! $streakDays-day streak! Don\'t break it now!';
      }

      if (message.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'streak_milestone',
          'title': 'Streak Milestone! 🔥',
          'body': message,
          'emoji': emoji,
          'streakDays': streakDays,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'data': {'screen': 'home', 'action': 'view_streak'},
        });
      }
    } catch (e) {
      debugPrint('Error sending streak milestone notification: $e');
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Update FCM token in Firestore
  Future<void> updateFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
}

// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final String
  type; // daily_reminder, achievement, withdrawal_status, streak_milestone
  final String title;
  final String body;
  final String? icon;
  final bool read;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.icon,
    required this.read,
    required this.timestamp,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'notification',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      icon: data['icon'],
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'],
    );
  }
}

// Global navigator key for showing snackbars
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
