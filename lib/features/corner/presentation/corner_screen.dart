import 'package:flutter/material.dart';

import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/theme/lume_theme.dart';
import '../../../core/widgets/lume_widgets.dart';

class CornerScreen extends StatelessWidget {
  const CornerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final today = controller.gratitudeFor(DateTime.now()).firstOrNull;
    final sortedGratitude = [...controller.gratitudeEntries]
      ..sort((a, b) => b.localDate.compareTo(a.localDate));

    return app_ui.LumePage(
      title: 'Cantinho',
      subtitle: 'Livros, desejos e coisas boas para guardar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LumeCard(
            tone: LumeCardTone.corner,
            onTap: () => _showGratitude(context, today?.text ?? ''),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    today == null
                        ? 'Quer guardar algo bom de hoje?'
                        : today.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 26),
          LumeSectionHeader(
            title: 'Biblioteca',
            actionLabel: 'Adicionar livro',
            onAction: () => _showBook(context),
          ),
          const SizedBox(height: 8),
          if (controller.books.isEmpty)
            LumeCard(
              child: LumeEmptyState(
                illustration: const Icon(Icons.menu_book_outlined, size: 40),
                title: 'Sua biblioteca começa aqui',
                description:
                    'Salve um livro sem capa ou autor e complete depois.',
                primaryAction: LumeButton(
                  label: 'Adicionar livro',
                  onPressed: () => _showBook(context),
                ),
              ),
            )
          else
            LumeCard(
              tone: LumeCardTone.calendar,
              child: Column(
                children: controller.books
                    .map(
                      (book) => _BookRow(
                        book: book,
                        onDelete: () => _deleteBook(context, book),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 26),
          LumeSectionHeader(
            title: 'Histórico de gratidão',
            actionLabel: sortedGratitude.isEmpty ? null : 'Ver tudo',
          ),
          const SizedBox(height: 8),
          if (sortedGratitude.isEmpty)
            const LumeCard(
              child: Text(
                'Uma entrada por dia, com texto ou foto, sem obrigação de manter sequência.',
              ),
            )
          else
            LumeCard(
              tone: LumeCardTone.corner,
              child: Column(
                children: sortedGratitude.take(10).map((entry) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.favorite_outline),
                    title: Text(entry.localDate),
                    subtitle: Text(
                      entry.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _showGratitude(context, entry.text),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 26),
          LumeCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.photo_library_outlined),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Fotos entram no fluxo de gratidão e livros quando o seletor do iOS e a fila privada de uploads forem configurados. O texto já funciona offline.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGratitude(BuildContext context, String initial) async {
    final text = TextEditingController(text: initial);
    await app_ui.showLumeSheet(
      context,
      title: 'Gratidão de hoje',
      child: Column(
        children: [
          TextField(
            controller: text,
            autofocus: true,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'O que foi bom hoje?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (text.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Escreva algo ou adicione uma foto.'),
                    ),
                  );
                  return;
                }
                await AppScope.read(context).saveGratitude(text.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
    text.dispose();
  }

  Future<void> _showBook(BuildContext context) async {
    final title = TextEditingController();
    final author = TextEditingController();
    final review = TextEditingController();
    var status = BookStatus.wantToRead;
    int? rating;

    await app_ui.showLumeSheet(
      context,
      title: 'Adicionar livro',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: author,
              decoration: const InputDecoration(labelText: 'Autor (opcional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BookStatus>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(
                  value: BookStatus.wantToRead,
                  child: Text('Quero ler'),
                ),
                DropdownMenuItem(
                  value: BookStatus.reading,
                  child: Text('Lendo'),
                ),
                DropdownMenuItem(value: BookStatus.read, child: Text('Lido')),
                DropdownMenuItem(
                  value: BookStatus.abandoned,
                  child: Text('Abandonado'),
                ),
              ],
              onChanged: (value) =>
                  setSheetState(() => status = value ?? BookStatus.wantToRead),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: rating,
              decoration: const InputDecoration(
                labelText: 'Avaliação (opcional)',
              ),
              items: [
                for (var value = 1; value <= 5; value++)
                  DropdownMenuItem(value: value, child: Text('$value de 5')),
              ],
              onChanged: (value) => setSheetState(() => rating = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: review,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resenha (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe o título.')),
                    );
                    return;
                  }
                  await AppScope.read(context).addBook(
                    title: title.text,
                    author: author.text,
                    status: status,
                    rating: rating,
                    review: review.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Salvar livro'),
              ),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    author.dispose();
    review.dispose();
  }

  Future<void> _deleteBook(BuildContext context, BookEntry book) async {
    await AppScope.read(context).removeBook(book.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${book.title} removido.')));
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book, required this.onDelete});

  final BookEntry book;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = switch (book.status) {
      BookStatus.wantToRead => 'Quero ler',
      BookStatus.reading => 'Lendo',
      BookStatus.read => 'Lido',
      BookStatus.abandoned => 'Abandonado',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: context.lumeColors.calendar,
        child: const Icon(Icons.menu_book_outlined),
      ),
      title: Text(book.title),
      subtitle: Text(
        [
          if (book.author != null) book.author!,
          status,
          if (book.rating != null) '★ ${book.rating}',
        ].join(' · '),
      ),
      trailing: IconButton(
        tooltip: 'Excluir livro',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
