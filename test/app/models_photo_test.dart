import 'package:flutter_test/flutter_test.dart';

import 'package:lume/app/models.dart';

void main() {
  test('gratidão preserva caminho local e aceita foto sem texto', () {
    const entry = GratitudeEntry(
      localDate: '2026-08-24',
      text: '',
      localImagePath: '/support/lume_photos/gratitude/photo.jpg',
      syncState: SyncState.pending,
    );

    final restored = GratitudeEntry.fromJson(entry.toJson());
    expect(restored.text, isEmpty);
    expect(restored.localImagePath, entry.localImagePath);
    expect(restored.syncState, SyncState.pending);
  });

  test('livro preserva capa local e modelos antigos continuam compatíveis', () {
    const book = BookEntry(
      id: 'book-1',
      title: 'Livro',
      localCoverPath: '/support/lume_photos/bookCover/cover.png',
      syncState: SyncState.pending,
    );
    final restored = BookEntry.fromJson(book.toJson());
    expect(restored.localCoverPath, book.localCoverPath);
    expect(
      BookEntry.fromJson({'id': 'old', 'title': 'Sem capa'}).localCoverPath,
      isNull,
    );
  });

  test('wishlist preserva imagem local e não inclui campo quando ausente', () {
    const item = WishlistItem(
      id: 'wish-1',
      originalUrl: 'https://example.com/item',
      title: 'Item',
      siteHost: 'example.com',
      localImagePath: '/support/lume_photos/wishlist/item.jpg',
    );
    final json = item.toJson();
    expect(json['localImagePath'], item.localImagePath);
    expect(WishlistItem.fromJson(json).localImagePath, item.localImagePath);
    expect(
      WishlistItem(
        id: 'wish-2',
        originalUrl: 'https://example.com/item',
        title: 'Item',
        siteHost: 'example.com',
      ).toJson().containsKey('localImagePath'),
      isFalse,
    );
  });

  test(
    'cache local da Agenda preserva eventos e cursor sem ir para o domínio',
    () {
      final snapshot = AppSnapshot(
        signedIn: true,
        settings: const UserSettings(calendarConnected: true),
        waterLogs: const [],
        bowelLogs: const [],
        exerciseLogs: const [],
        transactions: const [],
        gratitudeEntries: const [],
        books: const [],
        wishlistItems: const [],
        shoppingItems: const [],
        calendarEvents: [
          CalendarEvent(
            id: 'event-1',
            title: 'Consulta',
            start: DateTime(2026, 8, 24, 10),
            end: DateTime(2026, 8, 24, 11),
          ),
        ],
        calendarSyncToken: 'sync-token',
        calendarLastSyncedAt: DateTime(2026, 8, 24, 12),
      );

      final restored = AppSnapshot.fromJson(snapshot.toJson());
      expect(restored.calendarEvents.single.id, 'event-1');
      expect(restored.calendarSyncToken, 'sync-token');
      expect(restored.calendarLastSyncedAt, DateTime(2026, 8, 24, 12));
    },
  );
}
