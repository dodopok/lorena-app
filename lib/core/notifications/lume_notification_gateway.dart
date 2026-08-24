import 'package:lume/core/notifications/local_notifications_client.dart';
import 'package:lume/core/notifications/notification_rules.dart';

/// Testable facade for local reminders.
///
/// Permission is never requested by [initialize]. Call [requestPermission]
/// only after the user has enabled a reminder. Push remoto/APNs remains fora
/// do MVP; this gateway schedules and cancels on-device notifications only.
class LumeNotificationGateway {
  LumeNotificationGateway({LumeLocalNotificationsClient? client})
    : _client = client ?? FlutterLocalNotificationsClient();

  final LumeLocalNotificationsClient _client;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _client.initialize();
    _initialized = true;
  }

  /// Requests iOS permission on demand. Initialization itself is silent.
  Future<bool> requestPermission() => _client.requestPermission();

  /// Reusing the same schedule replaces the native notification with the same
  /// deterministic ID instead of creating a duplicate.
  Future<void> schedule(LumeNotificationSchedule schedule) async {
    await initialize();
    await _client.schedule(
      id: schedule.id,
      title: schedule.title,
      body: schedule.body,
      localDateTime: schedule.localDateTime,
    );
  }

  Future<void> cancel({
    required LumeReminderKind kind,
    required DateTime localDate,
    int slot = 0,
  }) => _client.cancel(
    LumeNotificationId.forReminder(
      kind: kind,
      localDate: localDate,
      slot: slot,
    ),
  );
}
