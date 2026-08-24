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
}
