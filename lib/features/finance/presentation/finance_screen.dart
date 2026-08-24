import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/theme.dart' as app_theme;
import '../../../app/ui.dart' as app_ui;
import '../../../core/theme/lume_theme.dart';
import '../../../core/widgets/lume_widgets.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final now = DateTime.now();
    final period = controller.periodFor(now);
    final entries = controller.transactionsFor(period);
    final wishlist = controller.wishlistItems
        .where((item) => item.status != WishlistStatus.archived)
        .toList();
    return app_ui.LumePage(
      title: 'Finanças',
      subtitle: 'Seu dinheiro com clareza e sem julgamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LumeMoneySummaryCard(
            periodLabel: _monthLabel(now),
            balanceMinor: controller.balanceFor(period),
            currency: 'BRL',
            incomeMinor: controller.incomeFor(period),
            expenseMinor: controller.expensesFor(period),
            rolloverMinor: controller.rolloverFor(period),
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
            title: 'Lançamentos de ${_monthLabel(now)}',
            actionLabel: entries.isEmpty ? null : 'Filtrar',
            onAction: entries.isEmpty ? null : () => _showCategoryInfo(context),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            LumeCard(
              child: LumeEmptyState(
                illustration: const Icon(Icons.receipt_long_outlined, size: 40),
                title: 'Nenhum lançamento ainda',
                description:
                    'Registre o primeiro gasto ou entrada para acompanhar o mês.',
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
            actionLabel: 'Adicionar',
            onAction: () => _showShoppingItem(context),
          ),
          const SizedBox(height: 8),
          LumeCard(
            tone: LumeCardTone.finance,
            child: controller.shoppingItems.isEmpty
                ? const Text(
                    'Uma lista simples para não precisar guardar tudo na cabeça.',
                  )
                : Column(
                    children: [
                      ...controller.shoppingItems.map(
                        (item) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: item.isChecked,
                          onChanged: (_) =>
                              controller.toggleShoppingItem(item.id),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: item.quantity == '1'
                              ? null
                              : Text('Quantidade: ${item.quantity}'),
                          secondary: IconButton(
                            tooltip: 'Excluir item',
                            onPressed: () =>
                                controller.removeShoppingItem(item.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                      if (controller.shoppingItems.any(
                        (item) => item.isChecked,
                      ))
                        TextButton.icon(
                          onPressed: controller.clearCompletedShoppingItems,
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
                    onDelete: () => controller.removeWishlistItem(item.id),
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
    var type = existing?.type ?? initialType;
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
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
                  if (existing == null) {
                    await controller.addTransaction(
                      type: type,
                      amountMinor: minor,
                      category: category.text,
                      description: description.text,
                    );
                  } else {
                    await controller.updateTransaction(
                      id: existing.id,
                      type: type,
                      amountMinor: minor,
                      category: category.text,
                      description: description.text,
                    );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Salvar lançamento'),
              ),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    description.dispose();
    category.dispose();
  }

  Future<void> _showShoppingItem(BuildContext context) async {
    final name = TextEditingController();
    final quantity = TextEditingController(text: '1');
    await app_ui.showLumeSheet(
      context,
      title: 'Adicionar item',
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
                await AppScope.read(
                  context,
                ).addShoppingItem(name.text, quantity: quantity.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ),
        ],
      ),
    );
    name.dispose();
    quantity.dispose();
  }

  void _showCategoryInfo(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Filtros'),
      content: const Text(
        'A lista já está agrupada pela competência atual. Categorias continuam visíveis em cada lançamento; o próximo passo é adicionar filtros persistentes por categoria.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );

  Future<void> _showWishlist(BuildContext context) async {
    final url = TextEditingController();
    final title = TextEditingController();
    final price = TextEditingController();
    final note = TextEditingController();
    await app_ui.showLumeSheet(
      context,
      title: 'Salvar desejo',
      child: Column(
        children: [
          TextField(
            controller: url,
            autofocus: true,
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Preço (opcional)',
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
                  await AppScope.read(context).addWishlistItem(
                    originalUrl: url.text,
                    title: title.text,
                    priceMinor: priceMinor,
                    note: note.text,
                  );
                } on ArgumentError catch (error) {
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
              child: const Text('Salvar desejo'),
            ),
          ),
        ],
      ),
    );
    url.dispose();
    title.dispose();
    price.dispose();
    note.dispose();
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    TransactionEntry entry,
  ) async {
    await AppScope.read(context).removeTransaction(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${entry.description} removido.')));
  }

  int? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null ? null : (value * 100).round();
  }
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
        '${entry.category} · ${controller.formatDate(entry.occurredAt)}',
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

class _WishlistRow extends StatelessWidget {
  const _WishlistRow({
    required this.item,
    required this.controller,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final WishlistItem item;
  final AppController controller;
  final ValueChanged<WishlistStatus> onStatusChanged;
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
      leading: CircleAvatar(
        backgroundColor: app_theme.LumeColors.brandSoft,
        child: const Icon(Icons.favorite_border),
      ),
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
          PopupMenuItem(value: 'wanted', child: Text('Marcar desejado')),
          PopupMenuItem(value: 'purchased', child: Text('Marcar comprado')),
          PopupMenuItem(value: 'archived', child: Text('Arquivar')),
          PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    );
  }
}
