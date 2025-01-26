import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PlatformSpecificNotifications {
  static NotificationDetails getPlatformChannelSpecifics() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'attendance_channel',
        'Attendance Notifications',
        channelDescription: 'Notifications for attendance reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
} 