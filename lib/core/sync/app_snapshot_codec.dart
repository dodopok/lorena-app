import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/models.dart';

const int currentSnapshotSchemaVersion = 1;

/// Firestore-shaped documents without any Firestore I/O.
///
/// Collection maps are keyed by document ID. The ID is deliberately kept out
/// of the document body because it is already the identity in the documented
/// Firestore path.
class RemoteSnapshotDocuments {
  const RemoteSnapshotDocuments({
    this.preferences,
    this.shoppingList,
    this.shoppingLists = const <String, Map<String, dynamic>>{},
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

  /// Legacy convenience field for the original single “Compras” document.
  final Map<String, dynamic>? shoppingList;
  final Map<String, Map<String, dynamic>> shoppingLists;
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
      shoppingLists.isNotEmpty ||
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
    this.shoppingLists = const <String, Map<String, dynamic>>{},
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

  /// Legacy convenience field for the original single “Compras” document.
  final Map<String, dynamic> shoppingList;
  final Map<String, Map<String, dynamic>> shoppingLists;
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
          if (item.bristolType != null) 'bristolType': item.bristolType,
          if (item.comfort != null) 'comfort': item.comfort!.name,
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
          if (item.intensity != null) 'intensity': item.intensity!.name,
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
          if (item.startedOn != null)
            'startedOn': timestampFromDate(item.startedOn!),
          if (item.finishedOn != null)
            'finishedOn': timestampFromDate(item.finishedOn!),
          if (item.rating != null) 'rating': item.rating,
          if (_nonEmpty(item.review) != null) 'review': item.review,
          if (_nonEmpty(item.isbn) != null) 'isbn': item.isbn,
          if (_nonEmpty(item.remoteCoverPath) != null)
            'coverImage': {'storagePath': item.remoteCoverPath},
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final gratitudeEntries = <String, Map<String, dynamic>>{};
    for (final item in snapshot.gratitudeEntries) {
      // A local path is intentionally not a remote image. The document is
      // valid while it has text or at least one uploaded Storage path.
      if (!_validId(item.localDate) ||
          (_nonEmpty(item.text) == null && item.remoteImagePaths.isEmpty)) {
        continue;
      }
      gratitudeEntries[item.localDate] = _withAudit(
        {
          'localDate': item.localDate,
          if (_nonEmpty(item.text) != null) 'text': item.text,
          if (item.remoteImagePaths.isNotEmpty)
            'images': List<String>.from(item.remoteImagePaths),
        },
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
          if (_nonEmpty(item.canonicalUrl) != null)
            'canonicalUrl': item.canonicalUrl,
          if (_nonEmpty(item.imageUrl) != null) 'imageUrl': item.imageUrl,
          if (item.priceMinor != null) 'priceMinor': item.priceMinor,
          if (_nonEmpty(item.currency) != null) 'currency': item.currency,
          'status': item.status.name,
          if (_nonEmpty(item.note) != null) 'note': item.note,
          'metadataSource': item.metadataSource.name,
          if (item.metadataFetchedAt != null)
            'metadataFetchedAt': timestampFromDate(item.metadataFetchedAt!),
          if (_nonEmpty(item.remoteImagePath) != null)
            'image': {'storagePath': item.remoteImagePath},
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final shoppingLists = <String, Map<String, dynamic>>{};
    for (final list in snapshot.shoppingLists) {
      if (!_validId(list.id) || _nonEmpty(list.name) == null) continue;
      shoppingLists[list.id] = _withAudit(
        {
          'name': list.name.trim(),
          if (list.archivedAt != null)
            'archivedAt': timestampFromDate(list.archivedAt!),
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }
    if (shoppingLists.isEmpty) {
      shoppingLists[defaultShoppingListId] = _withAudit(
        {'name': defaultShoppingListName},
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    final shoppingItems = <String, Map<String, dynamic>>{};
    final listPositions = <String, int>{};
    for (final item in snapshot.shoppingItems) {
      if (!_validId(item.id) || _nonEmpty(item.name) == null) continue;
      final listId = _validId(item.listId)
          ? item.listId
          : defaultShoppingListId;
      final fallbackPosition = listPositions[listId] ?? 0;
      final position = item.position == 0 && fallbackPosition > 0
          ? fallbackPosition
          : item.position;
      listPositions[listId] = position + 1;
      shoppingItems[item.id] = _withAudit(
        {
          'listId': listId,
          'name': item.name,
          'quantity': item.quantity,
          if (_nonEmpty(item.note) != null) 'note': item.note,
          'isChecked': item.isChecked,
          'position': position,
          if (item.estimatedPriceMinor != null)
            'estimatedPriceMinor': item.estimatedPriceMinor,
          if (item.checkedAt != null)
            'checkedAt': timestampFromDate(item.checkedAt!),
        },
        updatedAt: updatedAt,
        schemaVersion: schemaVersion,
      );
    }

    return FirestoreSnapshotPayload(
      preferences: preferences,
      shoppingList: shoppingLists[defaultShoppingListId]!,
      shoppingLists: shoppingLists,
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
      shoppingLists: _decodeShoppingLists(
        documents.shoppingLists,
        documents.shoppingList,
      ),
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
      ...settings.reminderPreferences.toJson(),
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
    if (notifications != null) {
      data['reminderPreferences'] = notifications;
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
    final bristolType = _boundedInt(entry.value['bristolType'], 1, 7);
    final comfort = _enumName(
      entry.value['comfort'],
      BowelComfort.values.map((value) => value.name),
    );
    return BowelLog.fromJson({
      'id': entry.key,
      'occurredAt': occurredAt,
      'localDate': _localDate(entry.value['localDate'], occurredAt),
      ..._optionalField('bristolType', bristolType),
      ..._optionalField('comfort', comfort),
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
    final intensity = _enumName(
      data['intensity'],
      ExerciseIntensity.values.map((value) => value.name),
    );
    return ExerciseLog.fromJson({
      'id': entry.key,
      'activityType': _nonEmpty(data['activityType']) ?? 'Movimento',
      'durationMinutes': duration,
      'occurredAt': startedAt,
      'localDate': _localDate(data['localDate'], startedAt),
      ..._optionalField('intensity', intensity),
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
    final images = data['images'] is List
        ? (data['images'] as List).whereType<String>().toList()
        : const <String>[];
    if (localDate == null || (text == null && images.isEmpty)) return null;
    return GratitudeEntry(
      localDate: localDate,
      text: text ?? '',
      remoteImagePaths: images,
      mediaSyncState: images.isEmpty
          ? MediaSyncState.local
          : MediaSyncState.uploaded,
    );
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
    final coverImage = _map(data['coverImage']);
    final coverPath = _nonEmpty(coverImage?['storagePath']);
    final startedOn = isoFromFirestore(data['startedOn']);
    final finishedOn = isoFromFirestore(data['finishedOn']);
    final isbn = _nonEmpty(data['isbn']);
    return BookEntry.fromJson({
      'id': entry.key,
      'title': title,
      ..._optionalField('author', author),
      'status': _bookStatusToDomain(data['status']),
      ..._optionalField('remoteCoverPath', coverPath),
      ..._optionalField('startedOn', startedOn),
      ..._optionalField('finishedOn', finishedOn),
      ..._optionalField('rating', rating),
      ..._optionalField('review', review),
      ..._optionalField('isbn', isbn),
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
    final canonicalUrl = _safeHttpUrl(data['canonicalUrl']);
    final imageUrl = _safeHttpUrl(data['imageUrl']);
    final priceMinor = _nonNegativeInt(data['priceMinor']);
    final currency = _nonEmpty(data['currency']);
    final note = _nonEmpty(data['note']);
    final image = _map(data['image']);
    final imagePath = _nonEmpty(image?['storagePath']);
    return WishlistItem.fromJson({
      'id': entry.key,
      'originalUrl': originalUrl,
      'title': title,
      'siteHost': siteHost,
      ..._optionalField('canonicalUrl', canonicalUrl),
      ..._optionalField('imageUrl', imageUrl),
      ..._optionalField('priceMinor', priceMinor),
      ..._optionalField('currency', currency),
      'status': data['status'],
      ..._optionalField('note', note),
      'metadataSource': _metadataSourceToDomain(data['metadataSource']),
      ..._optionalField(
        'metadataFetchedAt',
        isoFromFirestore(data['metadataFetchedAt']),
      ),
      ..._optionalField('remoteImagePath', imagePath),
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

  static List<ShoppingListEntry> _decodeShoppingLists(
    Map<String, Map<String, dynamic>> documents,
    Map<String, dynamic>? legacyDefault,
  ) {
    final source = <String, Map<String, dynamic>>{
      ...documents,
      if (documents.isEmpty && legacyDefault != null)
        defaultShoppingListId: legacyDefault,
    };
    final decoded = source.entries
        .map((entry) {
          final name = _nonEmpty(entry.value['name']);
          if (!_validId(entry.key) || name == null) return null;
          return ShoppingListEntry(
            id: entry.key,
            name: name,
            createdAt: dateTimeFromFirestore(entry.value['createdAt']),
            updatedAt: dateTimeFromFirestore(entry.value['updatedAt']),
            archivedAt: dateTimeFromFirestore(entry.value['archivedAt']),
          );
        })
        .whereType<ShoppingListEntry>()
        .toList();
    if (decoded.isEmpty) {
      return const [
        ShoppingListEntry(
          id: defaultShoppingListId,
          name: defaultShoppingListName,
        ),
      ];
    }
    if (!decoded.any((list) => list.id == defaultShoppingListId)) {
      decoded.insert(
        0,
        const ShoppingListEntry(
          id: defaultShoppingListId,
          name: defaultShoppingListName,
        ),
      );
    }
    return decoded;
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
    final listId = _nonEmpty(data['listId']);
    return ShoppingItem.fromJson({
      'id': entry.key,
      'listId': listId != null && _validId(listId)
          ? listId
          : defaultShoppingListId,
      'name': name,
      'quantity': quantity,
      ..._optionalField('note', note),
      'isChecked': data['isChecked'] == true,
      ..._optionalField(
        'estimatedPriceMinor',
        _nonNegativeInt(data['estimatedPriceMinor']),
      ),
      'position': _intValue(data['position']) ?? 0,
      ..._optionalField('checkedAt', isoFromFirestore(data['checkedAt'])),
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

  static String _metadataSourceToDomain(Object? value) => switch (value) {
    'jsonLd' || 'json_ld' => 'jsonLd',
    'openGraph' || 'open_graph' => 'openGraph',
    _ => 'manual',
  };

  static String? _safeHttpUrl(Object? raw) {
    if (raw is! String) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.port != 0 && uri.port != 80 && uri.port != 443)) {
      return null;
    }
    return uri.toString();
  }

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

  static String? _enumName(Object? value, Iterable<String> allowed) {
    if (value is! String || !allowed.contains(value)) return null;
    return value;
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
