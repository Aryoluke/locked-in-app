import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Time-of-day (hour/minute) used by [NotificationService.scheduleDailyCheckIn].
class Time {
  const Time({required this.hour, required this.minute});
  final int hour;
  final int minute;
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    // Resolve the device's real timezone so daily reminders fire at local time.
    // Falls back to UTC if the platform can't report one.
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool ongoing = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'locked_in_channel',
      'Locked In notifications',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: ongoing,
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> notifyWorkoutReminder(String workoutName) =>
      _show(
        id: 101,
        title: 'LOCKED IN',
        body: 'Time for $workoutName. Get after it.',
      );

  Future<void> notifyHabitReminder(String habitName) =>
      _show(
        id: 102,
        title: 'Habit Check',
        body: 'Don\'t forget: $habitName. Keep the streak alive.',
      );

  Future<void> notifyWaterReminder() =>
      _show(
        id: 103,
        title: 'Hydrate',
        body: 'You\'re lagging on water today. Take a sip.',
      );

  Future<void> notifyStudyReminder(String subject) =>
      _show(
        id: 104,
        title: 'Study Time',
        body: '$subject is calling. 25 minutes of focus.',
      );

  Future<void> notifyStreakEndangered(int streak) =>
      _show(
        id: 105,
        title: 'Streak Alert',
        body: 'Your $streak-day streak is at risk. Log in and lock in!',
      );

  Future<void> notifyStreakMilestone(int streak) =>
      _show(
        id: 106,
        title: '🔥 ${streak} DAY STREAK',
        body: 'You are LOCKED IN. Legendary consistency.',
      );

  Future<void> scheduleDailyCheckIn(Time time) async {
    tzdata.initializeTimeZones();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'locked_in_channel',
      'Locked In notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
    await _plugin.zonedSchedule(
      110,
      'Daily Lock-In',
      'Log your day and keep the chain alive.',
      scheduled,
      details,
      // Inexact is permission-free and more than accurate enough for a daily
      // nudge; exact alarms would need SCHEDULE_EXACT_ALARM on Android 12+.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyCheckIn() => _plugin.cancel(110);

  /// Applies the stored daily-reminder preference.
  ///
  /// Reads SharedPreferences on every app start so a reboot or reinstall of the
  /// app does not silently drop the schedule. Defaults remain off.
  Future<void> refreshScheduledReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_reminder_enabled') ?? false;
    if (!enabled) {
      await _plugin.cancel(110);
      return;
    }
    final raw = prefs.getString('daily_reminder_time') ?? '19:00';
    final parts = raw.split(':');
    final hour = int.tryParse(parts[0]) ?? 19;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    await scheduleDailyCheckIn(Time(hour: hour, minute: minute));
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
