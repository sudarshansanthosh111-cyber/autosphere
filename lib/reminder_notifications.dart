import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class ReminderNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    timezone_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));
    } catch (_) {}

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static Future<void> scheduleAll(List<Map<String, dynamic>> reminders) async {
    if (!_initialized) return;
    for (final reminder in reminders) {
      await schedule(
        id: reminder['id'] as int,
        title: reminder['title'] as String,
        reminderType:
            reminder['reminder_type'] as String? ?? 'Vehicle reminder',
        dueDate: reminder['due_date'] as String,
      );
    }
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String reminderType,
    required String dueDate,
  }) async {
    if (!_initialized) return;
    final date = DateTime.tryParse(dueDate);
    if (date == null) return;
    final scheduled = timezone.TZDateTime(
      timezone.local,
      date.year,
      date.month,
      date.day,
      9,
    );
    if (!scheduled.isAfter(timezone.TZDateTime.now(timezone.local))) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: '$reminderType is due today.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'vehicle_reminders',
          'Vehicle reminders',
          channelDescription: 'Renewal and maintenance due dates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id: id);
  }
}
