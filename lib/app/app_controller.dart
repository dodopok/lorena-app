import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/auth/auth_gateway.dart';
import '../core/biometrics/biometric_gateway.dart';
import '../core/calendar/calendar_gateway.dart';
import '../core/export/export_service.dart';
import '../core/notifications/lume_notification_gateway.dart';
import '../core/notifications/notification_rules.dart';
import '../core/photos/local_photo_service.dart';
import '../core/photos/firebase_photo_storage.dart';
import '../core/share/share_intent_service.dart';
import '../core/sync/remote_snapshot_store.dart';
import 'local_store.dart';
import 'models.dart';

typedef RemoteSnapshotStoreFactory = RemoteSnapshotStore Function(String uid);

class AppController extends ChangeNotifier {
  AppController({
    LocalStore? store,
    AuthGateway? authGateway,
    CalendarGateway? calendarGateway,
    LocalPhotoService? photoService,
    BiometricGateway? biometricGateway,
    LumeNotificationGateway? notificationGateway,
    PhotoStorageGateway? photoStorage,
    ExportService? exportService,
    RemoteSnapshotStoreFactory? remoteStoreFactory,
    ShareIntentService? shareIntentService,
  }) : _store = store ?? LocalStore(),
       _authGateway = authGateway,
       _calendarGateway = calendarGateway,
       _photoService = photoService ?? LocalPhotoService(),
       _biometricGateway = biometricGateway,
       _notificationGateway = notificationGateway,
       _photoStorage = photoStorage,
       _exportService = exportService ?? ExportService(),
       _remoteStoreFactory = remoteStoreFactory,
       _shareIntentService = shareIntentService;

  final LocalStore _store;
  final AuthGateway? _authGateway;
  final CalendarGateway? _calendarGateway;
  final LocalPhotoService _photoService;
  final BiometricGateway? _biometricGateway;
  final LumeNotificationGateway? _notificationGateway;
  final PhotoStorageGateway? _photoStorage;
  final ExportService _exportService;
  final RemoteSnapshotStoreFactory? _remoteStoreFactory;
  final ShareIntentService? _shareIntentService;
  RemoteSnapshotStore? _remoteStore;
  String? _remoteUserId;
  Future<void> _remoteWriteQueue = Future<void>.value();
  Future<void> _photoSyncQueue = Future<void>.value();

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
  String? calendarSyncToken;
  DateTime? calendarLastSyncedAt;
  Uri? pendingSharedUrl;

  /// Consumes the one-shot native share payload, if the current platform has
  /// the iOS Share Extension installed and configured.
  Future<void> consumeSharedUrl() async {
    final service = _shareIntentService;
    if (service == null) return;
    final url = await service.consumePendingUrl();
    if (url == null) return;
    pendingSharedUrl = url;
    notifyListeners();
  }

  void clearPendingSharedUrl([Uri? expected]) {
    if (expected != null &&
        pendingSharedUrl?.toString() != expected.toString()) {
      return;
    }
    if (pendingSharedUrl == null) return;
    pendingSharedUrl = null;
    notifyListeners();
  }

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
      calendarEvents = snapshot.calendarEvents;
      calendarSyncToken = snapshot.calendarSyncToken;
      calendarLastSyncedAt = snapshot.calendarLastSyncedAt;
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
    _ensureRemoteStore();
    if (!providerSession) {
      settings = settings.copyWith(onboardingComplete: false);
      _remoteStore = null;
      _remoteUserId = null;
    }
    await _store.write(_snapshot());
  }

  /// Reconciles local state with the authenticated user's remote snapshot.
  /// Firestore remains optional: failures leave the local copy usable.
  Future<void> syncRemote() async {
    if (!signedIn) return;
    _ensureRemoteStore();
    final remoteStore = _remoteStore;
    if (remoteStore == null) return;
    await _remoteWriteQueue;
    try {
      final remote = await remoteStore.read();
      if (remote == null) {
        await remoteStore.write(_snapshot());
        _queuePhotoSync();
        return;
      }
      _applySnapshot(remote);
      await _store.write(_snapshot());
      notifyListeners();
    } catch (_) {
      // Local writes are the recovery path when Firebase is unavailable.
    }
    _queuePhotoSync();
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

  Future<ExportBundle> createExport() => _exportService.create(_snapshot());

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
    _ensureRemoteStore();
    await _store.write(_snapshot());
    await syncRemote();
    _queuePhotoSync();
  }

  Future<void> signOut() async {
    await _remoteWriteQueue;
    await _notificationGateway?.cancelAll();
    await _authGateway?.signOut();
    await _calendarGateway?.disconnect();
    calendarEvents = [];
    calendarSyncToken = null;
    calendarLastSyncedAt = null;
    signedIn = false;
    settings = settings.copyWith(onboardingComplete: false);
    await _commit();
  }

  Future<void> deleteAccount() async {
    await _authGateway?.reauthenticate();
    _ensureRemoteStore();
    await _remoteWriteQueue;
    await _photoSyncQueue;
    await _notificationGateway?.cancelAll();
    await _deleteRemotePhotos();
    await _remoteStore?.clear();
    await _authGateway?.deleteAccount();
    await _calendarGateway?.disconnect();
    calendarEvents = [];
    calendarSyncToken = null;
    calendarLastSyncedAt = null;
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
    await _photoService.clearStoredPhotos();
    await _store.clear();
    notifyListeners();
  }

  Future<void> connectCalendar() async {
    final gateway = _calendarGateway;
    if (gateway == null) {
      throw const CalendarGatewayException(
        'A Agenda ainda não está configurada neste build.',
      );
    }
    await gateway.connect();
    final result = await gateway.syncEvents();
    calendarEvents = result.events;
    calendarSyncToken = result.nextSyncToken;
    calendarLastSyncedAt = DateTime.now();
    await updateSettings(settings.copyWith(calendarConnected: true));
  }

  Future<void> refreshCalendar() async {
    final gateway = _calendarGateway;
    if (gateway == null || !settings.calendarConnected) return;
    final result = await gateway.syncEvents(syncToken: calendarSyncToken);
    if (result.isIncremental) {
      final byId = <String, CalendarEvent>{
        for (final event in calendarEvents)
          if (event.id != null) event.id!: event,
      };
      for (final id in result.removedEventIds) {
        byId.remove(id);
      }
      for (final event in result.events) {
        if (event.id != null) byId[event.id!] = event;
      }
      calendarEvents = byId.values.toList()..sort(_compareCalendarEvents);
    } else {
      calendarEvents = result.events;
    }
    calendarSyncToken = result.nextSyncToken ?? calendarSyncToken;
    calendarLastSyncedAt = DateTime.now();
    await _commit();
  }

  Future<void> disconnectCalendar() async {
    await _calendarGateway?.disconnect();
    calendarEvents = [];
    calendarSyncToken = null;
    calendarLastSyncedAt = null;
    await updateSettings(settings.copyWith(calendarConnected: false));
  }

  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    final gateway = _requireCalendarGateway();
    final created = await gateway.createEvent(event);
    calendarEvents = _sortedCalendarEvents([...calendarEvents, created]);
    await _commit();
    return created;
  }

  Future<CalendarEvent> updateCalendarEvent(CalendarEvent event) async {
    final gateway = _requireCalendarGateway();
    if (event.id == null || event.id!.isEmpty) {
      throw const CalendarGatewayException(
        'Este evento não possui um identificador do Google.',
      );
    }
    final updated = await gateway.updateEvent(event);
    calendarEvents = _sortedCalendarEvents(
      calendarEvents
          .map((item) => item.id == updated.id ? updated : item)
          .toList(),
    );
    await _commit();
    return updated;
  }

  Future<void> deleteCalendarEvent(CalendarEvent event) async {
    final gateway = _requireCalendarGateway();
    if (event.id == null || event.id!.isEmpty) {
      throw const CalendarGatewayException(
        'Este evento não possui um identificador do Google.',
      );
    }
    await gateway.deleteEvent(event);
    calendarEvents = calendarEvents
        .where((item) => item.id != event.id)
        .toList();
    await _commit();
  }

  CalendarGateway _requireCalendarGateway() {
    if (!settings.calendarConnected) {
      throw const CalendarGatewayException(
        'Conecte a Agenda do Google primeiro.',
      );
    }
    final gateway = _calendarGateway;
    if (gateway == null) {
      throw const CalendarGatewayException(
        'A Agenda ainda não está configurada neste build.',
      );
    }
    return gateway;
  }

  List<CalendarEvent> _sortedCalendarEvents(List<CalendarEvent> events) =>
      events..sort(_compareCalendarEvents);

  int _compareCalendarEvents(CalendarEvent a, CalendarEvent b) =>
      a.start.compareTo(b.start);

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

  /// Enables the lock only when this device exposes a supported authenticator.
  /// The actual prompt is shown by [AppPrivacyShield] when the setting becomes
  /// active, keeping settings changes from triggering a duplicate prompt.
  Future<bool> setBiometricLockEnabled(bool enabled) async {
    if (enabled) {
      final gateway = _biometricGateway;
      if (gateway == null || !await gateway.isAvailable()) return false;
    }
    await updateSettings(settings.copyWith(biometricLockEnabled: enabled));
    return true;
  }

  /// Requests notification permission only when the user turns reminders on.
  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final gateway = _notificationGateway;
      if (gateway == null || !await gateway.requestPermission()) return false;
      final preferences =
          settings.reminderPreferences.waterTimes.isEmpty &&
              settings.reminderPreferences.exerciseWeekdays.isEmpty
          ? const ReminderPreferences(
              waterTimes: ['10:00', '15:00', '20:00'],
              exerciseWeekdays: [1, 3, 5],
            )
          : settings.reminderPreferences;
      await updateSettings(
        settings.copyWith(
          notificationsEnabled: true,
          reminderPreferences: preferences,
        ),
      );
      await rescheduleNotifications();
      return true;
    }
    await updateSettings(settings.copyWith(notificationsEnabled: false));
    await _notificationGateway?.cancelAll();
    return true;
  }

  Future<void> updateReminderPreferences(
    ReminderPreferences preferences,
  ) async {
    await updateSettings(settings.copyWith(reminderPreferences: preferences));
    if (settings.notificationsEnabled) await rescheduleNotifications();
  }

  Future<void> rescheduleNotifications() async {
    final gateway = _notificationGateway;
    if (gateway == null || !settings.notificationsEnabled) return;
    await gateway.cancelAll();
    final schedules = planReminderWindow(
      now: DateTime.now(),
      preferences: settings.reminderPreferences,
      allowanceDayOfMonth: settings.allowanceDayOfMonth,
    );
    for (final schedule in schedules) {
      await gateway.schedule(schedule);
    }
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

  Future<String> addBowel({
    String? note,
    int? bristolType,
    BowelComfort? comfort,
    DateTime? at,
  }) async {
    if (bristolType != null && (bristolType < 1 || bristolType > 7)) {
      throw ArgumentError.value(bristolType, 'bristolType');
    }
    final occurredAt = at ?? DateTime.now();
    final id = _id('bowel');
    bowelLogs = [
      ...bowelLogs,
      BowelLog(
        id: id,
        occurredAt: occurredAt,
        localDate: localDateFor(occurredAt),
        bristolType: bristolType,
        comfort: comfort,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
    return id;
  }

  Future<void> updateBowel({
    required String id,
    required DateTime at,
    int? bristolType,
    BowelComfort? comfort,
    String? note,
  }) async {
    if (bristolType != null && (bristolType < 1 || bristolType > 7)) {
      throw ArgumentError.value(bristolType, 'bristolType');
    }
    final existing = bowelLogs.where((item) => item.id == id).firstOrNull;
    if (existing == null) throw ArgumentError('Registro não encontrado');
    bowelLogs = bowelLogs
        .map(
          (item) => item.id == id
              ? existing.copyWith(
                  occurredAt: at,
                  localDate: localDateFor(at),
                  bristolType: bristolType,
                  clearBristolType: bristolType == null,
                  comfort: comfort,
                  clearComfort: comfort == null,
                  note: note?.trim(),
                  clearNote: note?.trim().isEmpty != false,
                )
              : item,
        )
        .toList();
    await _commit();
  }

  Future<void> removeBowel(String id) async {
    bowelLogs = bowelLogs.where((log) => log.id != id).toList();
    await _commit();
  }

  Future<void> addExercise({
    required String activityType,
    required int durationMinutes,
    ExerciseIntensity? intensity,
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
        intensity: intensity,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
  }

  Future<void> updateExercise({
    required String id,
    required String activityType,
    required int durationMinutes,
    required DateTime at,
    ExerciseIntensity? intensity,
    String? note,
  }) async {
    if (activityType.trim().isEmpty || durationMinutes <= 0) {
      throw ArgumentError('activityType e durationMinutes são obrigatórios');
    }
    final existing = exerciseLogs.where((item) => item.id == id).firstOrNull;
    if (existing == null) throw ArgumentError('Sessão não encontrada');
    exerciseLogs = exerciseLogs
        .map(
          (item) => item.id == id
              ? existing.copyWith(
                  activityType: activityType.trim(),
                  durationMinutes: durationMinutes,
                  occurredAt: at,
                  localDate: localDateFor(at),
                  intensity: intensity,
                  clearIntensity: intensity == null,
                  note: note?.trim(),
                  clearNote: note?.trim().isEmpty != false,
                )
              : item,
        )
        .toList();
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
    DateTime? at,
    String? note,
  }) async {
    if (amountMinor <= 0) throw ArgumentError.value(amountMinor, 'amountMinor');
    final existing = transactions.where((entry) => entry.id == id).firstOrNull;
    if (existing == null) throw ArgumentError('Lançamento não encontrado');
    final occurredAt = at ?? existing.occurredAt;
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
                  occurredAt: occurredAt,
                  period: periodFor(occurredAt),
                  note: note?.trim(),
                  clearNote: note?.trim().isEmpty != false,
                )
              : entry,
        )
        .toList();
    await _commit();
  }

  Future<String?> pickLocalPhoto(LocalPhotoKind kind) =>
      _photoService.pickAndStore(kind);

  /// Retries local media that has not yet reached the private Storage path.
  /// The local file remains the source of recovery when the network is down.
  Future<void> retryPhotoUploads() {
    _queuePhotoSync();
    return _photoSyncQueue;
  }

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
    final previous = gratitudeEntries
        .where((item) => item.localDate == localDate)
        .firstOrNull;
    final imageUnchanged = previous?.localImagePath == localImagePath;
    if (previous != null && !imageUnchanged) {
      for (final remotePath in previous.remoteImagePaths) {
        _queuePhotoDeletion(
          category: PhotoCategory.gratitude,
          id: previous.localDate,
          remotePath: remotePath,
        );
      }
      await _deleteLocalPhoto(previous.localImagePath);
    }
    final entry = GratitudeEntry(
      localDate: localDate,
      text: trimmed,
      localImagePath: localImagePath,
      remoteImagePaths: imageUnchanged
          ? previous?.remoteImagePaths ?? const []
          : const [],
      mediaSyncState: localImagePath == null || localImagePath.isEmpty
          ? MediaSyncState.uploaded
          : imageUnchanged && previous?.remoteImagePaths.isNotEmpty == true
          ? MediaSyncState.uploaded
          : MediaSyncState.pending,
      syncState: SyncState.pending,
    );
    gratitudeEntries = [
      ...gratitudeEntries.where((item) => item.localDate != localDate),
      entry,
    ];
    await _commit();
    _queuePhotoSync();
  }

  Future<void> removeGratitude(String localDate) async {
    final existing = gratitudeEntries
        .where((item) => item.localDate == localDate)
        .firstOrNull;
    if (existing == null) return;
    gratitudeEntries = gratitudeEntries
        .where((item) => item.localDate != localDate)
        .toList();
    await _commit();
    for (final remotePath in existing.remoteImagePaths) {
      _queuePhotoDeletion(
        category: PhotoCategory.gratitude,
        id: existing.localDate,
        remotePath: remotePath,
      );
    }
    await _deleteLocalPhoto(existing.localImagePath);
  }

  Future<void> addBook({
    required String title,
    String? author,
    BookStatus status = BookStatus.wantToRead,
    int? rating,
    String? review,
    String? localCoverPath,
    DateTime? startedOn,
    DateTime? finishedOn,
    String? isbn,
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
        startedOn: startedOn,
        finishedOn: finishedOn,
        rating: rating,
        review: review?.trim().isEmpty == true ? null : review?.trim(),
        isbn: isbn?.trim().isEmpty == true ? null : isbn?.trim(),
        localCoverPath: localCoverPath,
        mediaSyncState: localCoverPath == null || localCoverPath.isEmpty
            ? MediaSyncState.uploaded
            : MediaSyncState.pending,
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
    _queuePhotoSync();
  }

  Future<void> updateBook({
    required String id,
    required String title,
    String? author,
    BookStatus? status,
    DateTime? startedOn,
    DateTime? finishedOn,
    int? rating,
    String? review,
    String? isbn,
    String? localCoverPath,
    bool clearLocalCoverPath = false,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Título obrigatório');
    if (rating != null && (rating < 1 || rating > 5)) {
      throw ArgumentError('A avaliação deve estar entre 1 e 5');
    }
    final existing = books.where((item) => item.id == id).firstOrNull;
    if (existing == null) throw ArgumentError('Livro não encontrado');
    final nextCoverPath = clearLocalCoverPath
        ? null
        : localCoverPath ?? existing.localCoverPath;
    final coverChanged = nextCoverPath != existing.localCoverPath;
    if (coverChanged) {
      final remotePath = existing.remoteCoverPath;
      if (remotePath != null) {
        _queuePhotoDeletion(
          category: PhotoCategory.bookCover,
          id: existing.id,
          remotePath: remotePath,
        );
      }
      await _deleteLocalPhoto(existing.localCoverPath);
    }
    books = books
        .map(
          (item) => item.id == id
              ? existing.copyWith(
                  title: title.trim(),
                  author: author?.trim(),
                  clearAuthor: author?.trim().isEmpty != false,
                  status: status,
                  startedOn: startedOn,
                  clearStartedOn: startedOn == null,
                  finishedOn: finishedOn,
                  clearFinishedOn: finishedOn == null,
                  rating: rating,
                  clearRating: rating == null,
                  review: review?.trim(),
                  clearReview: review?.trim().isEmpty != false,
                  isbn: isbn?.trim(),
                  clearIsbn: isbn?.trim().isEmpty != false,
                  localCoverPath: nextCoverPath,
                  clearLocalCoverPath: coverChanged && nextCoverPath == null,
                  clearRemoteCoverPath: coverChanged,
                  mediaSyncState: coverChanged
                      ? nextCoverPath == null
                            ? MediaSyncState.removed
                            : MediaSyncState.pending
                      : null,
                )
              : item,
        )
        .toList();
    await _commit();
    _queuePhotoSync();
  }

  Future<void> removeBook(String id) async {
    final existing = books.where((book) => book.id == id).firstOrNull;
    books = books.where((book) => book.id != id).toList();
    await _commit();
    if (existing == null) return;
    final remotePath = existing.remoteCoverPath;
    if (remotePath != null) {
      _queuePhotoDeletion(
        category: PhotoCategory.bookCover,
        id: existing.id,
        remotePath: remotePath,
      );
    }
    await _deleteLocalPhoto(existing.localCoverPath);
  }

  Future<void> addWishlistItem({
    required String originalUrl,
    required String title,
    int? priceMinor,
    String? note,
    String? localImagePath,
    WishlistStatus status = WishlistStatus.wanted,
  }) async {
    final uri = _validatedWishlistUri(originalUrl);
    final normalizedTitle = title.trim().isEmpty ? uri.host : title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Nome obrigatório');
    if (priceMinor != null && priceMinor < 0) {
      throw ArgumentError('Preço não pode ser negativo');
    }
    wishlistItems = [
      ...wishlistItems,
      WishlistItem(
        id: _id('wishlist'),
        originalUrl: uri.toString(),
        title: normalizedTitle,
        siteHost: uri.host,
        priceMinor: priceMinor,
        currency: priceMinor == null ? null : 'BRL',
        status: status,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        localImagePath: localImagePath,
        mediaSyncState: localImagePath == null || localImagePath.isEmpty
            ? MediaSyncState.uploaded
            : MediaSyncState.pending,
        syncState: SyncState.pending,
      ),
    ];
    await _commit();
    _queuePhotoSync();
  }

  Future<void> updateWishlistStatus(String id, WishlistStatus status) async {
    wishlistItems = wishlistItems
        .map((item) => item.id == id ? item.copyWith(status: status) : item)
        .toList();
    await _commit();
  }

  Future<void> removeWishlistItem(String id) async {
    final existing = wishlistItems.where((item) => item.id == id).firstOrNull;
    wishlistItems = wishlistItems.where((item) => item.id != id).toList();
    await _commit();
    if (existing == null) return;
    final remotePath = existing.remoteImagePath;
    if (remotePath != null) {
      _queuePhotoDeletion(
        category: PhotoCategory.wishlist,
        id: existing.id,
        remotePath: remotePath,
      );
    }
    await _deleteLocalPhoto(existing.localImagePath);
  }

  Future<void> updateWishlistItem({
    required String id,
    required String originalUrl,
    required String title,
    int? priceMinor,
    String? note,
    String? localImagePath,
    WishlistStatus? status,
  }) async {
    final uri = _validatedWishlistUri(originalUrl);
    final normalizedTitle = title.trim().isEmpty ? uri.host : title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Nome obrigatório');
    if (priceMinor != null && priceMinor < 0) {
      throw ArgumentError('Preço não pode ser negativo');
    }
    final existing = wishlistItems.where((item) => item.id == id).firstOrNull;
    if (existing == null) throw ArgumentError('Desejo não encontrado');
    final changedImage = localImagePath != existing.localImagePath;
    if (changedImage) {
      final remotePath = existing.remoteImagePath;
      if (remotePath != null) {
        _queuePhotoDeletion(
          category: PhotoCategory.wishlist,
          id: existing.id,
          remotePath: remotePath,
        );
      }
      await _deleteLocalPhoto(existing.localImagePath);
    }
    wishlistItems = wishlistItems
        .map(
          (item) => item.id == id
              ? existing.copyWith(
                  originalUrl: uri.toString(),
                  title: normalizedTitle,
                  siteHost: uri.host,
                  priceMinor: priceMinor,
                  clearPrice: priceMinor == null,
                  status: status,
                  note: note?.trim(),
                  clearNote: note?.trim().isEmpty != false,
                  localImagePath: localImagePath,
                  clearLocalImagePath: localImagePath == null,
                  clearRemoteImagePath: changedImage,
                  mediaSyncState: changedImage
                      ? localImagePath == null
                            ? MediaSyncState.removed
                            : MediaSyncState.pending
                      : null,
                )
              : item,
        )
        .toList();
    await _commit();
    _queuePhotoSync();
  }

  Future<void> addShoppingItem(
    String name, {
    String quantity = '1',
    String? note,
    int? estimatedPriceMinor,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Item obrigatório');
    if (estimatedPriceMinor != null && estimatedPriceMinor < 0) {
      throw ArgumentError('Preço não pode ser negativo');
    }
    shoppingItems = [
      ...shoppingItems,
      ShoppingItem(
        id: _id('shopping'),
        name: name.trim(),
        quantity: quantity.trim().isEmpty ? '1' : quantity.trim(),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        estimatedPriceMinor: estimatedPriceMinor,
        position: shoppingItems.length,
      ),
    ];
    await _commit();
  }

  Future<void> updateShoppingItem({
    required String id,
    required String name,
    String quantity = '1',
    String? note,
    int? estimatedPriceMinor,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Item obrigatório');
    if (estimatedPriceMinor != null && estimatedPriceMinor < 0) {
      throw ArgumentError('Preço não pode ser negativo');
    }
    final existing = shoppingItems.where((item) => item.id == id).firstOrNull;
    if (existing == null) throw ArgumentError('Item não encontrado');
    shoppingItems = shoppingItems
        .map(
          (item) => item.id == id
              ? existing.copyWith(
                  name: name.trim(),
                  quantity: quantity.trim().isEmpty ? '1' : quantity.trim(),
                  note: note?.trim(),
                  clearNote: note?.trim().isEmpty != false,
                  estimatedPriceMinor: estimatedPriceMinor,
                  clearEstimatedPrice: estimatedPriceMinor == null,
                )
              : item,
        )
        .toList();
    await _commit();
  }

  Future<void> reorderShoppingItems(List<String> orderedIds) async {
    final byId = {for (final item in shoppingItems) item.id: item};
    if (byId.length != orderedIds.length ||
        orderedIds.any((id) => !byId.containsKey(id))) {
      throw ArgumentError('A ordem da lista de compras é inválida');
    }
    shoppingItems = [
      for (var index = 0; index < orderedIds.length; index++)
        byId[orderedIds[index]]!.copyWith(position: index),
    ];
    await _commit();
  }

  Future<void> toggleShoppingItem(String id) async {
    final toggledAt = DateTime.now();
    shoppingItems = shoppingItems
        .map(
          (item) => item.id == id
              ? item.copyWith(
                  isChecked: !item.isChecked,
                  checkedAt: !item.isChecked ? toggledAt : null,
                  clearCheckedAt: item.isChecked,
                )
              : item,
        )
        .toList();
    await _commit();
  }

  Future<void> removeShoppingItem(String id) async {
    shoppingItems = [
      for (var index = 0; index < shoppingItems.length; index++)
        if (shoppingItems[index].id != id)
          shoppingItems[index].copyWith(position: index),
    ];
    await _commit();
  }

  Future<void> clearCompletedShoppingItems() async {
    shoppingItems = [
      for (final item in shoppingItems.where((item) => !item.isChecked))
        item.copyWith(position: 0),
    ];
    shoppingItems = [
      for (var index = 0; index < shoppingItems.length; index++)
        shoppingItems[index].copyWith(position: index),
    ];
    await _commit();
  }

  Uri _validatedWishlistUri(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('Informe uma URL http(s) válida e segura');
    }
    return uri;
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

  void _queuePhotoSync() {
    if (!signedIn || _photoStorage == null || _authGateway?.userId == null) {
      return;
    }
    _photoSyncQueue = _photoSyncQueue.then((_) => _syncPendingPhotos());
  }

  void _queuePhotoDeletion({
    required PhotoCategory category,
    required String id,
    required String remotePath,
  }) {
    final storage = _photoStorage;
    final uid = _authGateway?.userId;
    if (!signedIn || storage == null || uid == null || uid.isEmpty) return;
    _photoSyncQueue = _photoSyncQueue.then((_) async {
      try {
        await storage.delete(
          uid: uid,
          category: category,
          id: id,
          fileName: remotePath,
        );
      } catch (_) {
        // A cleanup failure is recoverable by the backend account cleanup job.
      }
    });
  }

  Future<void> _deleteLocalPhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _photoService.deleteStored(path);
    } catch (_) {
      // The domain record is already gone; a missing local file is harmless.
    }
  }

  Future<void> _syncPendingPhotos() async {
    final storage = _photoStorage;
    final uid = _authGateway?.userId;
    if (!signedIn || storage == null || uid == null || uid.isEmpty) return;

    var changed = false;
    for (final entry in List<GratitudeEntry>.from(gratitudeEntries)) {
      final path = entry.localImagePath;
      if (path == null || path.isEmpty || entry.remoteImagePaths.isNotEmpty) {
        continue;
      }
      try {
        await storage.uploadFile(
          uid: uid,
          category: PhotoCategory.gratitude,
          id: entry.localDate,
          file: File(path),
          fileName: path,
        );
        final remotePath = buildPhotoStoragePath(
          uid: uid,
          category: PhotoCategory.gratitude,
          id: entry.localDate,
          extension: path,
        );
        gratitudeEntries = gratitudeEntries
            .map(
              (item) => item.localDate == entry.localDate
                  ? item.copyWith(
                      remoteImagePaths: [remotePath],
                      mediaSyncState: MediaSyncState.uploaded,
                    )
                  : item,
            )
            .toList();
        changed = true;
      } catch (_) {
        gratitudeEntries = gratitudeEntries
            .map(
              (item) => item.localDate == entry.localDate
                  ? item.copyWith(mediaSyncState: MediaSyncState.failed)
                  : item,
            )
            .toList();
        changed = true;
      }
    }

    for (final book in List<BookEntry>.from(books)) {
      final path = book.localCoverPath;
      if (path == null || path.isEmpty || book.remoteCoverPath != null) {
        continue;
      }
      try {
        await storage.uploadFile(
          uid: uid,
          category: PhotoCategory.bookCover,
          id: book.id,
          file: File(path),
          fileName: path,
        );
        final remotePath = buildPhotoStoragePath(
          uid: uid,
          category: PhotoCategory.bookCover,
          id: book.id,
          extension: path,
        );
        books = books
            .map(
              (item) => item.id == book.id
                  ? item.copyWith(
                      remoteCoverPath: remotePath,
                      mediaSyncState: MediaSyncState.uploaded,
                    )
                  : item,
            )
            .toList();
        changed = true;
      } catch (_) {
        books = books
            .map(
              (item) => item.id == book.id
                  ? item.copyWith(mediaSyncState: MediaSyncState.failed)
                  : item,
            )
            .toList();
        changed = true;
      }
    }

    for (final item in List<WishlistItem>.from(wishlistItems)) {
      final path = item.localImagePath;
      if (path == null || path.isEmpty || item.remoteImagePath != null) {
        continue;
      }
      try {
        await storage.uploadFile(
          uid: uid,
          category: PhotoCategory.wishlist,
          id: item.id,
          file: File(path),
          fileName: path,
        );
        final remotePath = buildPhotoStoragePath(
          uid: uid,
          category: PhotoCategory.wishlist,
          id: item.id,
          extension: path,
        );
        wishlistItems = wishlistItems
            .map(
              (current) => current.id == item.id
                  ? current.copyWith(
                      remoteImagePath: remotePath,
                      mediaSyncState: MediaSyncState.uploaded,
                    )
                  : current,
            )
            .toList();
        changed = true;
      } catch (_) {
        wishlistItems = wishlistItems
            .map(
              (current) => current.id == item.id
                  ? current.copyWith(mediaSyncState: MediaSyncState.failed)
                  : current,
            )
            .toList();
        changed = true;
      }
    }

    if (changed) await _commit();
  }

  Future<void> _deleteRemotePhotos() async {
    final storage = _photoStorage;
    final uid = _authGateway?.userId;
    if (storage == null || uid == null || uid.isEmpty) return;
    final operations = <Future<void>>[];
    for (final entry in gratitudeEntries) {
      for (final path in entry.remoteImagePaths) {
        operations.add(
          storage.delete(
            uid: uid,
            category: PhotoCategory.gratitude,
            id: entry.localDate,
            fileName: path,
          ),
        );
      }
    }
    for (final book in books) {
      final path = book.remoteCoverPath;
      if (path != null) {
        operations.add(
          storage.delete(
            uid: uid,
            category: PhotoCategory.bookCover,
            id: book.id,
            fileName: path,
          ),
        );
      }
    }
    for (final item in wishlistItems) {
      final path = item.remoteImagePath;
      if (path != null) {
        operations.add(
          storage.delete(
            uid: uid,
            category: PhotoCategory.wishlist,
            id: item.id,
            fileName: path,
          ),
        );
      }
    }
    for (final operation in operations) {
      try {
        await operation;
      } catch (_) {
        // Account deletion still proceeds; a backend cleanup job can remove
        // orphaned media when a single object is already missing/offline.
      }
    }
  }

  Future<void> _commit() async {
    notifyListeners();
    final snapshot = _snapshot();
    await _store.write(snapshot);
    _queueRemoteWrite(snapshot);
  }

  AppSnapshot _snapshot() => AppSnapshot(
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
    calendarEvents: calendarEvents,
    calendarSyncToken: calendarSyncToken,
    calendarLastSyncedAt: calendarLastSyncedAt,
  );

  void _applySnapshot(AppSnapshot snapshot) {
    signedIn = true;
    settings = snapshot.settings;
    waterLogs = snapshot.waterLogs;
    bowelLogs = snapshot.bowelLogs;
    exerciseLogs = snapshot.exerciseLogs;
    transactions = snapshot.transactions;
    gratitudeEntries = snapshot.gratitudeEntries;
    books = snapshot.books;
    wishlistItems = snapshot.wishlistItems;
    shoppingItems = snapshot.shoppingItems;
    // Calendar events and sync tokens are deliberately local-only. Firestore
    // snapshots do not contain this integration's cache.
  }

  void _ensureRemoteStore() {
    final userId = _authGateway?.userId;
    if (userId == null || userId.isEmpty || _remoteStoreFactory == null) return;
    if (_remoteUserId == userId && _remoteStore != null) return;
    _remoteUserId = userId;
    _remoteStore = _remoteStoreFactory(userId);
    _remoteWriteQueue = Future<void>.value();
  }

  void _queueRemoteWrite(AppSnapshot snapshot) {
    final remoteStore = _remoteStore;
    if (!signedIn || remoteStore == null) return;
    _remoteWriteQueue = _remoteWriteQueue.then((_) async {
      try {
        await remoteStore.write(snapshot);
      } catch (_) {
        // Keep the pending local snapshot; a later mutation retries it.
      }
    });
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
