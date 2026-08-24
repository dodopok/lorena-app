import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/auth/auth_gateway.dart';
import '../core/calendar/calendar_gateway.dart';
import '../core/photos/local_photo_service.dart';
import 'local_store.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController({
    LocalStore? store,
    AuthGateway? authGateway,
    CalendarGateway? calendarGateway,
    LocalPhotoService? photoService,
  }) : _store = store ?? LocalStore(),
       _authGateway = authGateway,
       _calendarGateway = calendarGateway,
       _photoService = photoService ?? LocalPhotoService();

  final LocalStore _store;
  final AuthGateway? _authGateway;
  final CalendarGateway? _calendarGateway;
  final LocalPhotoService _photoService;

  bool isReady = false;
  bool signedIn = false;
  UserSettings settings = const UserSettings();
  List<WaterLog> waterLogs = [];
  List<BowelLog> bowelLogs = [];
  List<ExerciseLog> exerciseLogs = [];
  List<TransactionEntry> transactions = [];
  List<GratitudeEntry> gratitudeEntries = [];
  List<BookEntry> books = [];
  List<WishlistItem> wishlistItems = [];
  List<ShoppingItem> shoppingItems = [];
  List<CalendarEvent> calendarEvents = [];

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
      wishlistItems = snapshot.wishlistItems;
      shoppingItems = snapshot.shoppingItems;
    }
    isReady = true;
    if (signedIn && settings.allowanceAmountMinor > 0) {
      _ensureAllowanceForPeriod(periodFor(DateTime.now()));
    }
    notifyListeners();
  }

  /// Aligns the local shell with the provider session after Firebase starts.
  Future<void> restoreAuthSession() async {
    final gateway = _authGateway;
    if (gateway == null) return;
    final providerSession = await gateway.hasSession();
    signedIn = providerSession;
    if (!providerSession) {
      settings = settings.copyWith(onboardingComplete: false);
    }
    await _commit();
  }

  String localDateFor(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String periodFor(DateTime date) => DateFormat('yyyy-MM').format(date);

  String formatMinor(int amountMinor) => NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(amountMinor / 100);

  String formatDate(DateTime date) =>
      DateFormat("d 'de' MMMM", 'pt_BR').format(date);

  String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  List<WaterLog> waterFor(DateTime date) =>
      waterLogs.where((log) => log.localDate == localDateFor(date)).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  int waterTotalFor(DateTime date) =>
      waterFor(date).fold(0, (total, log) => total + log.amountMl);

  List<GratitudeEntry> gratitudeFor(DateTime date) => gratitudeEntries
      .where((entry) => entry.localDate == localDateFor(date))
      .toList();

  int exerciseMinutesForPeriod(String period) => exerciseLogs
      .where((log) => log.localDate.startsWith(period))
      .fold(0, (total, log) => total + log.durationMinutes);

  List<TransactionEntry> transactionsFor(String period) =>
      transactions.where((entry) => entry.period == period).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  int incomeFor(String period) => transactionsFor(period)
      .where((entry) => entry.type != TransactionType.expense)
      .fold(0, (total, entry) => total + entry.amountMinor);

  int expensesFor(String period) => transactionsFor(period)
      .where((entry) => entry.type == TransactionType.expense)
      .fold(0, (total, entry) => total + entry.amountMinor);

  int rolloverFor(String period) {
    if (settings.rolloverMode == RolloverMode.none) return 0;
    return _rolloverFor(period, 0);
  }

  int balanceFor(String period) =>
      rolloverFor(period) + incomeFor(period) - expensesFor(period);

  int _rolloverFor(String period, int depth) {
    if (depth > 24) return 0;
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final previous = DateTime(year, month - 1);
    final previousPeriod =
        '${previous.year.toString().padLeft(4, '0')}-${previous.month.toString().padLeft(2, '0')}';
    final previousBalance =
        _rolloverFor(previousPeriod, depth + 1) +
        incomeFor(previousPeriod) -
        expensesFor(previousPeriod);
    return previousBalance > 0 ? previousBalance : 0;
  }

  String exportJson() => AppSnapshot(
    signedIn: signedIn,
    settings: settings,
    waterLogs: waterLogs,
    bowelLogs: bowelLogs,
    exerciseLogs: exerciseLogs,
    transactions: transactions,
    gratitudeEntries: gratitudeEntries,
    books: books,
    wishlistItems: wishlistItems,
    shoppingItems: shoppingItems,
  ).encode();

  Future<void> signInOnDevice() async {
    signedIn = true;
    await _commit();
  }

  Future<void> signInWithApple() async {
    final gateway = _authGateway;
    if (gateway == null) {
      await signInOnDevice();
      return;
    }
    await gateway.signInWithApple();
    signedIn = true;
    await _commit();
  }

  Future<void> signOut() async {
    await _authGateway?.signOut();
    await _calendarGateway?.disconnect();
    calendarEvents = [];
    signedIn = false;
    settings = settings.copyWith(onboardingComplete: false);
    await _commit();
  }

  Future<void> deleteAccount() async {
    await _authGateway?.deleteAccount();
    await _calendarGateway?.disconnect();
    calendarEvents = [];
    signedIn = false;
    settings = const UserSettings();
    waterLogs = [];
    bowelLogs = [];
    exerciseLogs = [];
    transactions = [];
    gratitudeEntries = [];
    books = [];
    wishlistItems = [];
    shoppingItems = [];
    await _store.clear();
    notifyListeners();
  }

  Future<void> connectCalendar() async {
    final gateway = _calendarGateway;
    if (gateway == null) {
      await updateSettings(settings.copyWith(calendarConnected: true));
      return;
    }
    await gateway.connect();
    calendarEvents = await gateway.fetchEvents();
    await updateSettings(settings.copyWith(calendarConnected: true));
  }

  Future<void> refreshCalendar() async {
    final gateway = _calendarGateway;
    if (gateway == null || !settings.calendarConnected) return;
    calendarEvents = await gateway.fetchEvents();
    notifyListeners();
  }

  Future<void> disconnectCalendar() async {
    await _calendarGateway?.disconnect();
    calendarEvents = [];
    await updateSettings(settings.copyWith(calendarConnected: false));
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

  Future<void> removeBowel(String id) async {
    bowelLogs = bowelLogs.where((log) => log.id != id).toList();
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

  Future<void> removeExercise(String id) async {
    exerciseLogs = exerciseLogs.where((log) => log.id != id).toList();
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

  Future<void> updateTransaction({
    required String id,
    required TransactionType type,
    required int amountMinor,
    required String category,
    required String description,
    String? note,
  }) async {
    if (amountMinor <= 0) throw ArgumentError.value(amountMinor, 'amountMinor');
    final existing = transactions.where((entry) => entry.id == id).firstOrNull;
    if (existing == null) throw ArgumentError('Lançamento não encontrado');
    transactions = transactions
        .map(
          (entry) => entry.id == id
              ? existing.copyWith(
                  type: type,
                  amountMinor: amountMinor,
                  category: category.trim().isEmpty
                      ? 'Outros'
                      : category.trim(),
                  description: description.trim(),
                  note: note,
                )
              : entry,
        )
        .toList();
    await _commit();
  }

  Future<String?> pickLocalPhoto(LocalPhotoKind kind) =>
      _photoService.pickAndStore(kind);

  Future<void> saveGratitude(
    String text, {
    DateTime? date,
    String? localImagePath,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (localImagePath == null || localImagePath.isEmpty)) {
      throw ArgumentError('A gratidão precisa de texto ou foto');
    }
    final localDate = localDateFor(date ?? DateTime.now());
    final entry = GratitudeEntry(
      localDate: localDate,
      text: trimmed,
      localImagePath: localImagePath,
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
    String? localCoverPath,
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
        localCoverPath: localCoverPath,
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
  }

  Future<void> removeBook(String id) async {
    books = books.where((book) => book.id != id).toList();
    await _commit();
  }

  Future<void> addWishlistItem({
    required String originalUrl,
    required String title,
    int? priceMinor,
    String? note,
    String? localImagePath,
  }) async {
    final uri = Uri.tryParse(originalUrl.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('Informe uma URL http(s) válida e segura');
    }
    if (title.trim().isEmpty) throw ArgumentError('Nome obrigatório');
    if (priceMinor != null && priceMinor < 0) {
      throw ArgumentError('Preço não pode ser negativo');
    }
    wishlistItems = [
      ...wishlistItems,
      WishlistItem(
        id: _id('wishlist'),
        originalUrl: uri.toString(),
        title: title.trim(),
        siteHost: uri.host,
        priceMinor: priceMinor,
        currency: priceMinor == null ? null : 'BRL',
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        localImagePath: localImagePath,
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
  }

  Future<void> updateWishlistStatus(String id, WishlistStatus status) async {
    wishlistItems = wishlistItems
        .map((item) => item.id == id ? item.copyWith(status: status) : item)
        .toList();
    await _commit();
  }

  Future<void> removeWishlistItem(String id) async {
    wishlistItems = wishlistItems.where((item) => item.id != id).toList();
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
        .map(
          (item) =>
              item.id == id ? item.copyWith(isChecked: !item.isChecked) : item,
        )
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

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

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
        wishlistItems: wishlistItems,
        shoppingItems: shoppingItems,
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
