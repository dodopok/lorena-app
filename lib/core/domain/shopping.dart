class ShoppingList {
  ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.archivedAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toUtc() {
    if (id.trim().isEmpty || userId.trim().isEmpty || name.trim().isEmpty)
      throw ArgumentError('lista precisa de id, usuário e nome');
  }
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.userId,
    required this.listId,
    required this.name,
    this.quantity,
    this.note,
    this.estimatedPriceMinor,
    this.currency,
    this.isChecked = false,
    required this.position,
    this.checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toUtc() {
    if (id.trim().isEmpty ||
        userId.trim().isEmpty ||
        listId.trim().isEmpty ||
        name.trim().isEmpty)
      throw ArgumentError('item incompleto');
    if (position < 0) throw ArgumentError.value(position, 'position');
    if (estimatedPriceMinor != null && estimatedPriceMinor! < 0)
      throw ArgumentError.value(estimatedPriceMinor, 'estimatedPriceMinor');
    if (estimatedPriceMinor != null &&
        (currency == null || currency!.trim().isEmpty))
      throw ArgumentError('preço estimado precisa de moeda');
    if (estimatedPriceMinor == null && currency != null)
      throw ArgumentError('moeda sem preço é inválida');
  }
  final String id;
  final String userId;
  final String listId;
  final String name;
  final String? quantity;
  final String? note;
  final int? estimatedPriceMinor;
  final String? currency;
  final bool isChecked;
  final int position;
  final DateTime? checkedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingItem toggled({DateTime? at}) => ShoppingItem(
    id: id,
    userId: userId,
    listId: listId,
    name: name,
    quantity: quantity,
    note: note,
    estimatedPriceMinor: estimatedPriceMinor,
    currency: currency,
    isChecked: !isChecked,
    position: position,
    checkedAt: !isChecked ? (at ?? DateTime.now().toUtc()) : null,
    createdAt: createdAt,
    updatedAt: at ?? DateTime.now().toUtc(),
  );
}

List<ShoppingItem> orderedShoppingItems(Iterable<ShoppingItem> items) =>
    items.toList()..sort((a, b) => a.position.compareTo(b.position));
