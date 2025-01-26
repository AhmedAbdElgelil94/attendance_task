import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'platform_specific_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      tz.initializeTimeZones();
      
      switch (task) {
        case 'checkAndShowReminder':
          await _checkAndShowReminder();
          break;
      }
      return true;
    } catch (e) {
      return false;
    }
  });
}

Future<void> _checkAndShowReminder() async {
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  final prefs = await SharedPreferences.getInstance();
  
  // Get the scheduled reminder time
  final hour = prefs.getInt('reminder_hour') ?? 8;
  final minute = prefs.getInt('reminder_minute') ?? 0;
  final isEnabled = prefs.getBool('reminder_enabled') ?? true;
  
  if (!isEnabled) return;

  // Check if it's time to show the notification
  final now = DateTime.now();
  
  // Check if we're within the 15-minute window of the scheduled time
  // This ensures we don't miss notifications due to the 15-minute periodic check
  final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
  final difference = now.difference(scheduledTime).inMinutes.abs();
  
  if (difference <= 15) {
    // Check if we already showed the notification today
    final lastNotificationDate = prefs.getString('last_notification_date');
    final today = DateTime(now.year, now.month, now.day).toString();
    
    if (lastNotificationDate != today) {
      // Show the notification
      await notifications.show(
        0,
        'Attendance Reminder',
        'Time to mark your attendance!',
        PlatformSpecificNotifications.getPlatformChannelSpecifics(),
        payload: 'attendance_reminder',
      );
      
      // Save the notification date to prevent duplicate notifications
      await prefs.setString('last_notification_date', today);
    }
  }
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerPeriodicTask() async {
    // Cancel existing tasks
    await Workmanager().cancelAll();
    
    // Register a task that checks every 15 minutes
    await Workmanager().registerPeriodicTask(
      'attendanceReminderCheck',
      'checkAndShowReminder',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: const Duration(seconds: 10), // Start checking after 10 seconds
    );
  }

  static Future<void> scheduleExactNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour') ?? 8;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    final isEnabled = prefs.getBool('reminder_enabled') ?? true;

    if (!isEnabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    await notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Schedule the notification
    await notifications.zonedSchedule(
      1, // Different ID from regular notifications
      'Attendance Reminder',
      'Time to mark your attendance!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      PlatformSpecificNotifications.getPlatformChannelSpecifics(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'attendance_reminder',
    );
  }

  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}