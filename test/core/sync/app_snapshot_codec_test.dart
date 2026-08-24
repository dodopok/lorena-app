import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/models.dart';
import 'package:lume/core/sync/app_snapshot_codec.dart';

void main() {
  final now = DateTime.utc(2026, 8, 24, 15, 30, 45);

  test('encodes the documented collections with audit fields', () {
    final snapshot = AppSnapshot(
      signedIn: true,
      settings: const UserSettings(
        waterGoalMl: 1800,
        rolloverMode: RolloverMode.positiveOnly,
        notificationsEnabled: true,
        calendarConnected: true,
      ),
      waterLogs: [
        WaterLog(
          id: 'water-1',
          amountMl: 300,
          occurredAt: now,
          localDate: '2026-08-24',
        ),
      ],
      bowelLogs: [
        BowelLog(
          id: 'bowel-1',
          occurredAt: now,
          localDate: '2026-08-24',
          note: 'Tudo bem',
        ),
      ],
      exerciseLogs: [
        ExerciseLog(
          id: 'exercise-1',
          activityType: 'Caminhada',
          durationMinutes: 20,
          occurredAt: now,
          localDate: '2026-08-24',
        ),
      ],
      transactions: [
        TransactionEntry(
          id: 'transaction-1',
          type: TransactionType.expense,
          amountMinor: 1250,
          occurredAt: now,
          period: '2026-08',
          category: 'lazer',
          description: 'Cinema',
        ),
      ],
      gratitudeEntries: [
        const GratitudeEntry(
          localDate: '2026-08-24',
          text: 'Um dia bonito',
          localImagePath: '/private/local/photo.jpg',
        ),
      ],
      books: [
        const BookEntry(
          id: 'book-1',
          title: 'O livro',
          localCoverPath: '/private/local/cover.jpg',
          status: BookStatus.read,
          rating: 5,
        ),
      ],
      wishlistItems: [
        const WishlistItem(
          id: 'wish-1',
          originalUrl: 'https://example.com/item',
          title: 'Um item',
          siteHost: 'example.com',
          localImagePath: '/private/local/wishlist.jpg',
        ),
      ],
      shoppingItems: [const ShoppingItem(id: 'shopping-1', name: 'Leite')],
    );

    final payload = AppSnapshotCodec.encode(snapshot, now: now);

    expect(payload.preferences['allowanceRolloverMode'], 'positive_only');
    expect(
      (payload.preferences['createdAt'] as Timestamp).toDate().toUtc(),
      now,
    );
    expect(payload.preferences['schemaVersion'], 1);
    expect(payload.exerciseSessions['exercise-1'], contains('startedAt'));
    expect(
      payload.transactions['transaction-1'],
      containsPair('currency', 'BRL'),
    );
    expect(
      payload.transactions['transaction-1'],
      containsPair('categoryId', 'lazer'),
    );
    expect(payload.shoppingItems['shopping-1'], containsPair('position', 0));
    expect(payload.shoppingList['name'], 'Compras');

    for (final collection in <Map<String, Map<String, dynamic>>?>[
      payload.waterLogs,
      payload.bowelLogs,
      payload.exerciseSessions,
      payload.transactions,
      payload.books,
      payload.gratitudeEntries,
      payload.wishlistItems,
      payload.shoppingItems,
    ]) {
      for (final document in collection!.values) {
        expect(document['createdAt'], isA<Timestamp>());
        expect(document['updatedAt'], isA<Timestamp>());
        expect(document['schemaVersion'], 1);
      }
    }

    expect(
      payload.gratitudeEntries['2026-08-24'],
      isNot(contains('localImagePath')),
    );
    expect(payload.books['book-1'], isNot(contains('localCoverPath')));
    expect(payload.wishlistItems['wish-1'], isNot(contains('localImagePath')));

    final mediaSnapshot = AppSnapshot(
      signedIn: true,
      settings: const UserSettings(),
      waterLogs: const [],
      bowelLogs: const [],
      exerciseLogs: const [],
      transactions: const [],
      gratitudeEntries: const [
        GratitudeEntry(
          localDate: '2026-08-24',
          text: '',
          remoteImagePaths: ['users/user-1/gratitude/2026-08-24/image.jpg'],
        ),
      ],
      books: const [
        BookEntry(
          id: 'book-remote',
          title: 'Livro remoto',
          remoteCoverPath: 'users/user-1/books/book-remote/image.jpg',
        ),
      ],
      wishlistItems: const [],
      shoppingItems: const [],
    );
    final mediaPayload = AppSnapshotCodec.encode(mediaSnapshot, now: now);
    expect(mediaPayload.gratitudeEntries['2026-08-24']!['images'], [
      'users/user-1/gratitude/2026-08-24/image.jpg',
    ]);
    expect(
      mediaPayload.books['book-remote']!['coverImage'],
      containsPair('storagePath', 'users/user-1/books/book-remote/image.jpg'),
    );
  });

  test(
    'decodes Timestamp, ISO values, ordering and absent collections safely',
    () {
      final timestamp = Timestamp.fromDate(now);
      final snapshot = AppSnapshotCodec.decode(
        RemoteSnapshotDocuments(
          preferences: {
            'waterGoalMl': 1600,
            'allowanceAmountMinor': 25000,
            'allowanceDayOfMonth': 5,
            'allowanceRolloverMode': 'none',
            'notificationPreferences': {'enabled': true},
            'calendarPreferences': {'connected': true},
          },
          waterLogs: {
            'water-1': {
              'amountMl': 250,
              'occurredAt': timestamp,
              'localDate': '2026-08-24',
            },
            'broken': {'amountMl': 200},
          },
          exerciseSessions: {
            'exercise-1': {
              'activityType': 'Yoga',
              'startedAt': now.toIso8601String(),
              'durationMinutes': 30,
            },
          },
          transactions: {
            'transaction-1': {
              'type': 'income',
              'amountMinor': 1000,
              'occurredAt': timestamp,
              'period': '2026-08',
              'categoryId': 'mesada',
            },
          },
          gratitudeEntries: {
            '2026-08-24': {
              'localDate': '2026-08-24',
              'text': 'Obrigada',
              'images': ['/remote/image.jpg'],
            },
          },
          books: {
            'book-1': {'title': 'Livro', 'status': 'want_to_read'},
          },
          wishlistItems: {
            'wish-1': {
              'originalUrl': 'https://example.com/item',
              'title': 'Item',
              'siteHost': 'example.com',
              'status': 'wanted',
            },
          },
          shoppingItems: {
            'second': {'name': 'Arroz', 'position': 2},
            'first': {'name': 'Feijão', 'position': 1},
          },
        ),
      );

      expect(snapshot.signedIn, isTrue);
      expect(snapshot.settings.waterGoalMl, 1600);
      expect(snapshot.settings.rolloverMode, RolloverMode.none);
      expect(snapshot.settings.notificationsEnabled, isTrue);
      expect(snapshot.settings.calendarConnected, isTrue);
      expect(snapshot.waterLogs, hasLength(1));
      expect(snapshot.waterLogs.single.occurredAt, now);
      expect(snapshot.exerciseLogs.single.occurredAt, now);
      expect(snapshot.transactions.single.category, 'mesada');
      expect(snapshot.books.single.status, BookStatus.wantToRead);
      expect(snapshot.shoppingItems.map((item) => item.name), [
        'Feijão',
        'Arroz',
      ]);
      expect(snapshot.gratitudeEntries.single.localImagePath, isNull);
      expect(snapshot.gratitudeEntries.single.remoteImagePaths, [
        '/remote/image.jpg',
      ]);
    },
  );

  test(
    'normalizes supported timestamp representations and rejects invalid data',
    () {
      expect(
        AppSnapshotCodec.dateTimeFromFirestore(now.toIso8601String()),
        now,
      );
      expect(
        AppSnapshotCodec.dateTimeFromFirestore(Timestamp.fromDate(now)),
        now,
      );
      expect(
        AppSnapshotCodec.dateTimeFromFirestore({
          'seconds': now.millisecondsSinceEpoch ~/ 1000,
          'nanoseconds': 0,
        }),
        now,
      );
      expect(AppSnapshotCodec.dateTimeFromFirestore('not-a-date'), isNull);
      expect(AppSnapshotCodec.timestampFromValue(null), isNull);
      expect(AppSnapshotCodec.isoFromFirestore(now), now.toIso8601String());
    },
  );
}
