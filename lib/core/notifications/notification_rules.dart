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
