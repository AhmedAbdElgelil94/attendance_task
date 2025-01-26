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
  late final InitializationSettings _initializationSettings;

  final SharedPreferences _prefs;
  static final onNotificationClick = ValueNotifier<String?>(null);

  // Keys for SharedPreferences
  static const String _reminderHourKey = 'reminder_hour';
  static const String _reminderMinuteKey = 'reminder_minute';
  static const String _reminderEnabledKey = 'reminder_enabled';

  NotificationService(this._prefs) {
    _initializationSettings = InitializationSettings(
      android: _androidSettings,
      iOS: _iOSSettings,
    );
    // Set default reminder time if not set
    if (!_prefs.containsKey(_reminderHourKey)) {
      _prefs.setInt(_reminderHourKey, 8); // Default 8 AM
      _prefs.setInt(_reminderMinuteKey, 0);
      _prefs.setBool(_reminderEnabledKey, true);
    }
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Request notification permissions
    if (Platform.isAndroid) {
      // For Android, permissions are handled in the Android Manifest
      // No runtime permission request needed for versions below Android 13
      // For Android 13 and above, permissions are requested through the settings
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // The permissions are declared in the Android Manifest
        // This will show the system settings if needed
        await _notifications.initialize(
          _initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTap,
        );
      }
    } else if (Platform.isIOS) {
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

    // Handle notification when app is in background or terminated
    await _notifications.getNotificationAppLaunchDetails().then((details) {
      if (details != null && details.didNotificationLaunchApp) {
        onNotificationClick.value = details.notificationResponse?.payload;
      }
    });

    await _notifications.initialize(
      _initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
    await BackgroundService.initialize();
  }

  void _onNotificationTap(NotificationResponse details) {
    // Handle notification tap
    print('Notification tapped: ${details.payload}');
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

    await _notifications.zonedSchedule(
      0,
      'Attendance Reminder',
      'Don\'t forget to mark your attendance!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      PlatformSpecificNotifications.getPlatformChannelSpecifics(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'attendance_reminder',
    );
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    await _prefs.setInt(_reminderHourKey, time.hour);
    await _prefs.setInt(_reminderMinuteKey, time.minute);
    await scheduleAttendanceReminder();
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
    } else {
      await cancelReminder();
    }
  }

  Future<bool> isReminderEnabled() async {
    return _prefs.getBool(_reminderEnabledKey) ?? true;
  }

  Future<void> cancelReminder() async {
    await _notifications.cancel(0);
    await BackgroundService.cancelAllTasks();
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  // Handle notification tap in background
  NotificationService.onNotificationClick.value = details.payload;
}
