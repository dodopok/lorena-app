import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/data/data.dart';
import 'package:lume/core/domain/domain.dart';

void main() {
  test('isola dados por usuário e upsert pelo mesmo id é idempotente', () {
    final repository = LocalDomainRepository();
    final first = WaterLog(
      id: 'same',
      userId: 'u1',
      amountMl: 200,
      occurredAt: DateTime.utc(2026, 8, 24),
      localDate: '2026-08-24',
      source: WaterSource.manual,
    );
    final second = WaterLog(
      id: 'same',
      userId: 'u1',
      amountMl: 500,
      occurredAt: DateTime.utc(2026, 8, 24),
      localDate: '2026-08-24',
      source: WaterSource.manual,
    );
    repository.saveWater(first);
    repository.saveWater(second);
    expect(repository.waterTotal('u1', '2026-08-24'), 500);
    expect(repository.waterTotal('u2', '2026-08-24'), 0);
  });

  test('gratitude substitui a entrada do mesmo dia sem duplicar', () {
    final repository = LocalDomainRepository();
    repository.saveGratitude(
      GratitudeEntry(
        id: 'one',
        userId: 'u1',
        localDate: '2026-08-24',
        text: 'primeira',
      ),
    );
    repository.saveGratitude(
      GratitudeEntry(
        id: 'two',
        userId: 'u1',
        localDate: '2026-08-24',
        text: 'editada',
      ),
    );
    expect(repository.gratitudeHistory('u1'), hasLength(1));
    expect(repository.gratitudeForDate('u1', '2026-08-24')!.text, 'editada');
  });

  test('mesada usa id determinístico e não duplica no retry', () {
    final repository = LocalDomainRepository();
    const settings = AllowanceSettings(
      amountMinor: 50000,
      dayOfMonth: 31,
      rolloverMode: AllowanceRolloverMode.positiveOnly,
    );
    final first = repository.ensureAllowancePeriod(
      userId: 'u1',
      period: '2026-02',
      settings: settings,
    );
    final second = repository.ensureAllowancePeriod(
      userId: 'u1',
      period: '2026-02',
      settings: settings,
    );
    expect(first.rolloverMinor, 0);
    expect(second, same(first));
    expect(repository.transactionsForPeriod('u1', '2026-02'), hasLength(1));
    expect(
      repository.transactionsForPeriod('u1', '2026-02').single.id,
      allowanceTransactionId('2026-02'),
    );
  });

  test('saldo deriva dos lançamentos e exclusão é idempotente', () {
    final repository = LocalDomainRepository();
    repository.ensureAllowancePeriod(
      userId: 'u1',
      period: '2026-08',
      settings: const AllowanceSettings(amountMinor: 50000, dayOfMonth: 10),
    );
    final expense = Transaction(
      id: 'expense-1',
      userId: 'u1',
      type: TransactionType.expense,
      amountMinor: 2599,
      occurredAt: DateTime.utc(2026, 8, 10),
      localDate: '2026-08-10',
      period: '2026-08',
      categoryId: 'food',
      description: 'almoço',
    );
    repository.saveTransaction(expense);
    expect(repository.financialSummary('u1', '2026-08').balanceMinor, 47401);
    expect(repository.deleteTransaction('u1', 'expense-1'), isTrue);
    expect(repository.deleteTransaction('u1', 'expense-1'), isFalse);
    expect(repository.financialSummary('u1', '2026-08').balanceMinor, 50000);
  });

  test('itens de compras permanecem após marcar e ordenam por posição', () {
    final repository = LocalDomainRepository();
    repository.saveShoppingList(
      ShoppingList(id: 'list', userId: 'u1', name: 'Mercado'),
    );
    final item = ShoppingItem(
      id: 'item',
      userId: 'u1',
      listId: 'list',
      name: 'Café',
      position: 2,
    );
    repository.saveShoppingItem(item);
    repository.saveShoppingItem(item.toggled(at: DateTime.utc(2026, 8, 24)));
    expect(repository.shoppingItems('u1', 'list'), hasLength(1));
    expect(repository.shoppingItems('u1', 'list').single.isChecked, isTrue);
    expect(repository.shoppingItems('u2', 'list'), isEmpty);
  });
}
