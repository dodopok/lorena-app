import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/models.dart';

const int currentSnapshotSchemaVersion = 1;
const String defaultShoppingListId = 'default';

/// Firestore-shaped documents without any Firestore I/O.
///
/// Collection maps are keyed by document ID. The ID is deliberately kept out
/// of the document body because it is already the identity in the documented
/// Firestore path.
class RemoteSnapshotDocuments {
  const RemoteSnapshotDocuments({
    this.preferences,
    this.shoppingList,
    this.waterLogs = const <String, Map<String, dynamic>>{},
    this.bowelLogs = const <String, Map<String, dynamic>>{},
    this.exerciseSessions = const <String, Map<String, dynamic>>{},
    this.transactions = const <String, Map<String, dynamic>>{},
    this.books = const <String, Map<String, dynamic>>{},
    this.gratitudeEntries = const <String, Map<String, dynamic>>{},
    this.wishlistItems = const <String, Map<String, dynamic>>{},
    this.shoppingItems = const <String, Map<String, dynamic>>{},
  });

  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? shoppingList;
  final Map<String, Map<String, dynamic>> waterLogs;
  final Map<String, Map<String, dynamic>> bowelLogs;
  final Map<String, Map<String, dynamic>> exerciseSessions;
  final Map<String, Map<String, dynamic>> transactions;
  final Map<String, Map<String, dynamic>> books;
  final Map<String, Map<String, dynamic>> gratitudeEntries;
  final Map<String, Map<String, dynamic>> wishlistItems;
  final Map<String, Map<String, dynamic>> shoppingItems;

  bool get hasAnyDocument =>
      preferences != null ||
      shoppingList != null ||
      waterLogs.isNotEmpty ||
      bowelLogs.isNotEmpty ||
      exerciseSessions.isNotEmpty ||
      transactions.isNotEmpty ||
      books.isNotEmpty ||
      gratitudeEntries.isNotEmpty ||
      wishlistItems.isNotEmpty ||
      shoppingItems.isNotEmpty;
}

/// Result of encoding an [AppSnapshot] into the documented remote shape.
class FirestoreSnapshotPayload {
  const FirestoreSnapshotPayload({
    required this.preferences,
    required this.shoppingList,
    required this.waterLogs,
    required this.bowelLogs,
    required this.exerciseSessions,
    required this.transactions,
    required this.books,
    required this.gratitudeEntries,
    required this.wishlistItems,
    required this.shoppingItems,
  });

  final Map<String, dynamic> preferences;
  final Map<String, dynamic> shoppingList;
  final Map<String, Map<String, dynamic>> waterLogs;
  final Map<String, Map<String, dynamic>> bowelLogs;
  final Map<String, Map<String, dynamic>> exerciseSessions;
  final Map<String, Map<String, dynamic>> transactions;
  final Map<String, Map<String, dynamic>> books;
  final Map<String, Map<String, dynamic>> gratitudeEntries;
  final Map<String, Map<String, dynamic>> wishlistItems;
  final Map<String, Map<String, dynamic>> shoppingItems;
}

/// Pure mapping between the app's current models and the documented
/// Firestore schema.
///
/// Domain models use ISO strings. Firestore receives real [Timestamp] values,
/// and the decoder accepts Timestamp, ISO strings, DateTime, epoch numbers,
/// and serialized `{seconds, nanoseconds}` values so older/cache-shaped data
/// does not make a whole snapshot unreadable.
class AppSnapshotCodec {
  const AppSnapshotCodec._();

  static FirestoreSnapshotPayload encode(
    AppSnapshot snapshot, {
    required DateTime now,
    int schemaVersion = currentSnapshotSchemaVersion,
  }) {
    final updatedAt = now.toUtc();
    final preferences = _withAudit(
      _encodePreferences(snapshot.settings),
      updatedAt: updatedAt,
      schemaVersion: schemaVersion,
    );

    final waterLogs = <String, Map<String, dynamic>>{};
    for (final item in snapshot.waterLogs) {
      if (!_validId(item.id) || item.amountMl <= 0) continue;
      waterLogs[item.id] = _withAudit(
        {
          'amountMl': item.amountMl,
          'occurredAt': timestampFromDate(item.occurredAt),
          'localDate': item.localDate,
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final bowelLogs = <String, Map<String, dynamic>>{};
    for (final item in snapshot.bowelLogs) {
      if (!_validId(item.id)) continue;
      bowelLogs[item.id] = _withAudit(
        {
          'occurredAt': timestampFromDate(item.occurredAt),
          'localDate': item.localDate,
          if (_nonEmpty(item.note) != null) 'note': item.note,
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final exerciseSessions = <String, Map<String, dynamic>>{};
    for (final item in snapshot.exerciseLogs) {
      if (!_validId(item.id) || item.durationMinutes <= 0) continue;
      exerciseSessions[item.id] = _withAudit(
        {
          'activityType': item.activityType,
          'startedAt': timestampFromDate(item.occurredAt),
          'localDate': item.localDate,
          'durationMinutes': item.durationMinutes,
          if (_nonEmpty(item.note) != null) 'note': item.note,
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final transactions = <String, Map<String, dynamic>>{};
    for (final item in snapshot.transactions) {
      if (!_validId(item.id) || item.amountMinor <= 0) continue;
      transactions[item.id] = _withAudit(
        {
          'type': item.type.name,
          'amountMinor': item.amountMinor,
          'currency': 'BRL',
          'occurredAt': timestampFromDate(item.occurredAt),
          'localDate': _localDateFor(item.occurredAt),
          'period': item.period,
          'categoryId': item.category,
          if (_nonEmpty(item.description) != null)
            'description': item.description,
          if (_nonEmpty(item.note) != null) 'note': item.note,
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final books = <String, Map<String, dynamic>>{};
    for (final item in snapshot.books) {
      if (!_validId(item.id) || _nonEmpty(item.title) == null) continue;
      books[item.id] = _withAudit(
        {
          'title': item.title,
          if (_nonEmpty(item.author) != null) 'author': item.author,
          'status': _bookStatusToRemote(item.status),
          if (item.rating != null) 'rating': item.rating,
          if (_nonEmpty(item.review) != null) 'review': item.review,
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final gratitudeEntries = <String, Map<String, dynamic>>{};
    for (final item in snapshot.gratitudeEntries) {
      // A local path is intentionally not a remote image. Without text or an
      // uploaded image, writing this document would violate the Firestore
      // invariant documented for gratitude entries.
      if (!_validId(item.localDate) || _nonEmpty(item.text) == null) continue;
      gratitudeEntries[item.localDate] = _withAudit(
        {'localDate': item.localDate, 'text': item.text},
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final wishlistItems = <String, Map<String, dynamic>>{};
    for (final item in snapshot.wishlistItems) {
      if (!_validId(item.id) || _nonEmpty(item.originalUrl) == null) continue;
      wishlistItems[item.id] = _withAudit(
        {
          'originalUrl': item.originalUrl,
          'title': item.title,
          'siteHost': item.siteHost,
          if (item.priceMinor != null) 'priceMinor': item.priceMinor,
          if (_nonEmpty(item.currency) != null) 'currency': item.currency,
          'status': item.status.name,
          if (_nonEmpty(item.note) != null) 'note': item.note,
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final shoppingItems = <String, Map<String, dynamic>>{};
    for (var index = 0; index < snapshot.shoppingItems.length; index++) {
      final item = snapshot.shoppingItems[index];
      if (!_validId(item.id) || _nonEmpty(item.name) == null) continue;
      shoppingItems[item.id] = _withAudit(
        {
          'name': item.name,
          'quantity': item.quantity,
          if (_nonEmpty(item.note) != null) 'note': item.note,
          'isChecked': item.isChecked,
          'position': index,
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    return FirestoreSnapshotPayload(
      preferences: preferences,
      shoppingList: _withAudit(
        {'name': 'Compras'},
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      ),
      waterLogs: waterLogs,
      bowelLogs: bowelLogs,
      exerciseSessions: exerciseSessions,
      transactions: transactions,
      books: books,
      gratitudeEntries: gratitudeEntries,
      wishlistItems: wishlistItems,
      shoppingItems: shoppingItems,
    );
  }

  static AppSnapshot decode(RemoteSnapshotDocuments documents) {
    return AppSnapshot(
      // The remote document is scoped to the authenticated UID. Session
      // state itself is never persisted in Firestore.
      signedIn: true,
      settings: UserSettings.fromJson(
        _decodePreferences(documents.preferences),
      ),
      waterLogs: _decodeWaterLogs(documents.waterLogs),
      bowelLogs: _decodeBowelLogs(documents.bowelLogs),
      exerciseLogs: _decodeExerciseLogs(documents.exerciseSessions),
      transactions: _decodeTransactions(documents.transactions),
      gratitudeEntries: _decodeGratitudeEntries(documents.gratitudeEntries),
      books: _decodeBooks(documents.books),
      wishlistItems: _decodeWishlistItems(documents.wishlistItems),
      shoppingItems: _decodeShoppingItems(documents.shoppingItems),
    );
  }

  /// Adds/normalizes audit fields without mutating [data].
  static Map<String, dynamic> withAudit(
    Map<String, dynamic> data, {
    required DateTime updatedAt,
    DateTime? createdAt,
    int schemaVersion = currentSnapshotSchemaVersion,
  }) {
    return <String, dynamic>{
      ...data,
      'createdAt': timestampFromDate((createdAt ?? updatedAt).toUtc()),
      'updatedAt': timestampFromDate(updatedAt.toUtc()),
      'schemaVersion': schemaVersion,
    };
  }

  static Timestamp timestampFromDate(DateTime value) =>
      Timestamp.fromDate(value.toUtc());

  static Timestamp? timestampFromValue(Object? value) {
    final date = dateTimeFromFirestore(value);
    return date == null ? null : timestampFromDate(date);
  }

  static String? isoFromFirestore(Object? value) {
    final date = dateTimeFromFirestore(value);
    return date?.toIso8601String();
  }

  static DateTime? dateTimeFromFirestore(Object? value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } on FormatException {
        return null;
      }
    }
    if (value is num && value.isFinite) {
      final number = value.toDouble();
      // Accept both milliseconds and Unix seconds for imported/cache data.
      final milliseconds = number.abs() < 100000000000
          ? (number * 1000).round()
          : number.round();
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    }
    if (value is Map) {
      final seconds = _number(value['seconds'] ?? value['_seconds']);
      final nanoseconds = _number(
        value['nanoseconds'] ?? value['_nanoseconds'],
      );
      if (seconds == null) return null;
      final milliseconds = seconds * 1000 + (nanoseconds ?? 0) / 1000000;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds.round(),
        isUtc: true,
      );
    }
    return null;
  }

  static Map<String, dynamic> _encodePreferences(UserSettings settings) => {
    'waterGoalMl': settings.waterGoalMl,
    'quickWaterAmountsMl': List<int>.from(settings.quickWaterAmountsMl),
    'allowanceAmountMinor': settings.allowanceAmountMinor,
    'allowanceDayOfMonth': settings.allowanceDayOfMonth,
    'allowanceRolloverMode': _rolloverModeToRemote(settings.rolloverMode),
    'biometricLockEnabled': settings.biometricLockEnabled,
    'notificationPreferences': <String, dynamic>{
      'enabled': settings.notificationsEnabled,
    },
    'calendarPreferences': <String, dynamic>{
      'connected': settings.calendarConnected,
    },
  };

  static Map<String, dynamic> _decodePreferences(Map<String, dynamic>? remote) {
    final data = <String, dynamic>{...?remote};
    final rollover = data['allowanceRolloverMode'];
    if (rollover is String) {
      data['rolloverMode'] = _rolloverModeToDomain(rollover);
    }

    final notifications = _map(data['notificationPreferences']);
    if (notifications != null && notifications['enabled'] is bool) {
      data['notificationsEnabled'] = notifications['enabled'];
    }

    final calendar = _map(data['calendarPreferences']);
    if (calendar != null && calendar['connected'] is bool) {
      data['calendarConnected'] = calendar['connected'];
    }
    return data;
  }

  static List<WaterLog> _decodeWaterLogs(
    Map<String, Map<String, dynamic>> documents,
  ) => documents.entries.map(_decodeWaterLog).whereType<WaterLog>().toList();

  static WaterLog? _decodeWaterLog(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final data = entry.value;
    final occurredAt = isoFromFirestore(data['occurredAt']);
    final amountMl = _positiveInt(data['amountMl']);
    if (!_validId(entry.key) || occurredAt == null || amountMl == null) {
      return null;
    }
    return WaterLog.fromJson({
      'id': entry.key,
      'amountMl': amountMl,
      'occurredAt': occurredAt,
      'localDate': _localDate(data['localDate'], occurredAt),
    });
  }

  static List<BowelLog> _decodeBowelLogs(
    Map<String, Map<String, dynamic>> documents,
  ) => documents.entries.map(_decodeBowelLog).whereType<BowelLog>().toList();

  static BowelLog? _decodeBowelLog(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final occurredAt = isoFromFirestore(entry.value['occurredAt']);
    if (!_validId(entry.key) || occurredAt == null) return null;
    final note = _nonEmpty(entry.value['note']);
    return BowelLog.fromJson({
      'id': entry.key,
      'occurredAt': occurredAt,
      'localDate': _localDate(entry.value['localDate'], occurredAt),
      ..._optionalField('note', note),
    });
  }

  static List<ExerciseLog> _decodeExerciseLogs(
    Map<String, Map<String, dynamic>> documents,
  ) => documents.entries
      .map(_decodeExerciseLog)
      .whereType<ExerciseLog>()
      .toList();

  static ExerciseLog? _decodeExerciseLog(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final data = entry.value;
    final startedAt = isoFromFirestore(data['startedAt'] ?? data['occurredAt']);
    final duration = _positiveInt(data['durationMinutes']);
    if (!_validId(entry.key) || startedAt == null || duration == null) {
      return null;
    }
    final note = _nonEmpty(data['note']);
    return ExerciseLog.fromJson({
      'id': entry.key,
      'activityType': _nonEmpty(data['activityType']) ?? 'Movimento',
      'durationMinutes': duration,
      'occurredAt': startedAt,
      'localDate': _localDate(data['localDate'], startedAt),
      ..._optionalField('note', note),
    });
  }

  static List<TransactionEntry> _decodeTransactions(
    Map<String, Map<String, dynamic>> documents,
  ) => documents.entries
      .map(_decodeTransaction)
      .whereType<TransactionEntry>()
      .toList();

  static TransactionEntry? _decodeTransaction(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final data = entry.value;
    final occurredAt = isoFromFirestore(data['occurredAt']);
    final amountMinor = _positiveInt(data['amountMinor']);
    final period = _nonEmpty(data['period']);
    if (!_validId(entry.key) ||
        occurredAt == null ||
        amountMinor == null ||
        period == null) {
      return null;
    }
    final category = _nonEmpty(data['categoryId'] ?? data['category']);
    final description = _nonEmpty(data['description']);
    final note = _nonEmpty(data['note']);
    return TransactionEntry.fromJson({
      'id': entry.key,
      'type': _transactionTypeToDomain(data['type']),
      'amountMinor': amountMinor,
      'occurredAt': occurredAt,
      'period': period,
      ..._optionalField('category', category),
      ..._optionalField('description', description),
      ..._optionalField('note', note),
    });
  }

  static List<GratitudeEntry> _decodeGratitudeEntries(
    Map<String, Map<String, dynamic>> documents,
  ) => documents.entries
      .map(_decodeGratitudeEntry)
      .whereType<GratitudeEntry>()
      .toList();

  static GratitudeEntry? _decodeGratitudeEntry(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final data = entry.value;
    final localDate = _nonEmpty(data['localDate']) ?? _nonEmpty(entry.key);
    final text = _nonEmpty(data['text']);
    // Remote image URLs are intentionally not copied into localImagePath.
    if (localDate == null || text == null) return null;
    return GratitudeEntry(localDate: localDate, text: text);
  }

  static List<BookEntry> _decodeBooks(
    Map<String, Map<String, dynamic>> documents,
  ) => documents.entries.map(_decodeBook).whereType<BookEntry>().toList();

  static BookEntry? _decodeBook(MapEntry<String, Map<String, dynamic>> entry) {
    final data = entry.value;
    final title = _nonEmpty(data['title']);
    if (!_validId(entry.key) || title == null) return null;
    final rating = _boundedInt(data['rating'], 1, 5);
    final author = _nonEmpty(data['author']);
    final review = _nonEmpty(data['review']);
    return BookEntry.fromJson({
      'id': entry.key,
      'title': title,
      ..._optionalField('author', author),
      'status': _bookStatusToDomain(data['status']),
      ..._optionalField('rating', rating),
      ..._optionalField('review', review),
    });
  }

  static List<WishlistItem> _decodeWishlistItems(
    Map<String, Map<String, dynamic>> documents,
  ) => documents.entries
      .map(_decodeWishlistItem)
      .whereType<WishlistItem>()
      .toList();

  static WishlistItem? _decodeWishlistItem(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final data = entry.value;
    final originalUrl = _nonEmpty(data['originalUrl']);
    if (!_validId(entry.key) || originalUrl == null) return null;
    final title = _nonEmpty(data['title']) ?? 'Sem título';
    final siteHost = _nonEmpty(data['siteHost']) ?? '';
    final priceMinor = _nonNegativeInt(data['priceMinor']);
    final currency = _nonEmpty(data['currency']);
    final note = _nonEmpty(data['note']);
    return WishlistItem.fromJson({
      'id': entry.key,
      'originalUrl': originalUrl,
      'title': title,
      'siteHost': siteHost,
      ..._optionalField('priceMinor', priceMinor),
      ..._optionalField('currency', currency),
      'status': data['status'],
      ..._optionalField('note', note),
    });
  }

  static List<ShoppingItem> _decodeShoppingItems(
    Map<String, Map<String, dynamic>> documents,
  ) {
    final entries = documents.entries.toList()
      ..sort((left, right) {
        final leftPosition = _intOrMax(left.value['position']);
        final rightPosition = _intOrMax(right.value['position']);
        final byPosition = leftPosition.compareTo(rightPosition);
        return byPosition == 0 ? left.key.compareTo(right.key) : byPosition;
      });
    return entries.map(_decodeShoppingItem).whereType<ShoppingItem>().toList();
  }

  static ShoppingItem? _decodeShoppingItem(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final data = entry.value;
    final name = _nonEmpty(data['name']);
    if (!_validId(entry.key) || name == null) return null;
    final rawQuantity = data['quantity'];
    final quantity = rawQuantity is String
        ? rawQuantity
        : rawQuantity is num
        ? rawQuantity.toString()
        : '1';
    final note = _nonEmpty(data['note']);
    return ShoppingItem.fromJson({
      'id': entry.key,
      'name': name,
      'quantity': quantity,
      ..._optionalField('note', note),
      'isChecked': data['isChecked'] == true,
    });
  }

  static Map<String, dynamic> _withAudit(
    Map<String, dynamic> data, {
    required DateTime updatedAt,
    required int schemaVersion,
  }) => withAudit(data, updatedAt: updatedAt, schemaVersion: schemaVersion);

  static String _rolloverModeToRemote(RolloverMode value) => switch (value) {
    RolloverMode.none => 'none',
    RolloverMode.positiveOnly => 'positive_only',
  };

  static String _rolloverModeToDomain(String value) => switch (value) {
    'positive_only' => 'positiveOnly',
    _ => 'none',
  };

  static String _bookStatusToRemote(BookStatus value) => switch (value) {
    BookStatus.wantToRead => 'want_to_read',
    BookStatus.reading => 'reading',
    BookStatus.read => 'read',
    BookStatus.abandoned => 'abandoned',
  };

  static String _bookStatusToDomain(Object? value) => switch (value) {
    'want_to_read' => 'wantToRead',
    'wantToRead' => 'wantToRead',
    'reading' => 'reading',
    'read' => 'read',
    'abandoned' => 'abandoned',
    _ => 'wantToRead',
  };

  static String _transactionTypeToDomain(Object? value) => switch (value) {
    'allowance' => 'allowance',
    'income' => 'income',
    'adjustment' => 'adjustment',
    _ => 'expense',
  };

  static String _localDate(Object? raw, String isoDate) {
    final value = _nonEmpty(raw);
    if (value != null) return value;
    return isoDate.length >= 10 ? isoDate.substring(0, 10) : isoDate;
  }

  static String _localDateFor(DateTime value) =>
      value.toUtc().toIso8601String().substring(0, 10);

  static Map<String, dynamic>? _map(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static Map<String, dynamic> _optionalField(String key, Object? value) =>
      value == null ? const <String, dynamic>{} : <String, dynamic>{key: value};

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : value;
  }

  static int? _positiveInt(Object? value) {
    final parsed = _intValue(value);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _nonNegativeInt(Object? value) {
    final parsed = _intValue(value);
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  static int? _boundedInt(Object? value, int min, int max) {
    final parsed = _intValue(value);
    return parsed != null && parsed >= min && parsed <= max ? parsed : null;
  }

  static int? _intValue(Object? value) =>
      value is num && value.isFinite ? value.toInt() : null;

  static int _intOrMax(Object? value) => _intValue(value) ?? 0x7fffffff;

  static num? _number(Object? value) =>
      value is num && value.isFinite ? value : null;

  static bool _validId(String value) =>
      value.trim().isNotEmpty && !value.contains('/');
}
