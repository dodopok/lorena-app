import 'date_rules.dart';

enum WaterSource { manual, quickAction, widget }

class WaterLog {
  WaterLog({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.occurredAt,
    required this.localDate,
    required this.source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? occurredAt,
       updatedAt = updatedAt ?? occurredAt {
    if (id.trim().isEmpty || userId.trim().isEmpty)
      throw ArgumentError('id e userId são obrigatórios');
    if (amountMl <= 0)
      throw ArgumentError.value(amountMl, 'amountMl', 'deve ser positivo');
    DateRules.parseDate(localDate);
  }

  final String id;
  final String userId;
  final int amountMl;
  final DateTime occurredAt;
  final String localDate;
  final WaterSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  WaterLog copyWith({
    int? amountMl,
    DateTime? occurredAt,
    String? localDate,
    WaterSource? source,
    DateTime? updatedAt,
  }) => WaterLog(
    id: id,
    userId: userId,
    amountMl: amountMl ?? this.amountMl,
    occurredAt: occurredAt ?? this.occurredAt,
    localDate: localDate ?? this.localDate,
    source: source ?? this.source,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

int totalWaterForDate(Iterable<WaterLog> logs, String localDate) => logs
    .where((log) => log.localDate == localDate)
    .fold(0, (total, log) => total + log.amountMl);

double waterProgress(int totalMl, int goalMl) {
  if (goalMl <= 0)
    throw ArgumentError.value(goalMl, 'goalMl', 'deve ser positivo');
  return totalMl / goalMl;
}
