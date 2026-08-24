// timezone is intentionally consumed through flutter_local_notifications here.
// pubspec.yaml is owned by the application integration task and is unchanged.
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Small adapter around the native plugin. The application depends on this
/// interface, which keeps gateway tests independent from method channels.
abstract interface class LumeLocalNotificationsClient {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime localDateTime,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();
}

/// Production adapter for iOS local notifications.
///
/// The MVP deliberately uses local notifications only. Remote push/APNs,
/// device tokens, FCM and server delivery are outside this gateway and outside
/// the MVP.
class FlutterLocalNotificationsClient implements LumeLocalNotificationsClient {
  FlutterLocalNotificationsClient({
    FlutterLocalNotificationsPlugin? plugin,
    this.timeZoneId = 'America/Sao_Paulo',
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final String timeZoneId;
  bool _initialized = false;
  bool _timeZoneInitialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initializeTimeZone();
    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  void _initializeTimeZone() {
    if (_timeZoneInitialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timeZoneId));
    _timeZoneInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          sound: true,
          badge: true,
        ) ??
        false;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime localDateTime,
  }) async {
    await initialize();
    final local = localDateTime.toLocal();
    final scheduled = tz.TZDateTime(
      tz.local,
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
