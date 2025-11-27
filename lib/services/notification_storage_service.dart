import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationStorageService {
  static const String _storageKey = 'user_notifications';

  Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNotification(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();

    // Add to beginning of list
    notifications.insert(0, notification);

    // Limit to last 50 notifications
    if (notifications.length > 50) {
      notifications.removeLast();
    }

    await prefs.setString(
      _storageKey,
      json.encode(notifications.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();

    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await prefs.setString(
        _storageKey,
        json.encode(notifications.map((e) => e.toJson()).toList()),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();

    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();

    await prefs.setString(
      _storageKey,
      json.encode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }
}
