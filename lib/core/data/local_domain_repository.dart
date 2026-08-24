import '../domain/domain.dart';

/// Armazenamento operacional local para a primeira fatia.
///
/// Cada coleção é particionada por [userId]. Nenhuma leitura aceita dados de
/// outro usuário, e gravar novamente o mesmo ID substitui o registro em vez de
/// criar uma segunda cópia. A implementação é deliberadamente síncrona para
/// poder ser trocada por SQLite/Firestore sem contaminar o domínio.
class LocalDomainRepository {
  final Map<String, Map<String, WaterLog>> _water = {};
  final Map<String, Map<String, GratitudeEntry>> _gratitude = {};
  final Map<String, Map<String, Transaction>> _transactions = {};
  final Map<String, Map<String, AllowancePeriod>> _periods = {};
  final Map<String, Map<String, ShoppingList>> _lists = {};
  final Map<String, Map<String, ShoppingItem>> _items = {};

  Map<String, T> _bucket<T>(
    Map<String, Map<String, T>> collection,
    String userId,
  ) => collection.putIfAbsent(userId, () => <String, T>{});

  WaterLog saveWater(WaterLog log) {
    _bucket(_water, log.userId)[log.id] = log;
    return log;
  }

  WaterLog? waterById(String userId, String id) => _water[userId]?[id];

  List<WaterLog> waterForDate(String userId, String localDate) =>
      List.unmodifiable(
        (_water[userId]?.values
                .where((log) => log.localDate == localDate)
                .toList() ??
            <WaterLog>[]),
      );

  bool deleteWater(String userId, String id) =>
      _water[userId]?.remove(id) != null;

  int waterTotal(String userId, String localDate) =>
      totalWaterForDate(waterForDate(userId, localDate), localDate);

  GratitudeEntry saveGratitude(GratitudeEntry entry) {
    final bucket = _bucket(_gratitude, entry.userId);
    // O ID normalmente é a data. A remoção do registro anterior também cobre
    // clientes que geraram IDs aleatórios para a mesma data.
    for (final old
        in bucket.values
            .where(
              (value) =>
                  value.localDate == entry.localDate && value.id != entry.id,
            )
            .toList()) {
      bucket.remove(old.id);
    }
    bucket[entry.id] = entry;
    return entry;
  }

  GratitudeEntry? gratitudeForDate(String userId, String localDate) =>
      _gratitude[userId]?.values
          .where((entry) => entry.localDate == localDate)
          .firstOrNull;

  List<GratitudeEntry> gratitudeHistory(String userId) {
    final values = _gratitude[userId]?.values.toList() ?? <GratitudeEntry>[];
    values.sort((a, b) => b.localDate.compareTo(a.localDate));
    return List.unmodifiable(values);
  }

  bool deleteGratitude(String userId, String id) =>
      _gratitude[userId]?.remove(id) != null;

  Transaction saveTransaction(Transaction transaction) {
    _bucket(_transactions, transaction.userId)[transaction.id] = transaction;
    return transaction;
  }

  Transaction? transactionById(String userId, String id) =>
      _transactions[userId]?[id];

  List<Transaction> transactionsForPeriod(
    String userId,
    String period, {
    String? categoryId,
  }) {
    final values =
        _transactions[userId]?.values
            .where(
              (transaction) =>
                  transaction.period == period &&
                  !transaction.isDeleted &&
                  (categoryId == null || transaction.categoryId == categoryId),
            )
            .toList() ??
        <Transaction>[];
    values.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return List.unmodifiable(values);
  }

  /// Exclusão lógica mantém a operação recuperável e idempotente.
  bool deleteTransaction(String userId, String id, {DateTime? at}) {
    final transaction = _transactions[userId]?[id];
    if (transaction == null || transaction.isDeleted) return false;
    _transactions[userId]![id] = Transaction(
      id: transaction.id,
      userId: transaction.userId,
      type: transaction.type,
      amountMinor: transaction.amountMinor,
      currency: transaction.currency,
      occurredAt: transaction.occurredAt,
      localDate: transaction.localDate,
      period: transaction.period,
      categoryId: transaction.categoryId,
      description: transaction.description,
      note: transaction.note,
      source: transaction.source,
      adjustmentDirection: transaction.adjustmentDirection,
      createdAt: transaction.createdAt,
      updatedAt: at ?? DateTime.now().toUtc(),
      deletedAt: at ?? DateTime.now().toUtc(),
    );
    return true;
  }

  FinancialSummary financialSummary(String userId, String period) =>
      summarizePeriod(
        period,
        _periods[userId]?[period]?.rolloverMinor ?? 0,
        _transactions[userId]?.values ?? const <Transaction>[],
      );

  AllowancePeriod? allowancePeriod(String userId, String period) =>
      _periods[userId]?[period];

  /// Abre o período e garante que a entrada `allowance_YYYY-MM` exista uma só vez.
  AllowancePeriod ensureAllowancePeriod({
    required String userId,
    required String period,
    required AllowanceSettings settings,
    DateTime? now,
  }) {
    final existing = _periods[userId]?[period];
    if (existing != null) {
      final allowanceId = allowanceTransactionId(period);
      if (_transactions[userId]?[allowanceId] == null &&
          settings.amountMinor > 0) {
        saveTransaction(
          _allowanceTransaction(
            userId,
            period,
            settings.amountMinor,
            settings.dayOfMonth,
            now,
          ),
        );
      }
      return existing;
    }
    final previous = DateRules.previousPeriod(period);
    final priorBalance = financialSummary(userId, previous).balanceMinor;
    final periodModel = AllowancePeriod(
      userId: userId,
      period: period,
      allowanceAmountMinor: settings.amountMinor,
      rolloverMinor: rolloverFor(settings.rolloverMode, priorBalance),
      createdAt: now,
      updatedAt: now,
    );
    _bucket(_periods, userId)[period] = periodModel;
    if (settings.amountMinor > 0)
      saveTransaction(
        _allowanceTransaction(
          userId,
          period,
          settings.amountMinor,
          settings.dayOfMonth,
          now,
        ),
      );
    return periodModel;
  }

  Transaction _allowanceTransaction(
    String userId,
    String period,
    int amountMinor,
    int requestedDay,
    DateTime? now,
  ) {
    final day = DateRules.effectiveAllowanceDay(period, requestedDay);
    final date = DateRules.parsePeriod(period);
    final localDate = DateRules.formatDate(
      DateTime(date.year, date.month, day),
    );
    final occurredAt = now ?? DateTime.utc(date.year, date.month, day);
    return Transaction(
      id: allowanceTransactionId(period),
      userId: userId,
      type: TransactionType.allowance,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      localDate: localDate,
      period: period,
      categoryId: 'allowance',
      description: 'Mesada',
      source: TransactionSource.allowanceGeneration,
    );
  }

  ShoppingList saveShoppingList(ShoppingList list) {
    _bucket(_lists, list.userId)[list.id] = list;
    return list;
  }

  ShoppingList? shoppingListById(String userId, String id) =>
      _lists[userId]?[id];

  List<ShoppingList> shoppingLists(String userId) =>
      List.unmodifiable(_lists[userId]?.values.toList() ?? <ShoppingList>[]);

  bool deleteShoppingList(String userId, String id) {
    final removed = _lists[userId]?.remove(id) != null;
    if (removed) _items[userId]?.removeWhere((_, item) => item.listId == id);
    return removed;
  }

  ShoppingItem saveShoppingItem(ShoppingItem item) {
    if (_lists[item.userId]?[item.listId] == null)
      throw StateError('lista não encontrada para este usuário');
    _bucket(_items, item.userId)[item.id] = item;
    return item;
  }

  List<ShoppingItem> shoppingItems(String userId, String listId) =>
      orderedShoppingItems(
        (_items[userId]?.values
                .where((item) => item.listId == listId)
                .toList() ??
            <ShoppingItem>[]),
      );

  ShoppingItem? shoppingItemById(String userId, String id) =>
      _items[userId]?[id];

  bool deleteShoppingItem(String userId, String id) =>
      _items[userId]?.remove(id) != null;

  bool clearCheckedShoppingItems(String userId, String listId) {
    final ids =
        _items[userId]?.values
            .where((item) => item.listId == listId && item.isChecked)
            .map((item) => item.id)
            .toList() ??
        <String>[];
    for (final id in ids) _items[userId]!.remove(id);
    return ids.isNotEmpty;
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
