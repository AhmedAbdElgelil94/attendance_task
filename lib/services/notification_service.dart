import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_specific_notifications.dart';
import 'background_service.dart';
import 'dart:io' show Platform;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialization settings for Android
  final AndroidInitializationSettings _androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Initialization settings for iOS
  final DarwinInitializationSettings _iOSSettings =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  // Combined initialization settings
  final InitializationSettings _initializationSettings;

  final SharedPreferences _prefs;
  static final onNotificationClick = ValueNotifier<String?>(null);

  // Keys for SharedPreferences
  static const String _reminderHourKey = 'reminder_hour';
  static const String _reminderMinuteKey = 'reminder_minute';
  static const String _reminderEnabledKey = 'reminder_enabled';

  NotificationService(this._prefs) : _initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    ),
  );

  Future<void> initialize() async {
    print('Initializing NotificationService');
    tz.initializeTimeZones();

    // Request notification permissions
    if (Platform.isAndroid) {
      print('Setting up Android notifications');
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // For Android 13 and above, the permissions are handled through the system settings
        final granted = await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
        print('Android notifications permission granted: $granted');
      }
    } else if (Platform.isIOS) {
      print('Requesting iOS notification permissions');
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }

    // Initialize notifications plugin
    await _notifications.initialize(
      _initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    print('Notifications initialized');

    // Test notification immediately
    await showForegroundNotification(
      title: 'Test Notification',
      body: 'Testing if notifications are working',
    );
    print('Test notification sent');

    // Initialize background service
    await BackgroundService.initialize();
    print('Background service initialized');

    // Schedule the daily reminder
    await scheduleAttendanceReminder();
    print('Daily reminder scheduled');
  }

  void _onNotificationTap(NotificationResponse details) {
    onNotificationClick.value = details.payload;
    print('Notification tapped: ${details.payload}');
  }

  Future<void> showForegroundNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    print('Showing foreground notification: $title - $body');
    
    final androidDetails = AndroidNotificationDetails(
      'attendance_reminder',
      'Attendance Reminders',
      channelDescription: 'Daily reminders to mark attendance',
      importance: Importance.max,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      print('Notification shown successfully');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> scheduleAttendanceReminder() async {
    if (!await isReminderEnabled()) return;

    final time = await getReminderTime();
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has passed for today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Cancel any existing notifications
    await _notifications.cancelAll();

    // Schedule the new notification with high priority
    final androidDetails = AndroidNotificationDetails(
      'attendance_reminder',
      'Attendance Reminders',
      channelDescription: 'Daily reminders to mark attendance',
      importance: Importance.max,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Schedule the notification
    await _notifications.zonedSchedule(
      0,
      'Attendance Reminder',
      'Time to mark your attendance!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'attendance_reminder',
    );

    // Also update the background service schedule
    await BackgroundService.registerPeriodicTask();
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    await _prefs.setInt(_reminderHourKey, time.hour);
    await _prefs.setInt(_reminderMinuteKey, time.minute);
    
    // Cancel existing notifications and reschedule
    await cancelReminder();
    await scheduleAttendanceReminder();
    
    // Update background service
    await BackgroundService.registerPeriodicTask();
  }

  Future<TimeOfDay> getReminderTime() async {
    final hour = _prefs.getInt(_reminderHourKey) ?? 8;
    final minute = _prefs.getInt(_reminderMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _prefs.setBool(_reminderEnabledKey, enabled);
    if (enabled) {
      await scheduleAttendanceReminder();
      await BackgroundService.registerPeriodicTask();
    } else {
      await cancelReminder();
    }
  }

  Future<bool> isReminderEnabled() async {
    return _prefs.getBool(_reminderEnabledKey) ?? true;
  }

  Future<void> cancelReminder() async {
    await _notifications.cancelAll();
    await BackgroundService.cancelAllTasks();
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  // Handle notification tap in background
  NotificationService.onNotificationClick.value = details.payload;
}
