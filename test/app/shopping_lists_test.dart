import 'package:flutter_test/flutter_test.dart';

import 'package:lume/app/models.dart';

void main() {
  test('modelos antigos migram itens para a lista Compras', () {
    final restored = AppSnapshot.fromJson({
      'signedIn': true,
      'settings': <String, dynamic>{},
      'waterLogs': <dynamic>[],
      'bowelLogs': <dynamic>[],
      'exerciseLogs': <dynamic>[],
      'transactions': <dynamic>[],
      'gratitudeEntries': <dynamic>[],
      'books': <dynamic>[],
      'wishlistItems': <dynamic>[],
      'shoppingItems': [
        {'id': 'item-1', 'name': 'Café'},
      ],
    });

    expect(restored.shoppingLists.single.id, defaultShoppingListId);
    expect(restored.shoppingLists.single.name, defaultShoppingListName);
    expect(restored.shoppingItems.single.listId, defaultShoppingListId);
  });

  test('listas nomeadas e links da agenda atravessam o cache local', () {
    final snapshot = AppSnapshot(
      signedIn: true,
      settings: const UserSettings(),
      waterLogs: const [],
      bowelLogs: const [],
      exerciseLogs: const [],
      transactions: const [],
      gratitudeEntries: const [],
      books: const [],
      wishlistItems: const [],
      shoppingLists: const [
        ShoppingListEntry(
          id: defaultShoppingListId,
          name: defaultShoppingListName,
        ),
        ShoppingListEntry(id: 'work', name: 'Trabalho'),
      ],
      shoppingItems: const [
        ShoppingItem(id: 'item-1', listId: 'work', name: 'Caderno'),
      ],
      calendarEvents: [
        CalendarEvent(
          id: 'event-1',
          title: 'Consulta',
          start: DateTime(2026, 8, 24, 10),
          end: DateTime(2026, 8, 24, 11),
          htmlLink: 'https://calendar.google.com/event?eid=1',
        ),
      ],
      activeShoppingListId: 'work',
    );

    final restored = AppSnapshot.fromJson(snapshot.toJson());
    expect(restored.shoppingLists.map((list) => list.id), ['default', 'work']);
    expect(restored.shoppingItems.single.listId, 'work');
    expect(restored.activeShoppingListId, 'work');
    expect(
      restored.calendarEvents.single.htmlLink,
      'https://calendar.google.com/event?eid=1',
    );
  });
}
