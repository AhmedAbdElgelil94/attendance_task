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
  
  final hour = prefs.getInt('reminder_hour') ?? 8;
  final minute = prefs.getInt('reminder_minute') ?? 0;
  
  // Check if it's time to show the notification
  final now = DateTime.now();
  if (now.hour == hour && now.minute == minute) {
    // Initialize notifications with high priority settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    await notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Show the notification
    await notifications.show(
      0,
      'Attendance Reminder',
      'Don\'t forget to mark your attendance today!',
      PlatformSpecificNotifications.getPlatformChannelSpecifics(),
    );
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
    
    // Register a task that checks every minute
    await Workmanager().registerPeriodicTask(
      'attendanceReminderCheck',
      'checkAndShowReminder',
      frequency: const Duration(minutes: 15), // Minimum allowed frequency
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  static Future<void> scheduleExactNotification() async {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    final prefs = await SharedPreferences.getInstance();
    
    final hour = prefs.getInt('reminder_hour') ?? 8;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    
    // Calculate next occurrence of the specified time
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await notifications.zonedSchedule(
      0,
      'Attendance Reminder',
      'Don\'t forget to mark your attendance today!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      PlatformSpecificNotifications.getPlatformChannelSpecifics(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'attendance_reminder',
    );
  }

  static Future<void> cancelAllTasks() async {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    await Workmanager().cancelAll();
    await notifications.cancelAll();
  }
} 