import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import 'notification_storage_service.dart';
import 'package:uuid/uuid.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final NotificationStorageService _storageService =
      NotificationStorageService();
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;

  // Stream controller for navigation events
  final StreamController<String> _navigationStreamController =
      StreamController<String>.broadcast();

  Stream<String> get navigationStream => _navigationStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false, // Request later
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    _isInitialized = true;
  }

  /// Request notification permissions (required for Android 13+)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted = await androidImplementation
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      debugPrint('Notification tapped: $payload');
      _navigationStreamController.add(payload);
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String type = 'system',
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );

    // Save to local storage
    final notification = NotificationModel(
      id: _uuid.v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );
    await _storageService.saveNotification(notification);
  }

  Future<void> scheduleDailyReminder() async {
    // Schedule a notification if the user hasn't opened the app in 24 hours
    await _notificationsPlugin.cancel(999); // Cancel existing reminder

    await _notificationsPlugin.zonedSchedule(
      999,
      'We miss you! 🥺',
      'Come back and earn more rewards today!',
      _nextInstanceOfTime(19, 0), // 7:00 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Reminders to open the app',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'home',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule a notification after a specific duration
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(delay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription: 'Notifications scheduled for specific times',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule a streak reminder (e.g., 23 hours from now)
  Future<void> scheduleStreakReminder() async {
    // ID 2000 for streak
    await _notificationsPlugin.cancel(2000);

    await scheduleNotification(
      id: 2000,
      title: '🔥 Streak Warning!',
      body: 'Don\'t lose your daily streak! Check in now to keep it.',
      delay: const Duration(hours: 23),
      payload: 'home',
    );
  }

  /// Schedule random engagement notifications
  Future<void> scheduleEngagementNotifications() async {
    // Cancel existing engagement notifications (IDs 3000-3005)
    for (int i = 3000; i < 3005; i++) {
      await _notificationsPlugin.cancel(i);
    }

    final messages = [
      ('💰 Quick Cash?', 'Complete a 1-min task to earn ₹0.50!'),
      ('🧠 Brain Power', 'Test your memory and earn rewards!'),
      ('🎁 Free Bonus', 'Watch a short ad to claim your bonus.'),
    ];

    // Schedule 3 notifications over the next 3 days
    for (int i = 0; i < messages.length; i++) {
      final delay = Duration(hours: 12 + (i * 24)); // 12h, 36h, 60h
      await scheduleNotification(
        id: 3000 + i,
        title: messages[i].$1,
        body: messages[i].$2,
        delay: delay,
        payload: 'engagement',
      );
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  void dispose() {
    _navigationStreamController.close();
  }
}
