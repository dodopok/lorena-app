import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/lume_app.dart';
import '../../../app/app_route.dart';
import '../../gratitude/presentation/gratitude_editor.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/photos/local_photo_service.dart';
import '../../../core/theme/lume_theme.dart';
import '../../../core/widgets/lume_widgets.dart';

class CornerScreen extends StatefulWidget {
  const CornerScreen({this.initialRoute, super.key});
  final AppRouteRequest? initialRoute;

  @override
  State<CornerScreen> createState() => _CornerScreenState();
}

class _CornerScreenState extends State<CornerScreen>
    with InitialRouteHandler<CornerScreen> {
  @override
  AppRouteRequest? get initialRoute => widget.initialRoute;
  final _booksSection = GlobalKey();
  final _gratitudeSection = GlobalKey();

  @override
  Future<void> openInitialRoute(AppRouteRequest route) async {
    final controller = AppScope.read(context);
    switch (route.action) {
      case AppRouteAction.bookNew:
        await _showBook(context);
      case AppRouteAction.bookEdit:
        final book = controller.books
            .where((item) => item.id == route.id)
            .firstOrNull;
        if (book == null) {
          routeMessage();
          return;
        }
        await _showBook(context, existing: book);
      case AppRouteAction.gratitudeEdit:
        final day = DateTime.parse(route.id!);
        if (controller.gratitudeFor(day).isEmpty) {
          routeMessage();
          return;
        }
        await showGratitudeEditor(context, date: day);
      case AppRouteAction.books:
        await Scrollable.ensureVisible(
          _booksSection.currentContext!,
          alignment: 0,
          duration: lumeMotionDuration(
            context,
            const Duration(milliseconds: 260),
          ),
        );
      case AppRouteAction.gratitude:
        await _showGratitudeHistory(context);
      default:
        break;
    }
  }

  String _bookQuery = '';
  BookStatus? _bookFilter;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final today = controller.gratitudeFor(DateTime.now()).firstOrNull;
    final sortedGratitude = [...controller.gratitudeEntries]
      ..sort((a, b) => b.localDate.compareTo(a.localDate));
    final filteredBooks = controller.books.where((book) {
      final query = _bookQuery.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          (book.author?.toLowerCase().contains(query) ?? false);
      return matchesQuery &&
          (_bookFilter == null || book.status == _bookFilter);
    }).toList();
    final todayImagePath = today?.localImagePath;
    final hasPendingMedia =
        controller.gratitudeEntries.any(
          (item) =>
              item.mediaSyncState == MediaSyncState.pending ||
              item.mediaSyncState == MediaSyncState.failed,
        ) ||
        controller.books.any(
          (item) =>
              item.mediaSyncState == MediaSyncState.pending ||
              item.mediaSyncState == MediaSyncState.failed,
        ) ||
        controller.wishlistItems.any(
          (item) =>
              item.mediaSyncState == MediaSyncState.pending ||
              item.mediaSyncState == MediaSyncState.failed,
        );

    return app_ui.LumePage(
      title: 'Cantinho',
      subtitle: 'Livros, desejos e coisas boas para guardar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LumeCard(
            tone: LumeCardTone.corner,
            onTap: () => _showGratitude(context, entry: today),
            child: Row(
              children: [
                if (todayImagePath != null)
                  GestureDetector(
                    onTap: () => showLumePhotoViewer(
                      context,
                      path: todayImagePath,
                      semanticLabel: 'Foto de gratidão de hoje',
                    ),
                    child: _LocalPhotoThumb(path: todayImagePath, size: 48),
                  )
                else
                  const Icon(Icons.favorite_border, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    today == null
                        ? 'Quer guardar algo bom de hoje?'
                        : today.text.isEmpty
                        ? 'Uma boa lembrança de hoje'
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
            key: _booksSection,
            title: 'Biblioteca',
            actionLabel: 'Adicionar livro',
            onAction: () => _showBook(context),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar por título ou autor',
            ),
            onChanged: (value) => setState(() => _bookQuery = value),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _bookFilter == null,
                  onSelected: (_) => setState(() => _bookFilter = null),
                ),
                const SizedBox(width: 8),
                for (final filter in BookStatus.values) ...[
                  FilterChip(
                    label: Text(_bookStatusLabel(filter)),
                    selected: _bookFilter == filter,
                    onSelected: (_) => setState(() => _bookFilter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
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
          else if (filteredBooks.isEmpty)
            const LumeCard(
              child: Text('Nenhum livro corresponde a esta busca ou filtro.'),
            )
          else
            LumeCard(
              tone: LumeCardTone.calendar,
              child: Column(
                children: filteredBooks
                    .map(
                      (book) => _BookRow(
                        book: book,
                        onEdit: () => _showBook(context, existing: book),
                        onDelete: () => _deleteBook(context, book),
                        onViewCover: book.localCoverPath == null
                            ? null
                            : () => showLumePhotoViewer(
                                context,
                                path: book.localCoverPath!,
                                semanticLabel: 'Capa de ${book.title}',
                              ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 26),
          LumeSectionHeader(
            key: _gratitudeSection,
            title: 'Histórico de gratidão',
            actionLabel: sortedGratitude.isEmpty ? null : 'Ver tudo',
            onAction: () => _showGratitudeHistory(context),
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
                    leading: entry.localImagePath == null
                        ? const Icon(Icons.favorite_outline)
                        : GestureDetector(
                            onTap: () => showLumePhotoViewer(
                              context,
                              path: entry.localImagePath!,
                              semanticLabel:
                                  'Foto de gratidão de ${entry.localDate}',
                            ),
                            child: _LocalPhotoThumb(
                              path: entry.localImagePath!,
                            ),
                          ),
                    title: Text(
                      controller.formatDate(DateTime.parse(entry.localDate)),
                    ),
                    subtitle: Text(
                      entry.text.isEmpty
                          ? 'Uma boa lembrança em foto'
                          : entry.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _showGratitude(context, entry: entry),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 26),
          _MediaStatusCard(
            hasPendingMedia: hasPendingMedia,
            onRetry: hasPendingMedia
                ? () => controller.retryPhotoUploads()
                : null,
          ),
        ],
      ),
    );
  }

  String _bookStatusLabel(BookStatus status) => switch (status) {
    BookStatus.wantToRead => 'Quero ler',
    BookStatus.reading => 'Lendo',
    BookStatus.read => 'Lido',
    BookStatus.abandoned => 'Abandonado',
  };

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  Future<void> _showGratitude(BuildContext context, {GratitudeEntry? entry}) =>
      showGratitudeEditor(
        context,
        date: entry == null ? null : DateTime.parse(entry.localDate),
      );

  Future<void> _showGratitudeHistory(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const _GratitudeHistoryScreen()),
      );

  Future<void> _showBook(BuildContext context, {BookEntry? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final author = TextEditingController(text: existing?.author ?? '');
    final review = TextEditingController(text: existing?.review ?? '');
    var status = existing?.status ?? BookStatus.wantToRead;
    int? rating = existing?.rating;
    String? localCoverPath = existing?.localCoverPath;
    var removeCover = false;
    var startedOn = existing?.startedOn;
    var finishedOn = existing?.finishedOn;
    var saving = false;

    await app_ui.showLumeSheet(
      context,
      title: existing == null ? 'Adicionar livro' : 'Editar livro',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            if (localCoverPath != null) ...[
              GestureDetector(
                onTap: () => showLumePhotoViewer(
                  context,
                  path: localCoverPath!,
                  semanticLabel: 'Capa de ${title.text}',
                ),
                child: _LocalPhotoPreview(path: localCoverPath!, isCover: true),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: saving
                      ? null
                      : () => setSheetState(() {
                          localCoverPath = null;
                          removeCover = true;
                        }),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover capa'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      final path = await AppScope.read(
                        context,
                      ).pickLocalPhoto(LocalPhotoKind.bookCover);
                      if (path != null && context.mounted) {
                        setSheetState(() {
                          localCoverPath = path;
                          removeCover = false;
                        });
                      }
                    },
              icon: const Icon(Icons.photo_camera_back_outlined),
              label: Text(
                localCoverPath == null ? 'Adicionar capa' : 'Trocar capa',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: title,
              autofocus: existing == null,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: author,
              decoration: const InputDecoration(labelText: 'Autor (opcional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BookStatus>(
              isExpanded: true,
              itemHeight: null,
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
              onChanged: (value) => setSheetState(() {
                status = value ?? BookStatus.wantToRead;
                if (status == BookStatus.read && finishedOn == null) {
                  finishedOn = DateTime.now();
                }
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: startedOn ?? DateTime.now(),
                            );
                            if (picked != null && context.mounted) {
                              setSheetState(() => startedOn = picked);
                            }
                          },
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: Text(
                      startedOn == null
                          ? 'Início'
                          : 'Início ${_shortDate(startedOn!)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: finishedOn ?? DateTime.now(),
                            );
                            if (picked != null && context.mounted) {
                              setSheetState(() => finishedOn = picked);
                            }
                          },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      finishedOn == null
                          ? 'Conclusão'
                          : 'Fim ${_shortDate(finishedOn!)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              itemHeight: null,
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
                onPressed: saving
                    ? null
                    : () async {
                        if (title.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Informe o título.')),
                          );
                          return;
                        }
                        if (startedOn != null &&
                            finishedOn != null &&
                            finishedOn!.isBefore(startedOn!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A conclusão não pode ser anterior ao início.',
                              ),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        try {
                          final controller = AppScope.read(context);
                          if (existing == null) {
                            await controller.addBook(
                              title: title.text,
                              author: author.text,
                              status: status,
                              rating: rating,
                              review: review.text,
                              localCoverPath: localCoverPath,
                              startedOn: startedOn,
                              finishedOn: finishedOn,
                            );
                          } else {
                            await controller.updateBook(
                              id: existing.id,
                              title: title.text,
                              author: author.text,
                              status: status,
                              rating: rating,
                              review: review.text,
                              startedOn: startedOn,
                              finishedOn: finishedOn,
                              localCoverPath: localCoverPath,
                              clearLocalCoverPath: removeCover,
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
                child: Text(saving ? 'Salvando…' : 'Salvar livro'),
              ),
            ),
            if (existing != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: saving ? null : () => _deleteBook(context, existing),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir livro'),
              ),
            ],
          ],
        ),
      ),
    );
    title.dispose();
    author.dispose();
    review.dispose();
  }

  Future<void> _deleteBook(BuildContext context, BookEntry book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir livro?'),
        content: Text(
          book.localCoverPath == null
              ? '“${book.title}” será removido da biblioteca.'
              : '“${book.title}” e sua capa serão removidos da biblioteca.',
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
    if (!context.mounted || confirmed != true) return;
    final controller = AppScope.read(context);
    await controller.removeBook(book.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${book.title} removido.')));
  }
}

class _MediaStatusCard extends StatelessWidget {
  const _MediaStatusCard({required this.hasPendingMedia, this.onRetry});

  final bool hasPendingMedia;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => LumeCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          hasPendingMedia
              ? Icons.cloud_upload_outlined
              : Icons.photo_library_outlined,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            hasPendingMedia
                ? 'As fotos ficam disponíveis offline e aguardam uma conexão para a cópia privada.'
                : 'As fotos ficam disponíveis offline e são copiadas para a área privada quando você está conectada.',
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Tentar')),
      ],
    ),
  );
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    this.onViewCover,
  });

  final BookEntry book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onViewCover;

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
      onTap: onEdit,
      leading: book.localCoverPath == null
          ? CircleAvatar(
              backgroundColor: context.lumeColors.calendar,
              child: const Icon(Icons.menu_book_outlined),
            )
          : GestureDetector(
              onTap: onViewCover,
              child: _LocalPhotoThumb(path: book.localCoverPath!, size: 48),
            ),
      title: Text(book.title),
      subtitle: Text(
        [
          if (book.author != null) book.author!,
          status,
          if (book.rating != null) '★ ${book.rating}',
        ].join(' · '),
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Ações do livro',
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
          if (value == 'cover') onViewCover?.call();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Editar')),
          if (onViewCover != null)
            const PopupMenuItem(value: 'cover', child: Text('Ver capa')),
          const PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    );
  }
}

class _LocalPhotoThumb extends StatelessWidget {
  const _LocalPhotoThumb({required this.path, this.size = 40});

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
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        color: context.lumeColors.surface,
        child: const Icon(Icons.broken_image_outlined),
      ),
    ),
  );
}

class _GratitudeHistoryScreen extends StatelessWidget {
  const _GratitudeHistoryScreen();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final entries = [...controller.gratitudeEntries]
      ..sort((a, b) => b.localDate.compareTo(a.localDate));
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de gratidão')),
      body: SafeArea(
        child: entries.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Suas boas lembranças vão aparecer aqui.'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final date = DateTime.parse(entry.localDate);
                  return LumeCard(
                    tone: LumeCardTone.corner,
                    onTap: () => showGratitudeEditor(context, date: date),
                    child: Row(
                      children: [
                        if (entry.localImagePath != null)
                          _LocalPhotoThumb(path: entry.localImagePath!)
                        else
                          const Icon(Icons.favorite_outline),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${controller.formatDate(date)} de ${date.year}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.text.isEmpty
                                    ? 'Uma boa lembrança em foto'
                                    : entry.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _LocalPhotoPreview extends StatelessWidget {
  const _LocalPhotoPreview({required this.path, this.isCover = false});

  final String path;
  final bool isCover;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.file(
      File(path),
      width: double.infinity,
      height: isCover ? 180 : 220,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: isCover ? 180 : 220,
        alignment: Alignment.center,
        color: context.lumeColors.surface,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined),
            SizedBox(height: 4),
            Text('Prévia indisponível; o texto continua salvo.'),
          ],
        ),
      ),
    ),
  );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
