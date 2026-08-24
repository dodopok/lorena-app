import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/notifications/notification_rules.dart';

void main() {
  group('LumeNotificationId', () {
    final date = DateTime(2026, 8, 24, 9, 30);

    test('is stable for the same kind, local date and slot', () {
      expect(
        LumeNotificationId.forReminder(
          kind: LumeReminderKind.water,
          localDate: date,
          slot: 2,
        ),
        LumeNotificationId.forReminder(
          kind: LumeReminderKind.water,
          localDate: date,
          slot: 2,
        ),
      );
    });

    test('separates kinds and slots on the same date', () {
      final water = LumeNotificationId.forReminder(
        kind: LumeReminderKind.water,
        localDate: date,
      );
      final exercise = LumeNotificationId.forReminder(
        kind: LumeReminderKind.exercise,
        localDate: date,
      );
      final secondWater = LumeNotificationId.forReminder(
        kind: LumeReminderKind.water,
        localDate: date,
        slot: 1,
      );
      expect({water, exercise, secondWater}, hasLength(3));
    });

    test('rejects unsupported slots', () {
      expect(
        () => LumeNotificationId.forReminder(
          kind: LumeReminderKind.water,
          localDate: date,
          slot: 10,
        ),
        throwsArgumentError,
      );
    });
  });

  test('notification copy is generic and does not include personal values', () {
    expect(
      LumeNotificationCopy.bodyFor(LumeReminderKind.water),
      contains('cuidar'),
    );
    expect(
      LumeNotificationCopy.bodyFor(LumeReminderKind.gratitude),
      isNot(contains('gratidão')),
    );
    expect(
      LumeNotificationCopy.bodyFor(LumeReminderKind.allowance),
      'Você tem um lembrete no Lume',
    );
  });

  test('schedule exposes one deterministic ID and generic copy', () {
    final schedule = LumeNotificationSchedule(
      kind: LumeReminderKind.exercise,
      localDateTime: DateTime(2026, 8, 24, 18),
    );
    expect(schedule.id, greaterThan(0));
    expect(schedule.title, 'Lume');
    expect(schedule.body, isNot(contains('18')));
  });
}
