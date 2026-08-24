import 'date_rules.dart';

enum TransactionType { allowance, income, expense, adjustment }

enum TransactionSource { manual, allowanceGeneration }

enum AdjustmentDirection { positive, negative }

enum AllowanceRolloverMode { none, positiveOnly }

enum PeriodStatus { open, closed }

class Money {
  const Money(this.amountMinor, {this.currency = 'BRL'})
    : assert(amountMinor >= 0);
  final int amountMinor;
  final String currency;
}

class Transaction {
  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    required this.localDate,
    required this.period,
    required this.categoryId,
    required this.description,
    this.note,
    this.currency = 'BRL',
    this.source = TransactionSource.manual,
    this.adjustmentDirection,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : createdAt = createdAt ?? occurredAt,
       updatedAt = updatedAt ?? occurredAt {
    if (id.trim().isEmpty || userId.trim().isEmpty)
      throw ArgumentError('id e userId são obrigatórios');
    if (amountMinor <= 0)
      throw ArgumentError.value(
        amountMinor,
        'amountMinor',
        'deve ser positivo',
      );
    if (currency != 'BRL')
      throw ArgumentError.value(currency, 'currency', 'a moeda do MVP é BRL');
    DateRules.parseDate(localDate);
    if (DateRules.periodOf(localDate) != period)
      throw ArgumentError('localDate e period não correspondem');
    if (description.trim().isEmpty)
      throw ArgumentError('description é obrigatório');
    if (type == TransactionType.adjustment && adjustmentDirection == null) {
      throw ArgumentError('adjustmentDirection é obrigatório para ajuste');
    }
    if (type != TransactionType.adjustment && adjustmentDirection != null) {
      throw ArgumentError('adjustmentDirection só pode ser usado em ajuste');
    }
    if (type == TransactionType.allowance &&
        source != TransactionSource.allowanceGeneration) {
      throw ArgumentError('mesada só pode ser gerada pela regra de mesada');
    }
  }

  final String id;
  final String userId;
  final TransactionType type;
  final int amountMinor;
  final String currency;
  final DateTime occurredAt;
  final String localDate;
  final String period;
  final String categoryId;
  final String description;
  final String? note;
  final TransactionSource source;
  final AdjustmentDirection? adjustmentDirection;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  int get signedAmountMinor {
    switch (type) {
      case TransactionType.allowance:
      case TransactionType.income:
        return amountMinor;
      case TransactionType.expense:
        return -amountMinor;
      case TransactionType.adjustment:
        return adjustmentDirection == AdjustmentDirection.positive
            ? amountMinor
            : -amountMinor;
    }
  }
}

class AllowancePeriod {
  AllowancePeriod({
    required this.userId,
    required this.period,
    required this.allowanceAmountMinor,
    required this.rolloverMinor,
    this.adjustmentMinor = 0,
    this.currency = 'BRL',
    String? startsOn,
    String? endsOn,
    this.status = PeriodStatus.open,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : startsOn = startsOn ?? DateRules.firstDayOfMonth(period),
       endsOn = endsOn ?? DateRules.lastDayOfMonth(period),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toUtc() {
    if (userId.trim().isEmpty) throw ArgumentError('userId é obrigatório');
    DateRules.parsePeriod(period);
    DateRules.parseDate(this.startsOn);
    DateRules.parseDate(this.endsOn);
    if (allowanceAmountMinor < 0 || rolloverMinor < 0)
      throw ArgumentError('valores da mesada não podem ser negativos');
    if (currency != 'BRL')
      throw ArgumentError.value(currency, 'currency', 'a moeda do MVP é BRL');
  }

  final String userId;
  final String period;
  final int allowanceAmountMinor;
  final int rolloverMinor;
  final int adjustmentMinor;
  final String currency;
  final String startsOn;
  final String endsOn;
  final PeriodStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AllowanceSettings {
  const AllowanceSettings({
    required this.amountMinor,
    required this.dayOfMonth,
    this.rolloverMode = AllowanceRolloverMode.none,
  }) : assert(amountMinor >= 0),
       assert(dayOfMonth >= 1 && dayOfMonth <= 31);
  final int amountMinor;
  final int dayOfMonth;
  final AllowanceRolloverMode rolloverMode;
}

class FinancialSummary {
  const FinancialSummary({
    required this.period,
    required this.rolloverMinor,
    required this.receivedMinor,
    required this.spentMinor,
  }) : balanceMinor = rolloverMinor + receivedMinor - spentMinor;
  final String period;
  final int rolloverMinor;
  final int receivedMinor;
  final int spentMinor;
  final int balanceMinor;
}

FinancialSummary summarizePeriod(
  String period,
  int rolloverMinor,
  Iterable<Transaction> transactions,
) {
  DateRules.parsePeriod(period);
  if (rolloverMinor < 0)
    throw ArgumentError.value(rolloverMinor, 'rolloverMinor');
  var received = 0;
  var spent = 0;
  for (final transaction in transactions) {
    if (transaction.period != period || transaction.isDeleted) continue;
    if (transaction.signedAmountMinor >= 0) {
      received += transaction.signedAmountMinor;
    } else {
      spent += -transaction.signedAmountMinor;
    }
  }
  return FinancialSummary(
    period: period,
    rolloverMinor: rolloverMinor,
    receivedMinor: received,
    spentMinor: spent,
  );
}

int rolloverFor(AllowanceRolloverMode mode, int priorBalanceMinor) {
  if (priorBalanceMinor < 0) return 0;
  return mode == AllowanceRolloverMode.positiveOnly ? priorBalanceMinor : 0;
}

String allowanceTransactionId(String period) {
  DateRules.parsePeriod(period);
  return 'allowance_$period';
}
