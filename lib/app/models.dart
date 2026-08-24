import 'dart:convert';

enum TransactionType { allowance, income, expense, adjustment }

enum BookStatus { wantToRead, reading, read, abandoned }

enum RolloverMode { none, positiveOnly }

enum WishlistStatus { wanted, purchased, archived }

enum SyncState { synced, pending, offline, conflict }

String _string(Map<String, dynamic> map, String key, [String fallback = '']) =>
    map[key] is String ? map[key] as String : fallback;

int _int(Map<String, dynamic> map, String key, [int fallback = 0]) =>
    map[key] is num ? (map[key] as num).toInt() : fallback;

DateTime _date(Map<String, dynamic> map, String key, [DateTime? fallback]) =>
    DateTime.tryParse(_string(map, key)) ?? fallback ?? DateTime.now();

class UserSettings {
  const UserSettings({
    this.displayName = 'Luna',
    this.waterGoalMl = 2000,
    this.quickWaterAmountsMl = const [200, 300, 500],
    this.allowanceAmountMinor = 0,
    this.allowanceDayOfMonth = 1,
    this.rolloverMode = RolloverMode.positiveOnly,
    this.biometricLockEnabled = false,
    this.notificationsEnabled = false,
    this.calendarConnected = false,
    this.onboardingComplete = false,
  });

  final String displayName;
  final int waterGoalMl;
  final List<int> quickWaterAmountsMl;
  final int allowanceAmountMinor;
  final int allowanceDayOfMonth;
  final RolloverMode rolloverMode;
  final bool biometricLockEnabled;
  final bool notificationsEnabled;
  final bool calendarConnected;
  final bool onboardingComplete;

  UserSettings copyWith({
    String? displayName,
    int? waterGoalMl,
    List<int>? quickWaterAmountsMl,
    int? allowanceAmountMinor,
    int? allowanceDayOfMonth,
    RolloverMode? rolloverMode,
    bool? biometricLockEnabled,
    bool? notificationsEnabled,
    bool? calendarConnected,
    bool? onboardingComplete,
  }) {
    return UserSettings(
      displayName: displayName ?? this.displayName,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      quickWaterAmountsMl: quickWaterAmountsMl ?? this.quickWaterAmountsMl,
      allowanceAmountMinor: allowanceAmountMinor ?? this.allowanceAmountMinor,
      allowanceDayOfMonth: allowanceDayOfMonth ?? this.allowanceDayOfMonth,
      rolloverMode: rolloverMode ?? this.rolloverMode,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      calendarConnected: calendarConnected ?? this.calendarConnected,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'waterGoalMl': waterGoalMl,
    'quickWaterAmountsMl': quickWaterAmountsMl,
    'allowanceAmountMinor': allowanceAmountMinor,
    'allowanceDayOfMonth': allowanceDayOfMonth,
    'rolloverMode': rolloverMode.name,
    'biometricLockEnabled': biometricLockEnabled,
    'notificationsEnabled': notificationsEnabled,
    'calendarConnected': calendarConnected,
    'onboardingComplete': onboardingComplete,
  };

  factory UserSettings.fromJson(Map<String, dynamic> map) => UserSettings(
    displayName: _string(map, 'displayName', 'Luna'),
    waterGoalMl: _int(map, 'waterGoalMl', 2000).clamp(1, 10000),
    quickWaterAmountsMl: (map['quickWaterAmountsMl'] is List)
        ? (map['quickWaterAmountsMl'] as List)
              .whereType<num>()
              .map((value) => value.toInt())
              .where((value) => value > 0)
              .take(4)
              .toList()
        : const [200, 300, 500],
    allowanceAmountMinor: _int(map, 'allowanceAmountMinor'),
    allowanceDayOfMonth: _int(map, 'allowanceDayOfMonth', 1).clamp(1, 31),
    rolloverMode: RolloverMode.values.firstWhere(
      (value) => value.name == _string(map, 'rolloverMode'),
      orElse: () => RolloverMode.positiveOnly,
    ),
    biometricLockEnabled: map['biometricLockEnabled'] == true,
    notificationsEnabled: map['notificationsEnabled'] == true,
    calendarConnected: map['calendarConnected'] == true,
    onboardingComplete: map['onboardingComplete'] == true,
  );
}

class WaterLog {
  const WaterLog({
    required this.id,
    required this.amountMl,
    required this.occurredAt,
    required this.localDate,
    this.syncState = SyncState.synced,
  });

  final String id;
  final int amountMl;
  final DateTime occurredAt;
  final String localDate;
  final SyncState syncState;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amountMl': amountMl,
    'occurredAt': occurredAt.toIso8601String(),
    'localDate': localDate,
    'syncState': syncState.name,
  };

  factory WaterLog.fromJson(Map<String, dynamic> map) => WaterLog(
    id: _string(map, 'id'),
    amountMl: _int(map, 'amountMl'),
    occurredAt: _date(map, 'occurredAt'),
    localDate: _string(map, 'localDate'),
    syncState: SyncState.values.firstWhere(
      (value) => value.name == _string(map, 'syncState'),
      orElse: () => SyncState.synced,
    ),
  );
}

class BowelLog {
  const BowelLog({
    required this.id,
    required this.occurredAt,
    required this.localDate,
    this.note,
    this.syncState = SyncState.synced,
  });

  final String id;
  final DateTime occurredAt;
  final String localDate;
  final String? note;
  final SyncState syncState;

  Map<String, dynamic> toJson() => {
    'id': id,
    'occurredAt': occurredAt.toIso8601String(),
    'localDate': localDate,
    if (note != null && note!.isNotEmpty) 'note': note,
    'syncState': syncState.name,
  };

  factory BowelLog.fromJson(Map<String, dynamic> map) => BowelLog(
    id: _string(map, 'id'),
    occurredAt: _date(map, 'occurredAt'),
    localDate: _string(map, 'localDate'),
    note: map['note'] is String ? map['note'] as String : null,
    syncState: SyncState.values.firstWhere(
      (value) => value.name == _string(map, 'syncState'),
      orElse: () => SyncState.synced,
    ),
  );
}

class ExerciseLog {
  const ExerciseLog({
    required this.id,
    required this.activityType,
    required this.durationMinutes,
    required this.occurredAt,
    required this.localDate,
    this.note,
    this.syncState = SyncState.synced,
  });

  final String id;
  final String activityType;
  final int durationMinutes;
  final DateTime occurredAt;
  final String localDate;
  final String? note;
  final SyncState syncState;

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityType': activityType,
    'durationMinutes': durationMinutes,
    'occurredAt': occurredAt.toIso8601String(),
    'localDate': localDate,
    if (note != null && note!.isNotEmpty) 'note': note,
    'syncState': syncState.name,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> map) => ExerciseLog(
    id: _string(map, 'id'),
    activityType: _string(map, 'activityType', 'Movimento'),
    durationMinutes: _int(map, 'durationMinutes'),
    occurredAt: _date(map, 'occurredAt'),
    localDate: _string(map, 'localDate'),
    note: map['note'] is String ? map['note'] as String : null,
    syncState: SyncState.values.firstWhere(
      (value) => value.name == _string(map, 'syncState'),
      orElse: () => SyncState.synced,
    ),
  );
}

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    required this.period,
    this.category = 'Outros',
    this.description = '',
    this.note,
    this.syncState = SyncState.synced,
  });

  final String id;
  final TransactionType type;
  final int amountMinor;
  final DateTime occurredAt;
  final String period;
  final String category;
  final String description;
  final String? note;
  final SyncState syncState;

  TransactionEntry copyWith({
    TransactionType? type,
    int? amountMinor,
    DateTime? occurredAt,
    String? period,
    String? category,
    String? description,
    String? note,
  }) => TransactionEntry(
    id: id,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    occurredAt: occurredAt ?? this.occurredAt,
    period: period ?? this.period,
    category: category ?? this.category,
    description: description ?? this.description,
    note: note ?? this.note,
    syncState: SyncState.pending,
  );

  int get signedAmountMinor => switch (type) {
    TransactionType.expense => -amountMinor,
    TransactionType.adjustment => amountMinor,
    _ => amountMinor,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amountMinor': amountMinor,
    'occurredAt': occurredAt.toIso8601String(),
    'period': period,
    'category': category,
    'description': description,
    if (note != null && note!.isNotEmpty) 'note': note,
    'syncState': syncState.name,
  };

  factory TransactionEntry.fromJson(Map<String, dynamic> map) =>
      TransactionEntry(
        id: _string(map, 'id'),
        type: TransactionType.values.firstWhere(
          (value) => value.name == _string(map, 'type'),
          orElse: () => TransactionType.expense,
        ),
        amountMinor: _int(map, 'amountMinor').abs(),
        occurredAt: _date(map, 'occurredAt'),
        period: _string(map, 'period'),
        category: _string(map, 'category', 'Outros'),
        description: _string(map, 'description'),
        note: map['note'] is String ? map['note'] as String : null,
        syncState: SyncState.values.firstWhere(
          (value) => value.name == _string(map, 'syncState'),
          orElse: () => SyncState.synced,
        ),
      );
}

class GratitudeEntry {
  const GratitudeEntry({
    required this.localDate,
    required this.text,
    this.localImagePath,
    this.syncState = SyncState.synced,
  });

  final String localDate;
  final String text;
  final String? localImagePath;
  final SyncState syncState;

  Map<String, dynamic> toJson() => {
    'localDate': localDate,
    'text': text,
    if (localImagePath != null && localImagePath!.isNotEmpty)
      'localImagePath': localImagePath,
    'syncState': syncState.name,
  };

  factory GratitudeEntry.fromJson(Map<String, dynamic> map) => GratitudeEntry(
    localDate: _string(map, 'localDate'),
    text: _string(map, 'text'),
    localImagePath: map['localImagePath'] is String
        ? map['localImagePath'] as String
        : null,
    syncState: SyncState.values.firstWhere(
      (value) => value.name == _string(map, 'syncState'),
      orElse: () => SyncState.synced,
    ),
  );
}

class BookEntry {
  const BookEntry({
    required this.id,
    required this.title,
    this.author,
    this.localCoverPath,
    this.status = BookStatus.wantToRead,
    this.rating,
    this.review,
    this.syncState = SyncState.synced,
  });

  final String id;
  final String title;
  final String? author;
  final String? localCoverPath;
  final BookStatus status;
  final int? rating;
  final String? review;
  final SyncState syncState;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (author != null && author!.isNotEmpty) 'author': author,
    if (localCoverPath != null && localCoverPath!.isNotEmpty)
      'localCoverPath': localCoverPath,
    'status': status.name,
    if (rating != null) 'rating': rating,
    if (review != null && review!.isNotEmpty) 'review': review,
    'syncState': syncState.name,
  };

  factory BookEntry.fromJson(Map<String, dynamic> map) => BookEntry(
    id: _string(map, 'id'),
    title: _string(map, 'title'),
    author: map['author'] is String ? map['author'] as String : null,
    localCoverPath: map['localCoverPath'] is String
        ? map['localCoverPath'] as String
        : null,
    status: BookStatus.values.firstWhere(
      (value) => value.name == _string(map, 'status'),
      orElse: () => BookStatus.wantToRead,
    ),
    rating: map['rating'] is num ? (map['rating'] as num).toInt() : null,
    review: map['review'] is String ? map['review'] as String : null,
    syncState: SyncState.values.firstWhere(
      (value) => value.name == _string(map, 'syncState'),
      orElse: () => SyncState.synced,
    ),
  );
}

class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.originalUrl,
    required this.title,
    required this.siteHost,
    this.priceMinor,
    this.currency = 'BRL',
    this.localImagePath,
    this.status = WishlistStatus.wanted,
    this.note,
    this.syncState = SyncState.synced,
  });

  final String id;
  final String originalUrl;
  final String title;
  final String siteHost;
  final int? priceMinor;
  final String? currency;
  final String? localImagePath;
  final WishlistStatus status;
  final String? note;
  final SyncState syncState;

  WishlistItem copyWith({
    String? title,
    String? siteHost,
    int? priceMinor,
    bool clearPrice = false,
    String? currency,
    WishlistStatus? status,
    String? note,
    String? localImagePath,
    bool clearLocalImagePath = false,
  }) => WishlistItem(
    id: id,
    originalUrl: originalUrl,
    title: title ?? this.title,
    siteHost: siteHost ?? this.siteHost,
    priceMinor: clearPrice ? null : priceMinor ?? this.priceMinor,
    currency: clearPrice ? null : currency ?? this.currency,
    status: status ?? this.status,
    note: note ?? this.note,
    localImagePath: clearLocalImagePath
        ? null
        : localImagePath ?? this.localImagePath,
    syncState: SyncState.pending,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalUrl': originalUrl,
    'title': title,
    'siteHost': siteHost,
    if (priceMinor != null) 'priceMinor': priceMinor,
    if (currency != null) 'currency': currency,
    'status': status.name,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (localImagePath != null && localImagePath!.isNotEmpty)
      'localImagePath': localImagePath,
    'syncState': syncState.name,
  };

  factory WishlistItem.fromJson(Map<String, dynamic> map) => WishlistItem(
    id: _string(map, 'id'),
    originalUrl: _string(map, 'originalUrl'),
    title: _string(map, 'title', 'Sem título'),
    siteHost: _string(map, 'siteHost'),
    priceMinor: map['priceMinor'] is num
        ? (map['priceMinor'] as num).toInt()
        : null,
    currency: map['currency'] is String ? map['currency'] as String : null,
    status: WishlistStatus.values.firstWhere(
      (value) => value.name == _string(map, 'status'),
      orElse: () => WishlistStatus.wanted,
    ),
    note: map['note'] is String ? map['note'] as String : null,
    localImagePath: map['localImagePath'] is String
        ? map['localImagePath'] as String
        : null,
    syncState: SyncState.values.firstWhere(
      (value) => value.name == _string(map, 'syncState'),
      orElse: () => SyncState.synced,
    ),
  );
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = '1',
    this.note,
    this.isChecked = false,
  });

  final String id;
  final String name;
  final String quantity;
  final String? note;
  final bool isChecked;

  ShoppingItem copyWith({bool? isChecked}) => ShoppingItem(
    id: id,
    name: name,
    quantity: quantity,
    note: note,
    isChecked: isChecked ?? this.isChecked,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    if (note != null && note!.isNotEmpty) 'note': note,
    'isChecked': isChecked,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> map) => ShoppingItem(
    id: _string(map, 'id'),
    name: _string(map, 'name'),
    quantity: _string(map, 'quantity', '1'),
    note: map['note'] is String ? map['note'] as String : null,
    isChecked: map['isChecked'] == true,
  );
}

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    this.isAllDay = false,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;
}

class AppSnapshot {
  const AppSnapshot({
    required this.signedIn,
    required this.settings,
    required this.waterLogs,
    required this.bowelLogs,
    required this.exerciseLogs,
    required this.transactions,
    required this.gratitudeEntries,
    required this.books,
    required this.wishlistItems,
    required this.shoppingItems,
  });

  final bool signedIn;
  final UserSettings settings;
  final List<WaterLog> waterLogs;
  final List<BowelLog> bowelLogs;
  final List<ExerciseLog> exerciseLogs;
  final List<TransactionEntry> transactions;
  final List<GratitudeEntry> gratitudeEntries;
  final List<BookEntry> books;
  final List<WishlistItem> wishlistItems;
  final List<ShoppingItem> shoppingItems;

  Map<String, dynamic> toJson() => {
    'signedIn': signedIn,
    'settings': settings.toJson(),
    'waterLogs': waterLogs.map((item) => item.toJson()).toList(),
    'bowelLogs': bowelLogs.map((item) => item.toJson()).toList(),
    'exerciseLogs': exerciseLogs.map((item) => item.toJson()).toList(),
    'transactions': transactions.map((item) => item.toJson()).toList(),
    'gratitudeEntries': gratitudeEntries.map((item) => item.toJson()).toList(),
    'books': books.map((item) => item.toJson()).toList(),
    'wishlistItems': wishlistItems.map((item) => item.toJson()).toList(),
    'shoppingItems': shoppingItems.map((item) => item.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory AppSnapshot.fromJson(Map<String, dynamic> map) => AppSnapshot(
    signedIn: map['signedIn'] == true,
    settings: UserSettings.fromJson(
      map['settings'] is Map
          ? Map<String, dynamic>.from(map['settings'] as Map)
          : const {},
    ),
    waterLogs: _list(map, 'waterLogs', WaterLog.fromJson),
    bowelLogs: _list(map, 'bowelLogs', BowelLog.fromJson),
    exerciseLogs: _list(map, 'exerciseLogs', ExerciseLog.fromJson),
    transactions: _list(map, 'transactions', TransactionEntry.fromJson),
    gratitudeEntries: _list(map, 'gratitudeEntries', GratitudeEntry.fromJson),
    books: _list(map, 'books', BookEntry.fromJson),
    wishlistItems: _list(map, 'wishlistItems', WishlistItem.fromJson),
    shoppingItems: _list(map, 'shoppingItems', ShoppingItem.fromJson),
  );

  static List<T> _list<T>(
    Map<String, dynamic> map,
    String key,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = map[key];
    if (raw is! List) return <T>[];
    return raw
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList();
  }
}
