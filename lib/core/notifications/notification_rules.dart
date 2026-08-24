import '../../app/models.dart';

/// Pure rules for local reminders. This file intentionally has no plugin
/// imports, so IDs and copy can be tested on every platform.
enum LumeReminderKind { water, exercise, gratitude, allowance }

/// A small, stable slot number allows a feature to schedule more than one
/// reminder of the same kind on the same local date without using hashCode.
class LumeNotificationId {
  const LumeNotificationId._();

  static int forReminder({
    required LumeReminderKind kind,
    required DateTime localDate,
    int slot = 0,
  }) {
    if (slot < 0 || slot > 9) {
      throw ArgumentError.value(slot, 'slot', 'must be between 0 and 9');
    }
    final date = localDate.toLocal();
    final dateKey = date.year * 10000 + date.month * 100 + date.day;
    // Date (yyyymmdd), kind and slot are deterministic across app restarts.
    return dateKey * 100 + kind.index * 10 + slot;
  }
}

class LumeNotificationCopy {
  const LumeNotificationCopy._();

  static const title = 'Lume';

  static String bodyFor(LumeReminderKind kind) => switch (kind) {
    LumeReminderKind.water => 'Um lembrete para cuidar de você 💧',
    LumeReminderKind.exercise => 'Um lembrete para cuidar do seu corpo',
    LumeReminderKind.gratitude => 'Um momento para guardar algo bom de hoje',
    LumeReminderKind.allowance => 'Você tem um lembrete no Lume',
  };
}

class LumeNotificationSchedule {
  const LumeNotificationSchedule({
    required this.kind,
    required this.localDateTime,
    this.slot = 0,
  });

  final LumeReminderKind kind;
  final DateTime localDateTime;
  final int slot;

  int get id => LumeNotificationId.forReminder(
    kind: kind,
    localDate: localDateTime,
    slot: slot,
  );

  String get title => LumeNotificationCopy.title;

  String get body => LumeNotificationCopy.bodyFor(kind);
}

/// Builds a finite rolling window of one-shot reminders. Native schedulers
/// are intentionally fed concrete local dates so a timezone/DST change does
/// not silently reinterpret a recurring rule.
List<LumeNotificationSchedule> planReminderWindow({
  required DateTime now,
  required ReminderPreferences preferences,
  required int allowanceDayOfMonth,
  int days = 35,
}) {
  final localNow = now.toLocal();
  final schedules = <LumeNotificationSchedule>[];
  for (var offset = 0; offset < days; offset++) {
    final day = DateTime(localNow.year, localNow.month, localNow.day + offset);
    for (var slot = 0; slot < preferences.waterTimes.length; slot++) {
      final time = _parseClock(preferences.waterTimes[slot]);
      if (time == null) continue;
      _addIfFuture(
        schedules,
        LumeReminderKind.water,
        DateTime(day.year, day.month, day.day, time.$1, time.$2),
        slot: slot,
        now: localNow,
      );
    }
    final gratitudeTime = _parseClock(preferences.gratitudeTime);
    if (gratitudeTime != null) {
      _addIfFuture(
        schedules,
        LumeReminderKind.gratitude,
        DateTime(
          day.year,
          day.month,
          day.day,
          gratitudeTime.$1,
          gratitudeTime.$2,
        ),
        now: localNow,
      );
    }
    if (preferences.exerciseWeekdays.contains(day.weekday)) {
      final exerciseTime = _parseClock(preferences.exerciseTime);
      if (exerciseTime != null) {
        _addIfFuture(
          schedules,
          LumeReminderKind.exercise,
          DateTime(
            day.year,
            day.month,
            day.day,
            exerciseTime.$1,
            exerciseTime.$2,
          ),
          now: localNow,
        );
      }
    }
    if (day.day == _lastDay(day.year, day.month, allowanceDayOfMonth)) {
      final allowanceTime = _parseClock(preferences.allowanceTime);
      if (allowanceTime != null) {
        _addIfFuture(
          schedules,
          LumeReminderKind.allowance,
          DateTime(
            day.year,
            day.month,
            day.day,
            allowanceTime.$1,
            allowanceTime.$2,
          ),
          now: localNow,
        );
      }
    }
  }
  return List.unmodifiable(schedules);
}

void _addIfFuture(
  List<LumeNotificationSchedule> target,
  LumeReminderKind kind,
  DateTime localDateTime, {
  required DateTime now,
  int slot = 0,
}) {
  if (localDateTime.isAfter(now)) {
    target.add(
      LumeNotificationSchedule(
        kind: kind,
        localDateTime: localDateTime,
        slot: slot,
      ),
    );
  }
}

(int, int)? _parseClock(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return (hour, minute);
}

int _lastDay(int year, int month, int desired) {
  final next = month == 12 ? DateTime(year + 1, 1) : DateTime(year, month + 1);
  return desired.clamp(1, next.subtract(const Duration(days: 1)).day);
}
