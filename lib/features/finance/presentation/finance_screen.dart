import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_controller.dart';
import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/theme.dart' as app_theme;
import '../../../app/ui.dart' as app_ui;
import '../../../core/photos/local_photo_service.dart';
import '../../../core/widgets/lume_widgets.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _categoryFilter;
  String? _handledSharedUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sharedUrl = AppScope.of(context).pendingSharedUrl;
    final rawUrl = sharedUrl?.toString();
    if (rawUrl == null || rawUrl == _handledSharedUrl) return;
    _handledSharedUrl = rawUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _showWishlist(context, initialUrl: rawUrl);
      } finally {
        if (mounted) {
          AppScope.read(context).clearPendingSharedUrl(sharedUrl);
          _handledSharedUrl = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final period = controller.periodFor(_selectedMonth);
    final allEntries = controller.transactionsFor(period);
    final entries = _categoryFilter == null
        ? allEntries
        : allEntries
              .where((entry) => entry.category == _categoryFilter)
              .toList();
    final wishlist = controller.wishlistItems
        .where((item) => item.status != WishlistStatus.archived)
        .toList();
    final shoppingLists = controller.shoppingLists
        .where((list) => !list.isArchived)
        .toList();
    final activeShoppingList = controller.activeShoppingList;
    final shopping = controller.shoppingItemsFor(activeShoppingList.id);
    return app_ui.LumePage(
      title: 'Finanças',
      subtitle: 'Seu dinheiro com clareza e sem julgamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LumeMoneySummaryCard(
            periodLabel: _monthLabel(_selectedMonth),
            balanceMinor: controller.balanceFor(period),
            currency: 'BRL',
            incomeMinor: controller.incomeFor(period),
            expenseMinor: controller.expensesFor(period),
            rolloverMinor: controller.rolloverFor(period),
          ),
          const SizedBox(height: 8),
          _MonthPicker(
            month: _selectedMonth,
            onPrevious: () => setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
              );
              _categoryFilter = null;
            }),
            onNext: () => setState(() {
              _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
              _categoryFilter = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _showTransaction(context, TransactionType.expense),
                  icon: const Icon(Icons.remove),
                  label: const Text('Novo gasto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showTransaction(context, TransactionType.income),
                  icon: const Icon(Icons.add),
                  label: const Text('Entrada'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LumeSectionHeader(
            title: 'Lançamentos de ${_monthLabel(_selectedMonth)}',
            actionLabel: allEntries.isEmpty
                ? null
                : _categoryFilter == null
                ? 'Filtrar'
                : '$_categoryFilter ×',
            onAction: allEntries.isEmpty ? null : () => _showFilters(context),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            LumeCard(
              child: LumeEmptyState(
                illustration: const Icon(Icons.receipt_long_outlined, size: 40),
                title: allEntries.isEmpty
                    ? 'Nenhum lançamento neste mês'
                    : 'Nenhum lançamento nesta categoria',
                description: allEntries.isEmpty
                    ? 'Registre o primeiro gasto ou entrada para acompanhar o mês.'
                    : 'Escolha outra categoria ou limpe o filtro para ver os demais lançamentos.',
                primaryAction: LumeButton(
                  label: 'Registrar gasto',
                  onPressed: () =>
                      _showTransaction(context, TransactionType.expense),
                ),
              ),
            )
          else
            LumeCard(
              child: Column(
                children: entries
                    .map(
                      (entry) => _TransactionRow(
                        entry: entry,
                        controller: controller,
                        onEdit: () => _showTransaction(
                          context,
                          entry.type,
                          existing: entry,
                        ),
                        onDelete: () => _deleteTransaction(context, entry),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 28),
          LumeSectionHeader(
            title: 'Lista de compras',
            actionLabel: 'Adicionar item',
            onAction: () => _showShoppingItem(context),
          ),
          const SizedBox(height: 8),
          LumeCard(
            tone: LumeCardTone.finance,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: activeShoppingList.id,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: shoppingLists
                        .map(
                          (list) => DropdownMenuItem<String>(
                            value: list.id,
                            child: Text(list.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        AppScope.read(context).selectShoppingList(value);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Nova lista',
                  onPressed: () => _showShoppingList(context),
                  icon: const Icon(Icons.playlist_add),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opções da lista',
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showShoppingList(context, existing: activeShoppingList);
                    } else if (value == 'delete') {
                      _deleteShoppingList(context, activeShoppingList);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Renomear lista'),
                    ),
                    if (activeShoppingList.id != defaultShoppingListId)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir lista'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LumeCard(
            tone: LumeCardTone.finance,
            child: shopping.isEmpty
                ? const Text(
                    'Uma lista simples para não precisar guardar tudo na cabeça.',
                  )
                : Column(
                    children: [
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: shopping.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          final reordered = [...shopping];
                          final item = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, item);
                          controller.reorderShoppingItems(
                            reordered.map((item) => item.id).toList(),
                          );
                        },
                        itemBuilder: (context, index) {
                          final item = shopping[index];
                          return _ShoppingRow(
                            key: ValueKey(item.id),
                            item: item,
                            controller: controller,
                            onToggle: () =>
                                controller.toggleShoppingItem(item.id),
                            onEdit: () =>
                                _showShoppingItem(context, existing: item),
                            onDelete: () => _deleteShoppingItem(context, item),
                          );
                        },
                      ),
                      if (shopping.any((item) => item.isChecked))
                        TextButton.icon(
                          onPressed: () =>
                              _clearCompletedShopping(context, controller),
                          icon: const Icon(Icons.cleaning_services_outlined),
                          label: const Text('Limpar concluídos'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 28),
          LumeSectionHeader(
            title: 'Desejos',
            actionLabel: 'Adicionar',
            onAction: () => _showWishlist(context),
          ),
          const SizedBox(height: 8),
          if (wishlist.isEmpty)
            LumeCard(
              tone: LumeCardTone.corner,
              child: LumeEmptyState(
                illustration: const Icon(Icons.favorite_border, size: 40),
                title: 'Nenhum desejo salvo',
                description:
                    'Cole uma URL, revise os detalhes e guarde para depois.',
                primaryAction: LumeButton(
                  label: 'Salvar um desejo',
                  onPressed: () => _showWishlist(context),
                ),
              ),
            )
          else
            LumeCard(
              tone: LumeCardTone.corner,
              child: Column(
                children: wishlist.map((item) {
                  return _WishlistRow(
                    item: item,
                    controller: controller,
                    onStatusChanged: (status) =>
                        controller.updateWishlistStatus(item.id, status),
                    onEdit: () => _showWishlist(context, existing: item),
                    onOpen: () => _openWishlist(context, item),
                    onDelete: () => _deleteWishlist(context, item),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _showTransaction(
    BuildContext context,
    TransactionType initialType, {
    TransactionEntry? existing,
  }) async {
    final controller = AppScope.read(context);
    final amount = TextEditingController(
      text: existing == null
          ? ''
          : (existing.amountMinor / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
    );
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    final category = TextEditingController(
      text:
          existing?.category ??
          (initialType == TransactionType.expense ? 'Outros' : 'Receita'),
    );
    final note = TextEditingController(text: existing?.note ?? '');
    var type = existing?.type ?? initialType;
    var occurredAt = existing?.occurredAt ?? _selectedMonth;
    var saving = false;
    await app_ui.showLumeSheet(
      context,
      title: existing == null
          ? (initialType == TransactionType.expense
                ? 'Novo gasto'
                : 'Nova entrada')
          : 'Editar lançamento',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Gasto'),
                  icon: Icon(Icons.remove),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Entrada'),
                  icon: Icon(Icons.add),
                ),
              ],
              selected: {type},
              onSelectionChanged: (value) =>
                  setSheetState(() => type = value.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: r'R$ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: occurredAt,
                        );
                        if (picked != null && context.mounted) {
                          setSheetState(
                            () => occurredAt = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              occurredAt.hour,
                              occurredAt.minute,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.event_outlined),
                label: Text('Data: ${_shortDate(occurredAt)}'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final minor = _parseMoney(amount.text);
                        if (minor == null ||
                            minor <= 0 ||
                            description.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe valor e descrição.'),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        try {
                          if (existing == null) {
                            await controller.addTransaction(
                              type: type,
                              amountMinor: minor,
                              category: category.text,
                              description: description.text,
                              at: occurredAt,
                              note: note.text,
                            );
                          } else {
                            await controller.updateTransaction(
                              id: existing.id,
                              type: type,
                              amountMinor: minor,
                              category: category.text,
                              description: description.text,
                              at: occurredAt,
                              note: note.text,
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } on ArgumentError catch (error) {
                          if (!context.mounted) return;
                          setSheetState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.message?.toString() ??
                                    'Confira os campos.',
                              ),
                            ),
                          );
                        }
                      },
                child: Text(saving ? 'Salvando…' : 'Salvar lançamento'),
              ),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    description.dispose();
    category.dispose();
    note.dispose();
  }

  Future<void> _showShoppingItem(
    BuildContext context, {
    ShoppingItem? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final quantity = TextEditingController(text: existing?.quantity ?? '1');
    final note = TextEditingController(text: existing?.note ?? '');
    final price = TextEditingController(
      text: existing?.estimatedPriceMinor == null
          ? ''
          : (existing!.estimatedPriceMinor! / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
    );
    await app_ui.showLumeSheet(
      context,
      title: existing == null ? 'Adicionar item' : 'Editar item',
      child: Column(
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Item'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Preço estimado (opcional)',
              prefixText: r'R$ ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe o item.')),
                  );
                  return;
                }
                final priceMinor = price.text.trim().isEmpty
                    ? null
                    : _parseMoney(price.text);
                if (price.text.trim().isNotEmpty &&
                    (priceMinor == null || priceMinor < 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confira o preço.')),
                  );
                  return;
                }
                final controller = AppScope.read(context);
                if (existing == null) {
                  await controller.addShoppingItem(
                    name.text,
                    listId: controller.activeShoppingListId,
                    quantity: quantity.text,
                    note: note.text,
                    estimatedPriceMinor: priceMinor,
                  );
                } else {
                  await controller.updateShoppingItem(
                    id: existing.id,
                    name: name.text,
                    quantity: quantity.text,
                    note: note.text,
                    estimatedPriceMinor: priceMinor,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(existing == null ? 'Adicionar' : 'Salvar'),
            ),
          ),
        ],
      ),
    );
    name.dispose();
    quantity.dispose();
    note.dispose();
    price.dispose();
  }

  Future<void> _showShoppingList(
    BuildContext context, {
    ShoppingListEntry? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    var saving = false;
    await app_ui.showLumeSheet(
      context,
      title: existing == null ? 'Nova lista' : 'Renomear lista',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome da lista'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe um nome para a lista.'),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        try {
                          final controller = AppScope.read(context);
                          if (existing == null) {
                            await controller.addShoppingList(name.text);
                          } else {
                            await controller.renameShoppingList(
                              existing.id,
                              name.text,
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                        } on ArgumentError catch (error) {
                          if (!context.mounted) return;
                          setSheetState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.message?.toString() ??
                                    'Confira o nome da lista.',
                              ),
                            ),
                          );
                        }
                      },
                child: Text(saving ? 'Salvando…' : 'Salvar lista'),
              ),
            ),
          ],
        ),
      ),
    );
    name.dispose();
  }

  Future<void> _deleteShoppingList(
    BuildContext context,
    ShoppingListEntry list,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lista?'),
        content: Text(
          'A lista “${list.name}” e seus itens serão removidos deste aparelho e da conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AppScope.read(context).removeShoppingList(list.id);
    } on ArgumentError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message?.toString() ?? 'Não foi possível excluir a lista.',
          ),
        ),
      );
    }
  }

  Future<void> _clearCompletedShopping(
    BuildContext context,
    AppController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar concluídos?'),
        content: const Text(
          'Os itens marcados como comprados serão removidos desta lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await controller.clearCompletedShoppingItems(
      listId: controller.activeShoppingListId,
    );
    if (!context.mounted || removed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.length} item(ns) removido(s).'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreShoppingItems(removed),
        ),
      ),
    );
  }

  Future<void> _deleteShoppingItem(
    BuildContext context,
    ShoppingItem item,
  ) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir item?',
      content: '“${item.name}” será removido da lista de compras.',
    );
    if (!context.mounted || !confirmed) return;
    final controller = AppScope.read(context);
    final removed = await controller.removeShoppingItem(item.id);
    if (!context.mounted || removed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removido.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreShoppingItems([removed]),
        ),
      ),
    );
  }

  Future<void> _deleteWishlist(BuildContext context, WishlistItem item) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir desejo?',
      content: '“${item.title}” e sua imagem local serão removidos.',
    );
    if (!context.mounted || !confirmed) return;
    await AppScope.read(context).removeWishlistItem(item.id);
  }

  Future<bool> _confirmDelete(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false);
  }

  Future<void> _showFilters(BuildContext context) async {
    final controller = AppScope.read(context);
    final categories =
        controller
            .transactionsFor(controller.periodFor(_selectedMonth))
            .map((entry) => entry.category)
            .toSet()
            .toList()
          ..sort();
    var draft = _categoryFilter;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar lançamentos'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: draft == null,
                  onSelected: (_) => setDialogState(() => draft = null),
                ),
                for (final category in categories)
                  FilterChip(
                    label: Text(category),
                    selected: draft == category,
                    onSelected: (_) => setDialogState(() => draft = category),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _categoryFilter = draft);
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWishlist(
    BuildContext context, {
    WishlistItem? existing,
    String? initialUrl,
  }) async {
    final sharedUri = initialUrl == null ? null : Uri.tryParse(initialUrl);
    final url = TextEditingController(
      text: existing?.originalUrl ?? initialUrl ?? '',
    );
    final title = TextEditingController(
      text: existing?.title ?? (sharedUri?.host ?? ''),
    );
    final price = TextEditingController(
      text: existing?.priceMinor == null
          ? ''
          : (existing!.priceMinor! / 100)
                .toStringAsFixed(2)
                .replaceAll('.', ','),
    );
    final note = TextEditingController(text: existing?.note ?? '');
    String? localImagePath = existing?.localImagePath;
    var status = existing?.status ?? WishlistStatus.wanted;
    await app_ui.showLumeSheet(
      context,
      title: existing == null ? 'Salvar desejo' : 'Editar desejo',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            if (localImagePath != null) ...[
              _LocalPhotoThumb(path: localImagePath!, size: 64),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () async {
                final path = await AppScope.read(
                  context,
                ).pickLocalPhoto(LocalPhotoKind.wishlist);
                if (path != null && context.mounted) {
                  setSheetState(() => localImagePath = path);
                }
              },
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                localImagePath == null ? 'Adicionar imagem' : 'Trocar imagem',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: url,
              autofocus: existing == null,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Link do produto',
                hintText: 'https://…',
                helperText:
                    'O link fica salvo mesmo se a extração não estiver disponível.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Nome do produto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Preço (opcional)',
                prefixText: r'R$ ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WishlistStatus>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(
                  value: WishlistStatus.wanted,
                  child: Text('Desejado'),
                ),
                DropdownMenuItem(
                  value: WishlistStatus.purchased,
                  child: Text('Comprado'),
                ),
                DropdownMenuItem(
                  value: WishlistStatus.archived,
                  child: Text('Arquivado'),
                ),
              ],
              onChanged: (value) =>
                  setSheetState(() => status = value ?? WishlistStatus.wanted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final priceMinor = price.text.trim().isEmpty
                      ? null
                      : _parseMoney(price.text);
                  if (price.text.trim().isNotEmpty &&
                      (priceMinor == null || priceMinor < 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Confira o preço.')),
                    );
                    return;
                  }
                  try {
                    final controller = AppScope.read(context);
                    if (existing == null) {
                      await controller.addWishlistItem(
                        originalUrl: url.text,
                        title: title.text,
                        priceMinor: priceMinor,
                        note: note.text,
                        localImagePath: localImagePath,
                        status: status,
                      );
                    } else {
                      await controller.updateWishlistItem(
                        id: existing.id,
                        originalUrl: url.text,
                        title: title.text,
                        priceMinor: priceMinor,
                        note: note.text,
                        localImagePath: localImagePath,
                        status: status,
                      );
                    }
                  } on ArgumentError catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.message?.toString() ?? 'Confira os campos.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(existing == null ? 'Salvar desejo' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
    url.dispose();
    title.dispose();
    price.dispose();
    note.dispose();
  }

  Future<void> _openWishlist(BuildContext context, WishlistItem item) async {
    final opened = await launchUrl(
      Uri.parse(item.originalUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir este link.')),
      );
    }
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    TransactionEntry entry,
  ) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir lançamento?',
      content:
          '“${entry.description}” será removido e o resumo será recalculado.',
    );
    if (!context.mounted || !confirmed) return;
    final controller = AppScope.read(context);
    final removed = await controller.removeTransaction(entry.id);
    if (removed == null) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.description} removido.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => controller.restoreTransaction(removed),
        ),
      ),
    );
  }

  int? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null ? null : (value * 100).round();
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Mês anterior',
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Center(
          child: Text(
            '${month.month.toString().padLeft(2, '0')}/${month.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Próximo mês',
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.entry,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionEntry entry;
  final AppController controller;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpense = entry.type == TransactionType.expense;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isExpense
            ? app_theme.LumeColors.finance
            : app_theme.LumeColors.wellbeing,
        child: Icon(
          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          size: 18,
        ),
      ),
      title: Text(entry.description),
      subtitle: Text(
        [
          entry.category,
          controller.formatDate(entry.occurredAt),
          if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isExpense ? '-' : '+'}${controller.formatMinor(entry.amountMinor)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isExpense
                  ? Theme.of(context).colorScheme.error
                  : app_theme.LumeColors.brandStrong,
            ),
          ),
          IconButton(
            tooltip: 'Editar lançamento',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir lançamento',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    super.key,
    required this.item,
    required this.controller,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingItem item;
  final AppController controller;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Checkbox(value: item.isChecked, onChanged: (_) => onToggle()),
    title: Text(
      item.name,
      style: TextStyle(
        decoration: item.isChecked ? TextDecoration.lineThrough : null,
      ),
    ),
    subtitle: Text(
      [
        if (item.quantity != '1') 'Quantidade: ${item.quantity}',
        if (item.note != null && item.note!.isNotEmpty) item.note!,
        if (item.estimatedPriceMinor != null)
          controller.formatMinor(item.estimatedPriceMinor!),
      ].join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: PopupMenuButton<String>(
      tooltip: 'Ações do item',
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'delete', child: Text('Excluir')),
      ],
    ),
  );
}

class _WishlistRow extends StatelessWidget {
  const _WishlistRow({
    required this.item,
    required this.controller,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onOpen,
    required this.onDelete,
  });

  final WishlistItem item;
  final AppController controller;
  final ValueChanged<WishlistStatus> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = switch (item.status) {
      WishlistStatus.wanted => 'Desejado',
      WishlistStatus.purchased => 'Comprado',
      WishlistStatus.archived => 'Arquivado',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onOpen,
      leading: item.localImagePath == null
          ? CircleAvatar(
              backgroundColor: app_theme.LumeColors.brandSoft,
              child: const Icon(Icons.favorite_border),
            )
          : _LocalPhotoThumb(path: item.localImagePath!),
      title: Text(item.title),
      subtitle: Text(
        [
          item.siteHost,
          if (item.priceMinor != null) controller.formatMinor(item.priceMinor!),
          status,
        ].join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Ações do desejo',
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'open':
              onOpen();
            case 'purchased':
              onStatusChanged(WishlistStatus.purchased);
            case 'wanted':
              onStatusChanged(WishlistStatus.wanted);
            case 'archived':
              onStatusChanged(WishlistStatus.archived);
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'open', child: Text('Abrir link')),
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'wanted', child: Text('Marcar desejado')),
          PopupMenuItem(value: 'purchased', child: Text('Marcar comprado')),
          PopupMenuItem(value: 'archived', child: Text('Arquivar')),
          PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    );
  }
}

class _LocalPhotoThumb extends StatelessWidget {
  const _LocalPhotoThumb({required this.path, this.size = 48});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.file(
      File(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => CircleAvatar(
        backgroundColor: app_theme.LumeColors.brandSoft,
        child: const Icon(Icons.broken_image_outlined),
      ),
    ),
  );
}
