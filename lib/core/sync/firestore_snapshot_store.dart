import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/models.dart';
import 'app_snapshot_codec.dart';
import 'remote_snapshot_store.dart';

/// A single Firestore write operation, kept separate from the Firebase SDK so
/// the store can be tested without initializing Firebase.
class FirestoreWrite {
  const FirestoreWrite.set(this.path, this.data) : delete = false;

  const FirestoreWrite.delete(this.path) : data = null, delete = true;

  final String path;
  final Map<String, dynamic>? data;
  final bool delete;
}

/// Narrow Firestore boundary used by [FirestoreSnapshotStore].
///
/// The production adapter below uses regular Firestore reads and batches,
/// preserving the SDK's mobile offline persistence. Tests can inject a fake
/// implementation without touching Firebase platform channels.
abstract interface class FirestoreSnapshotBackend {
  Future<Map<String, dynamic>?> getDocument(String path);

  Future<Map<String, Map<String, dynamic>>> getCollection(String path);

  Future<void> commit(List<FirestoreWrite> writes);
}

class FirebaseFirestoreSnapshotBackend implements FirestoreSnapshotBackend {
  FirebaseFirestoreSnapshotBackend(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> getDocument(String path) async {
    final snapshot = await _firestore.doc(path).get();
    final data = snapshot.data();
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getCollection(String path) async {
    final snapshot = await _firestore.collection(path).get();
    return <String, Map<String, dynamic>>{
      for (final document in snapshot.docs)
        document.id: Map<String, dynamic>.from(document.data()),
    };
  }

  @override
  Future<void> commit(List<FirestoreWrite> writes) async {
    // Firestore limits a batch to 500 operations. Leave headroom for SDK or
    // future bookkeeping changes while keeping each batch atomic.
    const maxOperationsPerBatch = 450;
    for (var start = 0; start < writes.length; start += maxOperationsPerBatch) {
      final end = (start + maxOperationsPerBatch).clamp(0, writes.length);
      final batch = _firestore.batch();
      for (final write in writes.sublist(start, end)) {
        final reference = _firestore.doc(write.path);
        if (write.delete) {
          batch.delete(reference);
        } else {
          batch.set(reference, write.data!);
        }
      }
      await batch.commit();
    }
  }
}

/// Firestore-backed snapshot store for one authenticated Firebase UID.
///
/// No Firebase method is called by the constructor. Reads happen only from
/// [read] or [write]. [write] uses Firestore batches, which are queued by the
/// SDK while offline. A failed pre-read does not prevent that queueing; it only
/// disables stale-document deletion and createdAt preservation for that call.
class FirestoreSnapshotStore implements RemoteSnapshotStore {
  FirestoreSnapshotStore({
    required String uid,
    FirebaseFirestore? firestore,
    FirestoreSnapshotBackend? backend,
    DateTime Function()? clock,
  }) : _uid = _validateUid(uid),
       _backend = backend ?? _backendFor(firestore),
       _clock = clock ?? DateTime.now;

  final String _uid;
  final FirestoreSnapshotBackend _backend;
  final DateTime Function() _clock;

  String get uid => _uid;

  @override
  Future<AppSnapshot?> read() async {
    final documents = await _readDocuments();
    if (!documents.hasAnyDocument) return null;
    return AppSnapshotCodec.decode(documents);
  }

  @override
  Future<void> write(AppSnapshot snapshot) async {
    // This read is only for audit continuity and physical deletion of IDs no
    // longer present locally. It is deliberately best-effort so an offline
    // first write still reaches Firestore's persistent pending-write queue.
    RemoteSnapshotDocuments? existing;
    try {
      existing = await _readDocuments();
    } catch (_) {
      existing = null;
    }

    final updatedAt = _clock().toUtc();
    final payload = AppSnapshotCodec.encode(snapshot, now: updatedAt);
    final writes = <FirestoreWrite>[
      FirestoreWrite.set(
        _preferencesPath,
        _withExistingAudit(
          payload.preferences,
          existing?.preferences,
          updatedAt,
        ),
      ),
    ];

    final desiredLists = payload.shoppingLists.isEmpty
        ? <String, Map<String, dynamic>>{
            defaultShoppingListId: payload.shoppingList,
          }
        : payload.shoppingLists;
    final existingLists = _shoppingListDocuments(existing);
    _appendCollectionWrites(
      writes,
      collectionName: 'shopping_lists',
      desired: desiredLists,
      existing: existingLists,
      updatedAt: updatedAt,
    );

    _appendCollectionWrites(
      writes,
      collectionName: 'water_logs',
      desired: payload.waterLogs,
      existing: existing?.waterLogs,
      updatedAt: updatedAt,
    );
    _appendCollectionWrites(
      writes,
      collectionName: 'bowel_logs',
      desired: payload.bowelLogs,
      existing: existing?.bowelLogs,
      updatedAt: updatedAt,
    );
    _appendCollectionWrites(
      writes,
      collectionName: 'exercise_sessions',
      desired: payload.exerciseSessions,
      existing: existing?.exerciseSessions,
      updatedAt: updatedAt,
    );
    _appendCollectionWrites(
      writes,
      collectionName: 'transactions',
      desired: payload.transactions,
      existing: existing?.transactions,
      updatedAt: updatedAt,
    );
    _appendCollectionWrites(
      writes,
      collectionName: 'books',
      desired: payload.books,
      existing: existing?.books,
      updatedAt: updatedAt,
    );
    _appendCollectionWrites(
      writes,
      collectionName: 'gratitude_entries',
      desired: payload.gratitudeEntries,
      existing: existing?.gratitudeEntries,
      updatedAt: updatedAt,
    );
    _appendCollectionWrites(
      writes,
      collectionName: 'wishlist_items',
      desired: payload.wishlistItems,
      existing: existing?.wishlistItems,
      updatedAt: updatedAt,
    );
    final desiredItemsByList = _shoppingItemsByList(payload.shoppingItems);
    final existingItemsByList = _shoppingItemsByList(
      existing?.shoppingItems ?? const {},
    );
    final shoppingListIds = <String>{
      ...desiredItemsByList.keys,
      ...existingItemsByList.keys,
      ...desiredLists.keys,
      ...existingLists.keys,
    };
    for (final listId in shoppingListIds) {
      _appendCollectionWrites(
        writes,
        collectionName: 'shopping_lists/$listId/items',
        desired: desiredItemsByList[listId] ?? const {},
        existing: existingItemsByList[listId] ?? const {},
        updatedAt: updatedAt,
      );
    }

    await _backend.commit(writes);
  }

  @override
  Future<void> clear() async {
    final existing = await _readDocuments();
    final writes = <FirestoreWrite>[];
    if (existing.preferences != null) {
      writes.add(FirestoreWrite.delete(_preferencesPath));
    }
    _appendCollectionDeletes(
      writes,
      collectionName: 'shopping_lists',
      existing: _shoppingListDocuments(existing),
    );
    _appendCollectionDeletes(
      writes,
      collectionName: 'water_logs',
      existing: existing.waterLogs,
    );
    _appendCollectionDeletes(
      writes,
      collectionName: 'bowel_logs',
      existing: existing.bowelLogs,
    );
    _appendCollectionDeletes(
      writes,
      collectionName: 'exercise_sessions',
      existing: existing.exerciseSessions,
    );
    _appendCollectionDeletes(
      writes,
      collectionName: 'transactions',
      existing: existing.transactions,
    );
    _appendCollectionDeletes(
      writes,
      collectionName: 'books',
      existing: existing.books,
    );
    _appendCollectionDeletes(
      writes,
      collectionName: 'gratitude_entries',
      existing: existing.gratitudeEntries,
    );
    _appendCollectionDeletes(
      writes,
      collectionName: 'wishlist_items',
      existing: existing.wishlistItems,
    );
    final existingItemsByList = _shoppingItemsByList(existing.shoppingItems);
    for (final entry in existingItemsByList.entries) {
      _appendCollectionDeletes(
        writes,
        collectionName: 'shopping_lists/${entry.key}/items',
        existing: entry.value,
      );
    }
    if (writes.isNotEmpty) await _backend.commit(writes);
  }

  String get _userPath => 'users/$_uid';

  String get _preferencesPath => '$_userPath/settings/preferences';

  String _collectionPath(String collectionName) => '$_userPath/$collectionName';

  Future<RemoteSnapshotDocuments> _readDocuments() async {
    final results = await Future.wait<Object?>([
      _backend.getDocument(_preferencesPath),
      _backend.getCollection(_collectionPath('water_logs')),
      _backend.getCollection(_collectionPath('bowel_logs')),
      _backend.getCollection(_collectionPath('exercise_sessions')),
      _backend.getCollection(_collectionPath('transactions')),
      _backend.getCollection(_collectionPath('books')),
      _backend.getCollection(_collectionPath('gratitude_entries')),
      _backend.getCollection(_collectionPath('wishlist_items')),
      _backend.getCollection(_collectionPath('shopping_lists')),
    ]);

    final shoppingLists = _documentsAt(results[8]);
    final listIds = <String>{defaultShoppingListId, ...shoppingLists.keys};
    final itemCollections = await Future.wait(
      listIds.map(
        (listId) => _backend.getCollection(
          _collectionPath('shopping_lists/$listId/items'),
        ),
      ),
    );
    final shoppingItems = <String, Map<String, dynamic>>{};
    var collectionIndex = 0;
    for (final listId in listIds) {
      final documents = itemCollections[collectionIndex++];
      for (final entry in documents.entries) {
        shoppingItems[entry.key] = {
          ...entry.value,
          'listId': entry.value['listId'] is String
              ? entry.value['listId']
              : listId,
        };
      }
    }

    return RemoteSnapshotDocuments(
      preferences: results[0] as Map<String, dynamic>?,
      shoppingList: shoppingLists[defaultShoppingListId],
      shoppingLists: shoppingLists,
      waterLogs: _documentsAt(results[1]),
      bowelLogs: _documentsAt(results[2]),
      exerciseSessions: _documentsAt(results[3]),
      transactions: _documentsAt(results[4]),
      books: _documentsAt(results[5]),
      gratitudeEntries: _documentsAt(results[6]),
      wishlistItems: _documentsAt(results[7]),
      shoppingItems: shoppingItems,
    );
  }

  Map<String, Map<String, dynamic>> _shoppingListDocuments(
    RemoteSnapshotDocuments? documents,
  ) {
    if (documents == null) return const {};
    if (documents.shoppingLists.isNotEmpty) return documents.shoppingLists;
    final legacy = documents.shoppingList;
    return legacy == null
        ? const {}
        : <String, Map<String, dynamic>>{defaultShoppingListId: legacy};
  }

  Map<String, Map<String, Map<String, dynamic>>> _shoppingItemsByList(
    Map<String, Map<String, dynamic>> items,
  ) {
    final grouped = <String, Map<String, Map<String, dynamic>>>{};
    for (final entry in items.entries) {
      final rawListId = entry.value['listId'];
      final listId =
          rawListId is String &&
              rawListId.isNotEmpty &&
              !rawListId.contains('/')
          ? rawListId
          : defaultShoppingListId;
      grouped.putIfAbsent(listId, () => {})[entry.key] = entry.value;
    }
    return grouped;
  }

  void _appendCollectionWrites(
    List<FirestoreWrite> writes, {
    required String collectionName,
    required Map<String, Map<String, dynamic>> desired,
    required Map<String, Map<String, dynamic>>? existing,
    required DateTime updatedAt,
  }) {
    final collectionPath = _collectionPath(collectionName);
    for (final entry in desired.entries) {
      writes.add(
        FirestoreWrite.set(
          '$collectionPath/${entry.key}',
          _withExistingAudit(entry.value, existing?[entry.key], updatedAt),
        ),
      );
    }

    if (existing == null) return;
    for (final id in existing.keys) {
      if (!desired.containsKey(id)) {
        writes.add(FirestoreWrite.delete('$collectionPath/$id'));
      }
    }
  }

  void _appendCollectionDeletes(
    List<FirestoreWrite> writes, {
    required String collectionName,
    required Map<String, Map<String, dynamic>> existing,
  }) {
    final collectionPath = _collectionPath(collectionName);
    for (final id in existing.keys) {
      writes.add(FirestoreWrite.delete('$collectionPath/$id'));
    }
  }

  Map<String, dynamic> _withExistingAudit(
    Map<String, dynamic> data,
    Map<String, dynamic>? existing,
    DateTime updatedAt,
  ) => AppSnapshotCodec.withAudit(
    data,
    createdAt: AppSnapshotCodec.dateTimeFromFirestore(existing?['createdAt']),
    updatedAt: updatedAt,
  );

  static Map<String, Map<String, dynamic>> _documentsAt(Object? value) {
    if (value is! Map) return <String, Map<String, dynamic>>{};
    return <String, Map<String, dynamic>>{
      for (final entry in value.entries)
        if (entry.key is String && entry.value is Map)
          entry.key as String: Map<String, dynamic>.from(entry.value as Map),
    };
  }

  static FirestoreSnapshotBackend _backendFor(FirebaseFirestore? firestore) {
    if (firestore == null) {
      throw ArgumentError(
        'Provide FirebaseFirestore or a FirestoreSnapshotBackend.',
      );
    }
    return FirebaseFirestoreSnapshotBackend(firestore);
  }

  static String _validateUid(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(uid, 'uid', 'must be a non-empty path segment');
    }
    return normalized;
  }
}
