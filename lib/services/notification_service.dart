import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int dailySummaryId = 1001;

  bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'daily_achievement_channel',
    'Daily Achievements',
    channelDescription:
        'Daily task progress and encouraging reminders.',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (error) {
      debugPrint('Could not set local timezone: $error');
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notifications.initialize(settings: settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> scheduleDailySummary({
    required String body,
    int hour = 17,
    int minute = 45,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.cancel(id: dailySummaryId);

    await _notifications.zonedSchedule(
      id: dailySummaryId,
      title: 'Your My Todo List Daily Summary',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showTestNotification() async {
    await initialize();

    await _notifications.show(
      id: 1002,
      title: 'My Todo List is ready!',
      body: 'Every small step counts. Keep building your progress!',
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
      ),
    );
  }

  Future<void> cancelDailySummary() async {
    await initialize();
    await _notifications.cancel(id: dailySummaryId);
  }
}
