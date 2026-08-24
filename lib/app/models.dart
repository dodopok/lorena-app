import 'dart:convert';

enum TransactionType { allowance, income, expense, adjustment }

enum BookStatus { wantToRead, reading, read, abandoned }

enum RolloverMode { none, positiveOnly }

enum WishlistStatus { wanted, purchased, archived }

enum SyncState { synced, pending, offline, conflict }

enum BowelComfort { comfortable, neutral, uncomfortable }

enum ExerciseIntensity { light, moderate, intense }

enum MediaSyncState { local, pending, uploaded, failed, removed }

String _string(Map<String, dynamic> map, String key, [String fallback = '']) =>
    map[key] is String ? map[key] as String : fallback;

int _int(Map<String, dynamic> map, String key, [int fallback = 0]) =>
    map[key] is num ? (map[key] as num).toInt() : fallback;

DateTime _date(Map<String, dynamic> map, String key, [DateTime? fallback]) =>
    DateTime.tryParse(_string(map, key)) ?? fallback ?? DateTime.now();

DateTime? _optionalDate(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

class ReminderPreferences {
  const ReminderPreferences({
    this.waterTimes = const [],
    this.exerciseWeekdays = const [],
    this.exerciseTime = '18:00',
    this.gratitudeTime = '21:00',
    this.allowanceTime = '09:00',
  });

  final List<String> waterTimes;
  final List<int> exerciseWeekdays;
  final String exerciseTime;
  final String gratitudeTime;
  final String allowanceTime;

  ReminderPreferences copyWith({
    List<String>? waterTimes,
    List<int>? exerciseWeekdays,
    String? exerciseTime,
    String? gratitudeTime,
    String? allowanceTime,
  }) => ReminderPreferences(
    waterTimes: waterTimes ?? this.waterTimes,
    exerciseWeekdays: exerciseWeekdays ?? this.exerciseWeekdays,
    exerciseTime: exerciseTime ?? this.exerciseTime,
    gratitudeTime: gratitudeTime ?? this.gratitudeTime,
    allowanceTime: allowanceTime ?? this.allowanceTime,
  );

  Map<String, dynamic> toJson() => {
    'waterTimes': List<String>.from(waterTimes),
    'exerciseWeekdays': List<int>.from(exerciseWeekdays),
    'exerciseTime': exerciseTime,
    'gratitudeTime': gratitudeTime,
    'allowanceTime': allowanceTime,
  };

  factory ReminderPreferences.fromJson(Map<String, dynamic> map) {
    final times = map['waterTimes'] is List
        ? (map['waterTimes'] as List)
              .whereType<String>()
              .where(_validClockTime)
              .take(6)
              .toList()
        : const <String>[];
    final weekdays = map['exerciseWeekdays'] is List
        ? (map['exerciseWeekdays'] as List)
              .whereType<num>()
              .map((value) => value.toInt())
              .where((value) => value >= 1 && value <= 7)
              .toSet()
              .toList()
        : const <int>[];
    return ReminderPreferences(
      waterTimes: times,
      exerciseWeekdays: weekdays,
      exerciseTime: _clockTime(map['exerciseTime'], '18:00'),
      gratitudeTime: _clockTime(map['gratitudeTime'], '21:00'),
      allowanceTime: _clockTime(map['allowanceTime'], '09:00'),
    );
  }
}

bool _validClockTime(String value) =>
    RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value);

String _clockTime(Object? value, String fallback) =>
    value is String && _validClockTime(value) ? value : fallback;

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
    this.reminderPreferences = const ReminderPreferences(),
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
  final ReminderPreferences reminderPreferences;
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
    ReminderPreferences? reminderPreferences,
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
      reminderPreferences: reminderPreferences ?? this.reminderPreferences,
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
    'reminderPreferences': reminderPreferences.toJson(),
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
    reminderPreferences: ReminderPreferences.fromJson(
      map['reminderPreferences'] is Map
          ? Map<String, dynamic>.from(map['reminderPreferences'] as Map)
          : const {},
    ),
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

  WaterLog copyWith({
    int? amountMl,
    DateTime? occurredAt,
    String? localDate,
    SyncState? syncState,
  }) => WaterLog(
    id: id,
    amountMl: amountMl ?? this.amountMl,
    occurredAt: occurredAt ?? this.occurredAt,
    localDate: localDate ?? this.localDate,
    syncState: syncState ?? SyncState.pending,
  );

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
    this.bristolType,
    this.comfort,
    this.note,
    this.syncState = SyncState.synced,
  });

  final String id;
  final DateTime occurredAt;
  final String localDate;
  final int? bristolType;
  final BowelComfort? comfort;
  final String? note;
  final SyncState syncState;

  BowelLog copyWith({
    DateTime? occurredAt,
    String? localDate,
    int? bristolType,
    bool clearBristolType = false,
    BowelComfort? comfort,
    bool clearComfort = false,
    String? note,
    bool clearNote = false,
    SyncState? syncState,
  }) => BowelLog(
    id: id,
    occurredAt: occurredAt ?? this.occurredAt,
    localDate: localDate ?? this.localDate,
    bristolType: clearBristolType ? null : bristolType ?? this.bristolType,
    comfort: clearComfort ? null : comfort ?? this.comfort,
    note: clearNote ? null : note ?? this.note,
    syncState: syncState ?? SyncState.pending,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'occurredAt': occurredAt.toIso8601String(),
    'localDate': localDate,
    if (bristolType != null) 'bristolType': bristolType,
    if (comfort != null) 'comfort': comfort!.name,
    if (note != null && note!.isNotEmpty) 'note': note,
    'syncState': syncState.name,
  };

  factory BowelLog.fromJson(Map<String, dynamic> map) => BowelLog(
    id: _string(map, 'id'),
    occurredAt: _date(map, 'occurredAt'),
    localDate: _string(map, 'localDate'),
    bristolType: map['bristolType'] is num
        ? (map['bristolType'] as num).toInt()
        : null,
    comfort:
        BowelComfort.values
                .firstWhere(
                  (value) => value.name == _string(map, 'comfort'),
                  orElse: () => BowelComfort.neutral,
                )
                .name ==
            _string(map, 'comfort')
        ? BowelComfort.values.firstWhere(
            (value) => value.name == _string(map, 'comfort'),
            orElse: () => BowelComfort.neutral,
          )
        : null,
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
    this.intensity,
    this.note,
    this.syncState = SyncState.synced,
  });

  final String id;
  final String activityType;
  final int durationMinutes;
  final DateTime occurredAt;
  final String localDate;
  final ExerciseIntensity? intensity;
  final String? note;
  final SyncState syncState;

  ExerciseLog copyWith({
    String? activityType,
    int? durationMinutes,
    DateTime? occurredAt,
    String? localDate,
    ExerciseIntensity? intensity,
    bool clearIntensity = false,
    String? note,
    bool clearNote = false,
    SyncState? syncState,
  }) => ExerciseLog(
    id: id,
    activityType: activityType ?? this.activityType,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    occurredAt: occurredAt ?? this.occurredAt,
    localDate: localDate ?? this.localDate,
    intensity: clearIntensity ? null : intensity ?? this.intensity,
    note: clearNote ? null : note ?? this.note,
    syncState: syncState ?? SyncState.pending,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityType': activityType,
    'durationMinutes': durationMinutes,
    'occurredAt': occurredAt.toIso8601String(),
    'localDate': localDate,
    if (intensity != null) 'intensity': intensity!.name,
    if (note != null && note!.isNotEmpty) 'note': note,
    'syncState': syncState.name,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> map) => ExerciseLog(
    id: _string(map, 'id'),
    activityType: _string(map, 'activityType', 'Movimento'),
    durationMinutes: _int(map, 'durationMinutes'),
    occurredAt: _date(map, 'occurredAt'),
    localDate: _string(map, 'localDate'),
    intensity:
        ExerciseIntensity.values
                .firstWhere(
                  (value) => value.name == _string(map, 'intensity'),
                  orElse: () => ExerciseIntensity.light,
                )
                .name ==
            _string(map, 'intensity')
        ? ExerciseIntensity.values.firstWhere(
            (value) => value.name == _string(map, 'intensity'),
            orElse: () => ExerciseIntensity.light,
          )
        : null,
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
    this.remoteImagePaths = const [],
    this.mediaSyncState = MediaSyncState.local,
    this.syncState = SyncState.synced,
  });

  final String localDate;
  final String text;
  final String? localImagePath;
  final List<String> remoteImagePaths;
  final MediaSyncState mediaSyncState;
  final SyncState syncState;

  GratitudeEntry copyWith({
    String? text,
    String? localImagePath,
    bool clearLocalImagePath = false,
    List<String>? remoteImagePaths,
    MediaSyncState? mediaSyncState,
    SyncState? syncState,
  }) => GratitudeEntry(
    localDate: localDate,
    text: text ?? this.text,
    localImagePath: clearLocalImagePath
        ? null
        : localImagePath ?? this.localImagePath,
    remoteImagePaths: remoteImagePaths ?? this.remoteImagePaths,
    mediaSyncState: mediaSyncState ?? this.mediaSyncState,
    syncState: syncState ?? SyncState.pending,
  );

  Map<String, dynamic> toJson() => {
    'localDate': localDate,
    'text': text,
    if (localImagePath != null && localImagePath!.isNotEmpty)
      'localImagePath': localImagePath,
    if (remoteImagePaths.isNotEmpty) 'remoteImagePaths': remoteImagePaths,
    'mediaSyncState': mediaSyncState.name,
    'syncState': syncState.name,
  };

  factory GratitudeEntry.fromJson(Map<String, dynamic> map) => GratitudeEntry(
    localDate: _string(map, 'localDate'),
    text: _string(map, 'text'),
    localImagePath: map['localImagePath'] is String
        ? map['localImagePath'] as String
        : null,
    remoteImagePaths: map['remoteImagePaths'] is List
        ? (map['remoteImagePaths'] as List).whereType<String>().toList()
        : const [],
    mediaSyncState: MediaSyncState.values.firstWhere(
      (value) => value.name == _string(map, 'mediaSyncState'),
      orElse: () => MediaSyncState.local,
    ),
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
    this.remoteCoverPath,
    this.status = BookStatus.wantToRead,
    this.startedOn,
    this.finishedOn,
    this.rating,
    this.review,
    this.isbn,
    this.mediaSyncState = MediaSyncState.local,
    this.syncState = SyncState.synced,
  });

  final String id;
  final String title;
  final String? author;
  final String? localCoverPath;
  final String? remoteCoverPath;
  final BookStatus status;
  final DateTime? startedOn;
  final DateTime? finishedOn;
  final int? rating;
  final String? review;
  final String? isbn;
  final MediaSyncState mediaSyncState;
  final SyncState syncState;

  BookEntry copyWith({
    String? title,
    String? author,
    bool clearAuthor = false,
    String? localCoverPath,
    bool clearLocalCoverPath = false,
    String? remoteCoverPath,
    bool clearRemoteCoverPath = false,
    BookStatus? status,
    DateTime? startedOn,
    bool clearStartedOn = false,
    DateTime? finishedOn,
    bool clearFinishedOn = false,
    int? rating,
    bool clearRating = false,
    String? review,
    bool clearReview = false,
    String? isbn,
    bool clearIsbn = false,
    MediaSyncState? mediaSyncState,
    SyncState? syncState,
  }) => BookEntry(
    id: id,
    title: title ?? this.title,
    author: clearAuthor ? null : author ?? this.author,
    localCoverPath: clearLocalCoverPath
        ? null
        : localCoverPath ?? this.localCoverPath,
    remoteCoverPath: clearRemoteCoverPath
        ? null
        : remoteCoverPath ?? this.remoteCoverPath,
    status: status ?? this.status,
    startedOn: clearStartedOn ? null : startedOn ?? this.startedOn,
    finishedOn: clearFinishedOn ? null : finishedOn ?? this.finishedOn,
    rating: clearRating ? null : rating ?? this.rating,
    review: clearReview ? null : review ?? this.review,
    isbn: clearIsbn ? null : isbn ?? this.isbn,
    mediaSyncState: mediaSyncState ?? this.mediaSyncState,
    syncState: syncState ?? SyncState.pending,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (author != null && author!.isNotEmpty) 'author': author,
    if (localCoverPath != null && localCoverPath!.isNotEmpty)
      'localCoverPath': localCoverPath,
    if (remoteCoverPath != null && remoteCoverPath!.isNotEmpty)
      'remoteCoverPath': remoteCoverPath,
    'status': status.name,
    if (startedOn != null) 'startedOn': startedOn!.toIso8601String(),
    if (finishedOn != null) 'finishedOn': finishedOn!.toIso8601String(),
    if (rating != null) 'rating': rating,
    if (review != null && review!.isNotEmpty) 'review': review,
    if (isbn != null && isbn!.isNotEmpty) 'isbn': isbn,
    'mediaSyncState': mediaSyncState.name,
    'syncState': syncState.name,
  };

  factory BookEntry.fromJson(Map<String, dynamic> map) => BookEntry(
    id: _string(map, 'id'),
    title: _string(map, 'title'),
    author: map['author'] is String ? map['author'] as String : null,
    localCoverPath: map['localCoverPath'] is String
        ? map['localCoverPath'] as String
        : null,
    remoteCoverPath: map['remoteCoverPath'] is String
        ? map['remoteCoverPath'] as String
        : null,
    status: BookStatus.values.firstWhere(
      (value) => value.name == _string(map, 'status'),
      orElse: () => BookStatus.wantToRead,
    ),
    startedOn: _optionalDate(map, 'startedOn'),
    finishedOn: _optionalDate(map, 'finishedOn'),
    rating: map['rating'] is num ? (map['rating'] as num).toInt() : null,
    review: map['review'] is String ? map['review'] as String : null,
    isbn: map['isbn'] is String ? map['isbn'] as String : null,
    mediaSyncState: MediaSyncState.values.firstWhere(
      (value) => value.name == _string(map, 'mediaSyncState'),
      orElse: () => MediaSyncState.local,
    ),
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
    this.remoteImagePath,
    this.status = WishlistStatus.wanted,
    this.note,
    this.mediaSyncState = MediaSyncState.local,
    this.syncState = SyncState.synced,
  });

  final String id;
  final String originalUrl;
  final String title;
  final String siteHost;
  final int? priceMinor;
  final String? currency;
  final String? localImagePath;
  final String? remoteImagePath;
  final WishlistStatus status;
  final String? note;
  final MediaSyncState mediaSyncState;
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
    String? remoteImagePath,
    bool clearRemoteImagePath = false,
    MediaSyncState? mediaSyncState,
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
    remoteImagePath: clearRemoteImagePath
        ? null
        : remoteImagePath ?? this.remoteImagePath,
    mediaSyncState: mediaSyncState ?? this.mediaSyncState,
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
    if (remoteImagePath != null && remoteImagePath!.isNotEmpty)
      'remoteImagePath': remoteImagePath,
    'mediaSyncState': mediaSyncState.name,
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
    remoteImagePath: map['remoteImagePath'] is String
        ? map['remoteImagePath'] as String
        : null,
    mediaSyncState: MediaSyncState.values.firstWhere(
      (value) => value.name == _string(map, 'mediaSyncState'),
      orElse: () => MediaSyncState.local,
    ),
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
    this.estimatedPriceMinor,
    this.position = 0,
    this.checkedAt,
  });

  final String id;
  final String name;
  final String quantity;
  final String? note;
  final bool isChecked;
  final int? estimatedPriceMinor;
  final int position;
  final DateTime? checkedAt;

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    String? note,
    bool? isChecked,
    int? estimatedPriceMinor,
    bool clearEstimatedPrice = false,
    int? position,
    DateTime? checkedAt,
    bool clearCheckedAt = false,
  }) => ShoppingItem(
    id: id,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    note: note ?? this.note,
    isChecked: isChecked ?? this.isChecked,
    estimatedPriceMinor: clearEstimatedPrice
        ? null
        : estimatedPriceMinor ?? this.estimatedPriceMinor,
    position: position ?? this.position,
    checkedAt: clearCheckedAt ? null : checkedAt ?? this.checkedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    if (note != null && note!.isNotEmpty) 'note': note,
    'isChecked': isChecked,
    if (estimatedPriceMinor != null) 'estimatedPriceMinor': estimatedPriceMinor,
    'position': position,
    if (checkedAt != null) 'checkedAt': checkedAt!.toIso8601String(),
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> map) => ShoppingItem(
    id: _string(map, 'id'),
    name: _string(map, 'name'),
    quantity: _string(map, 'quantity', '1'),
    note: map['note'] is String ? map['note'] as String : null,
    isChecked: map['isChecked'] == true,
    estimatedPriceMinor: map['estimatedPriceMinor'] is num
        ? (map['estimatedPriceMinor'] as num).toInt()
        : null,
    position: _int(map, 'position'),
    checkedAt: _optionalDate(map, 'checkedAt'),
  );
}

class CalendarEvent {
  const CalendarEvent({
    this.id,
    this.calendarId = 'primary',
    required this.title,
    required this.start,
    required this.end,
    this.isAllDay = false,
    this.description,
    this.colorId,
    this.etag,
    this.recurrence = const [],
    this.reminderMinutes = const [],
  });

  final String? id;
  final String calendarId;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;
  final String? description;
  final String? colorId;
  final String? etag;
  final List<String> recurrence;
  final List<int> reminderMinutes;

  CalendarEvent copyWith({
    String? id,
    String? calendarId,
    String? title,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
    String? description,
    bool clearDescription = false,
    String? colorId,
    bool clearColorId = false,
    String? etag,
    List<String>? recurrence,
    List<int>? reminderMinutes,
  }) => CalendarEvent(
    id: id ?? this.id,
    calendarId: calendarId ?? this.calendarId,
    title: title ?? this.title,
    start: start ?? this.start,
    end: end ?? this.end,
    isAllDay: isAllDay ?? this.isAllDay,
    description: clearDescription ? null : description ?? this.description,
    colorId: clearColorId ? null : colorId ?? this.colorId,
    etag: etag ?? this.etag,
    recurrence: recurrence ?? this.recurrence,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'calendarId': calendarId,
    'title': title,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'isAllDay': isAllDay,
    if (description != null && description!.isNotEmpty)
      'description': description,
    if (colorId != null && colorId!.isNotEmpty) 'colorId': colorId,
    if (etag != null && etag!.isNotEmpty) 'etag': etag,
    if (recurrence.isNotEmpty) 'recurrence': recurrence,
    if (reminderMinutes.isNotEmpty) 'reminderMinutes': reminderMinutes,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> map) => CalendarEvent(
    id: map['id'] is String ? map['id'] as String : null,
    calendarId: _string(map, 'calendarId', 'primary'),
    title: _string(map, 'title', 'Sem título'),
    start: _date(map, 'start'),
    end: _date(map, 'end'),
    isAllDay: map['isAllDay'] == true,
    description: map['description'] is String
        ? map['description'] as String
        : null,
    colorId: map['colorId'] is String ? map['colorId'] as String : null,
    etag: map['etag'] is String ? map['etag'] as String : null,
    recurrence: map['recurrence'] is List
        ? (map['recurrence'] as List).whereType<String>().toList()
        : const [],
    reminderMinutes: map['reminderMinutes'] is List
        ? (map['reminderMinutes'] as List)
              .whereType<num>()
              .map((value) => value.toInt())
              .where((value) => value >= 0)
              .toList()
        : const [],
  );
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
    this.calendarEvents = const [],
    this.calendarSyncToken,
    this.calendarLastSyncedAt,
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
  final List<CalendarEvent> calendarEvents;

  /// Calendar integration state is local-only. It is deliberately not part
  /// of the Firestore snapshot codec because Google cache tokens must not be
  /// synced to the Lume backend.
  final String? calendarSyncToken;
  final DateTime? calendarLastSyncedAt;

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
    'calendarEvents': calendarEvents.map((item) => item.toJson()).toList(),
    if (calendarSyncToken != null) 'calendarSyncToken': calendarSyncToken,
    if (calendarLastSyncedAt != null)
      'calendarLastSyncedAt': calendarLastSyncedAt!.toIso8601String(),
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
    calendarEvents: _list(map, 'calendarEvents', CalendarEvent.fromJson),
    calendarSyncToken: map['calendarSyncToken'] is String
        ? map['calendarSyncToken'] as String
        : null,
    calendarLastSyncedAt: _optionalDate(map, 'calendarLastSyncedAt'),
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
