import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'local_store.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController({LocalStore? store}) : _store = store ?? LocalStore();

  final LocalStore _store;

  bool isReady = false;
  bool signedIn = false;
  UserSettings settings = const UserSettings();
  List<WaterLog> waterLogs = [];
  List<BowelLog> bowelLogs = [];
  List<ExerciseLog> exerciseLogs = [];
  List<TransactionEntry> transactions = [];
  List<GratitudeEntry> gratitudeEntries = [];
  List<BookEntry> books = [];
  List<ShoppingItem> shoppingItems = [];

  Future<void> hydrate() async {
    final snapshot = await _store.read();
    if (snapshot != null) {
      signedIn = snapshot.signedIn;
      settings = snapshot.settings;
      waterLogs = snapshot.waterLogs;
      bowelLogs = snapshot.bowelLogs;
      exerciseLogs = snapshot.exerciseLogs;
      transactions = snapshot.transactions;
      gratitudeEntries = snapshot.gratitudeEntries;
      books = snapshot.books;
      shoppingItems = snapshot.shoppingItems;
    }
    isReady = true;
    if (signedIn && settings.allowanceAmountMinor > 0) {
      _ensureAllowanceForPeriod(periodFor(DateTime.now()));
    }
    notifyListeners();
  }

  String localDateFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String periodFor(DateTime date) => DateFormat('yyyy-MM').format(date);

  String formatMinor(int amountMinor) => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
      ).format(amountMinor / 100);

  String formatDate(DateTime date) => DateFormat("d 'de' MMMM", 'pt_BR').format(date);

  String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  List<WaterLog> waterFor(DateTime date) => waterLogs
      .where((log) => log.localDate == localDateFor(date))
      .toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  int waterTotalFor(DateTime date) =>
      waterFor(date).fold(0, (total, log) => total + log.amountMl);

  List<GratitudeEntry> gratitudeFor(DateTime date) => gratitudeEntries
      .where((entry) => entry.localDate == localDateFor(date))
      .toList();

  int exerciseMinutesForPeriod(String period) => exerciseLogs
      .where((log) => log.localDate.startsWith(period))
      .fold(0, (total, log) => total + log.durationMinutes);

  List<TransactionEntry> transactionsFor(String period) => transactions
      .where((entry) => entry.period == period)
      .toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  int incomeFor(String period) => transactionsFor(period)
      .where((entry) => entry.type != TransactionType.expense)
      .fold(0, (total, entry) => total + entry.amountMinor);

  int expensesFor(String period) => transactionsFor(period)
      .where((entry) => entry.type == TransactionType.expense)
      .fold(0, (total, entry) => total + entry.amountMinor);

  int balanceFor(String period) => incomeFor(period) - expensesFor(period);

  Future<void> signInOnDevice() async {
    signedIn = true;
    await _commit();
  }

  Future<void> signOut() async {
    signedIn = false;
    settings = settings.copyWith(onboardingComplete: false);
    await _commit();
  }

  Future<void> deleteAccount() async {
    signedIn = false;
    settings = const UserSettings();
    waterLogs = [];
    bowelLogs = [];
    exerciseLogs = [];
    transactions = [];
    gratitudeEntries = [];
    books = [];
    shoppingItems = [];
    await _store.clear();
    notifyListeners();
  }

  Future<void> saveOnboarding({
    required int waterGoalMl,
    required int allowanceAmountMinor,
    required int allowanceDayOfMonth,
    required RolloverMode rolloverMode,
  }) async {
    settings = settings.copyWith(
      waterGoalMl: waterGoalMl,
      allowanceAmountMinor: allowanceAmountMinor,
      allowanceDayOfMonth: allowanceDayOfMonth,
      rolloverMode: rolloverMode,
      onboardingComplete: true,
    );
    _ensureAllowanceForPeriod(periodFor(DateTime.now()));
    await _commit();
  }

  Future<void> updateSettings(UserSettings next) async {
    settings = next;
    if (settings.allowanceAmountMinor > 0) {
      _ensureAllowanceForPeriod(periodFor(DateTime.now()));
    }
    await _commit();
  }

  Future<String> addWater(int amountMl, {DateTime? at}) async {
    if (amountMl <= 0) throw ArgumentError.value(amountMl, 'amountMl');
    final occurredAt = at ?? DateTime.now();
    final id = _id('water');
    waterLogs = [
      ...waterLogs,
      WaterLog(
        id: id,
        amountMl: amountMl,
        occurredAt: occurredAt,
        localDate: localDateFor(occurredAt),
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
    return id;
  }

  Future<void> removeWater(String id) async {
    waterLogs = waterLogs.where((log) => log.id != id).toList();
    await _commit();
  }

  Future<void> addBowel({String? note, DateTime? at}) async {
    final occurredAt = at ?? DateTime.now();
    bowelLogs = [
      ...bowelLogs,
      BowelLog(
        id: _id('bowel'),
        occurredAt: occurredAt,
        localDate: localDateFor(occurredAt),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
  }

  Future<void> addExercise({
    required String activityType,
    required int durationMinutes,
    String? note,
    DateTime? at,
  }) async {
    if (activityType.trim().isEmpty || durationMinutes <= 0) {
      throw ArgumentError('activityType e durationMinutes são obrigatórios');
    }
    final occurredAt = at ?? DateTime.now();
    exerciseLogs = [
      ...exerciseLogs,
      ExerciseLog(
        id: _id('exercise'),
        activityType: activityType.trim(),
        durationMinutes: durationMinutes,
        occurredAt: occurredAt,
        localDate: localDateFor(occurredAt),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
  }

  Future<void> addTransaction({
    required TransactionType type,
    required int amountMinor,
    required String category,
    required String description,
    DateTime? at,
    String? note,
  }) async {
    if (amountMinor <= 0) throw ArgumentError.value(amountMinor, 'amountMinor');
    final occurredAt = at ?? DateTime.now();
    transactions = [
      ...transactions,
      TransactionEntry(
        id: _id('transaction'),
        type: type,
        amountMinor: amountMinor,
        occurredAt: occurredAt,
        period: periodFor(occurredAt),
        category: category.trim().isEmpty ? 'Outros' : category.trim(),
        description: description.trim(),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
  }

  Future<void> removeTransaction(String id) async {
    transactions = transactions.where((entry) => entry.id != id).toList();
    await _commit();
  }

  Future<void> saveGratitude(String text, {DateTime? date}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('A gratidão não pode ficar vazia');
    final localDate = localDateFor(date ?? DateTime.now());
    final entry = GratitudeEntry(
      localDate: localDate,
      text: trimmed,
      syncState: SyncState.pending,
    );
    gratitudeEntries = [
      ...gratitudeEntries.where((item) => item.localDate != localDate),
      entry,
    ];
    await _commit();
  }

  Future<void> addBook({
    required String title,
    String? author,
    BookStatus status = BookStatus.wantToRead,
    int? rating,
    String? review,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Título obrigatório');
    if (rating != null && (rating < 1 || rating > 5)) {
      throw ArgumentError('A avaliação deve estar entre 1 e 5');
    }
    books = [
      ...books,
      BookEntry(
        id: _id('book'),
        title: title.trim(),
        author: author?.trim().isEmpty == true ? null : author?.trim(),
        status: status,
        rating: rating,
        review: review?.trim().isEmpty == true ? null : review?.trim(),
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
  }

  Future<void> removeBook(String id) async {
    books = books.where((book) => book.id != id).toList();
    await _commit();
  }

  Future<void> addShoppingItem(String name, {String quantity = '1'}) async {
    if (name.trim().isEmpty) throw ArgumentError('Item obrigatório');
    shoppingItems = [
      ...shoppingItems,
      ShoppingItem(
        id: _id('shopping'),
        name: name.trim(),
        quantity: quantity.trim().isEmpty ? '1' : quantity.trim(),
      ),
    ];
    await _commit();
  }

  Future<void> toggleShoppingItem(String id) async {
    shoppingItems = shoppingItems
        .map((item) => item.id == id ? item.copyWith(isChecked: !item.isChecked) : item)
        .toList();
    await _commit();
  }

  Future<void> removeShoppingItem(String id) async {
    shoppingItems = shoppingItems.where((item) => item.id != id).toList();
    await _commit();
  }

  Future<void> clearCompletedShoppingItems() async {
    shoppingItems = shoppingItems.where((item) => !item.isChecked).toList();
    await _commit();
  }

  void _ensureAllowanceForPeriod(String period) {
    if (settings.allowanceAmountMinor <= 0 ||
        transactions.any((entry) => entry.id == 'allowance_$period')) {
      return;
    }
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = _lastValidDay(year, month, settings.allowanceDayOfMonth);
    final occurredAt = DateTime(year, month, day, 9);
    transactions = [
      ...transactions,
      TransactionEntry(
        id: 'allowance_$period',
        type: TransactionType.allowance,
        amountMinor: settings.allowanceAmountMinor,
        occurredAt: occurredAt,
        period: period,
        category: 'Mesada',
        description: 'Mesada de $period',
      ),
    ];
  }

  int _lastValidDay(int year, int month, int desiredDay) {
    final firstOfNextMonth = month == 12
        ? DateTime(year + 1, 1)
        : DateTime(year, month + 1);
    final lastDay = firstOfNextMonth.subtract(const Duration(days: 1)).day;
    return desiredDay.clamp(1, lastDay);
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _commit() async {
    notifyListeners();
    await _store.write(
      AppSnapshot(
        signedIn: signedIn,
        settings: settings,
        waterLogs: waterLogs,
        bowelLogs: bowelLogs,
        exerciseLogs: exerciseLogs,
        transactions: transactions,
        gratitudeEntries: gratitudeEntries,
        books: books,
        shoppingItems: shoppingItems,
      ),
    );
  }
}
