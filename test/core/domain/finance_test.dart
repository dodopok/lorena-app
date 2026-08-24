import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/domain/domain.dart';

Transaction tx(
  String id,
  TransactionType type,
  int cents, {
  AdjustmentDirection? direction,
}) => Transaction(
  id: id,
  userId: 'u1',
  type: type,
  amountMinor: cents,
  occurredAt: DateTime.utc(2026, 8, 10),
  localDate: '2026-08-10',
  period: '2026-08',
  categoryId: 'general',
  description: id,
  adjustmentDirection: direction,
  source: type == TransactionType.allowance
      ? TransactionSource.allowanceGeneration
      : TransactionSource.manual,
);

void main() {
  test('saldo usa centavos e direção do tipo', () {
    final summary = summarizePeriod('2026-08', 1000, [
      tx('allowance', TransactionType.allowance, 50000),
      tx('income', TransactionType.income, 1000),
      tx('expense', TransactionType.expense, 2599),
      tx(
        'adjustment',
        TransactionType.adjustment,
        100,
        direction: AdjustmentDirection.positive,
      ),
    ]);
    expect(summary.receivedMinor, 51100);
    expect(summary.spentMinor, 2599);
    expect(summary.balanceMinor, 49501);
  });

  test('rollover só carrega saldo positivo quando configurado', () {
    expect(rolloverFor(AllowanceRolloverMode.none, 100), 0);
    expect(rolloverFor(AllowanceRolloverMode.positiveOnly, 100), 100);
    expect(rolloverFor(AllowanceRolloverMode.positiveOnly, -1), 0);
  });

  test('transação exige período compatível e valor positivo', () {
    expect(() => tx('bad', TransactionType.expense, 0), throwsArgumentError);
    expect(
      () => Transaction(
        id: 'bad',
        userId: 'u1',
        type: TransactionType.expense,
        amountMinor: 1,
        occurredAt: DateTime.now(),
        localDate: '2026-08-10',
        period: '2026-07',
        categoryId: 'x',
        description: 'x',
      ),
      throwsArgumentError,
    );
  });
}
