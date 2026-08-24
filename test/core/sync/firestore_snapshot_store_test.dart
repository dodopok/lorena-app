import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/models.dart';
import 'package:lume/core/sync/firestore_snapshot_store.dart';

void main() {
  final clock = DateTime.utc(2026, 8, 24, 16);

  test('does not call the backend while constructing the store', () {
    final backend = _FakeFirestoreBackend();

    FirestoreSnapshotStore(uid: 'user-1', backend: backend, clock: () => clock);

    expect(backend.readCount, 0);
    expect(backend.commitCount, 0);
  });

  test('reads a cached remote snapshot and returns null when empty', () async {
    final backend = _FakeFirestoreBackend();
    final emptyStore = FirestoreSnapshotStore(
      uid: 'user-empty',
      backend: backend,
    );
    expect(await emptyStore.read(), isNull);

    backend.documents['users/user-1/settings/preferences'] = {
      'waterGoalMl': 1500,
      'allowanceAmountMinor': 0,
      'allowanceDayOfMonth': 1,
      'allowanceRolloverMode': 'positive_only',
      'notificationPreferences': {'enabled': false},
      'calendarPreferences': {'connected': false},
    };
    backend.documents['users/user-1/water_logs/water-1'] = {
      'amountMl': 400,
      'occurredAt': Timestamp.fromDate(clock),
      'localDate': '2026-08-24',
    };

    final store = FirestoreSnapshotStore(uid: 'user-1', backend: backend);
    final snapshot = await store.read();

    expect(snapshot, isNotNull);
    expect(snapshot!.settings.waterGoalMl, 1500);
    expect(snapshot.waterLogs.single.amountMl, 400);
  });

  test(
    'writes documented paths, preserves createdAt and deletes stale IDs',
    () async {
      final backend = _FakeFirestoreBackend();
      final oldCreatedAt = DateTime.utc(2026, 8, 1);
      backend.documents['users/user-1/books/book-1'] = {
        'createdAt': Timestamp.fromDate(oldCreatedAt),
        'title': 'Antigo',
      };
      backend.documents['users/user-1/water_logs/stale'] = {
        'createdAt': Timestamp.fromDate(oldCreatedAt),
        'amountMl': 200,
      };

      final store = FirestoreSnapshotStore(
        uid: 'user-1',
        backend: backend,
        clock: () => clock,
      );
      await store.write(_snapshot());

      expect(backend.documents, contains('users/user-1/settings/preferences'));
      expect(
        backend.documents,
        contains('users/user-1/shopping_lists/default'),
      );
      expect(
        backend.documents,
        contains('users/user-1/shopping_lists/default/items/item-1'),
      );
      expect(backend.documents, contains('users/user-1/water_logs/water-1'));
      expect(
        backend.documents,
        isNot(contains('users/user-1/water_logs/stale')),
      );
      expect(
        (backend.documents['users/user-1/books/book-1']!['createdAt']
                as Timestamp)
            .toDate()
            .toUtc(),
        oldCreatedAt,
      );
      expect(
        (backend.documents['users/user-1/books/book-1']!['updatedAt']
                as Timestamp)
            .toDate()
            .toUtc(),
        clock,
      );

      final allWrites = backend.commits.expand((batch) => batch);
      expect(
        allWrites.any(
          (write) => write.delete && write.path.endsWith('/water_logs/stale'),
        ),
        isTrue,
      );
      for (final write in allWrites.where((write) => !write.delete)) {
        expect(_containsSensitiveKey(write.data), isFalse);
      }
    },
  );

  test(
    'still queues writes when the best-effort pre-read is offline',
    () async {
      final backend = _FakeFirestoreBackend()..failReads = true;
      final store = FirestoreSnapshotStore(
        uid: 'user-1',
        backend: backend,
        clock: () => clock,
      );

      await store.write(_snapshot());

      expect(backend.readCount, greaterThan(0));
      expect(backend.commitCount, 1);
      expect(backend.documents, contains('users/user-1/water_logs/water-1'));
      expect(
        backend.commits.expand((batch) => batch).where((write) => write.delete),
        isEmpty,
      );
    },
  );
}

AppSnapshot _snapshot() => AppSnapshot(
  signedIn: true,
  settings: const UserSettings(),
  waterLogs: [
    WaterLog(
      id: 'water-1',
      amountMl: 250,
      occurredAt: DateTime.utc(2026, 8, 24, 10),
      localDate: '2026-08-24',
    ),
  ],
  bowelLogs: const [],
  exerciseLogs: const [],
  transactions: const [],
  gratitudeEntries: const [],
  books: const [BookEntry(id: 'book-1', title: 'Novo livro')],
  wishlistItems: const [],
  shoppingItems: const [ShoppingItem(id: 'item-1', name: 'Café')],
);

bool _containsSensitiveKey(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().toLowerCase();
      if (key.contains('token') ||
          key.contains('localimagepath') ||
          key.contains('localcoverpath') ||
          key.contains('localpath')) {
        return true;
      }
      if (_containsSensitiveKey(entry.value)) return true;
    }
  }
  if (value is Iterable) {
    return value.any(_containsSensitiveKey);
  }
  return false;
}

class _FakeFirestoreBackend implements FirestoreSnapshotBackend {
  final Map<String, Map<String, dynamic>> documents = {};
  final List<List<FirestoreWrite>> commits = [];
  bool failReads = false;
  int readCount = 0;

  int get commitCount => commits.length;

  @override
  Future<Map<String, dynamic>?> getDocument(String path) async {
    readCount++;
    if (failReads) throw StateError('offline');
    final value = documents[path];
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getCollection(String path) async {
    readCount++;
    if (failReads) throw StateError('offline');
    final prefix = '$path/';
    return {
      for (final entry in documents.entries)
        if (entry.key.startsWith(prefix) &&
            !entry.key.substring(prefix.length).contains('/'))
          entry.key.substring(prefix.length): Map<String, dynamic>.from(
            entry.value,
          ),
    };
  }

  @override
  Future<void> commit(List<FirestoreWrite> writes) async {
    commits.add(List<FirestoreWrite>.from(writes));
    for (final write in writes) {
      if (write.delete) {
        documents.remove(write.path);
      } else {
        documents[write.path] = Map<String, dynamic>.from(write.data!);
      }
    }
  }
}
