import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/models.dart';

class ExportBundle {
  const ExportBundle({required this.path, required this.fileName});

  final String path;
  final String fileName;
}

/// Creates a portable, human-readable ZIP without including auth tokens,
/// local absolute paths, or private Storage URLs. Local media is copied under
/// a relative `media/` directory so the archive remains useful offline.
class ExportService {
  ExportService({Future<Directory> Function()? temporaryDirectoryProvider})
    : _temporaryDirectoryProvider =
          temporaryDirectoryProvider ?? getTemporaryDirectory;

  final Future<Directory> Function() _temporaryDirectoryProvider;

  Future<ExportBundle> create(AppSnapshot snapshot, {DateTime? now}) async {
    final date = (now ?? DateTime.now()).toLocal();
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final fileName = 'lume-export-$dateKey.zip';
    final archive = Archive();

    _addText(
      archive,
      'profile.json',
      _prettyJson({
        'format': 'lume-export-v1',
        'exportedAt': date.toIso8601String(),
        'locale': 'pt-BR',
        'timeZone': 'America/Sao_Paulo',
        'currency': 'BRL',
        'settings': _settings(snapshot.settings),
      }),
    );
    _addText(archive, 'water.csv', _waterCsv(snapshot.waterLogs));
    _addText(archive, 'bowel.csv', _bowelCsv(snapshot.bowelLogs));
    _addText(archive, 'exercise.csv', _exerciseCsv(snapshot.exerciseLogs));
    _addText(
      archive,
      'finance/periods.csv',
      _periodsCsv(snapshot.settings, snapshot.transactions),
    );
    _addText(
      archive,
      'finance/transactions.csv',
      _transactionsCsv(snapshot.transactions),
    );
    _addText(
      archive,
      'shopping/lists.json',
      _prettyJson({
        'name': 'Compras',
        'items': snapshot.shoppingItems.map(_shoppingItem).toList(),
      }),
    );
    _addText(
      archive,
      'shopping/wishlist.csv',
      _wishlistCsv(snapshot.wishlistItems),
    );
    _addText(
      archive,
      'books.json',
      _prettyJson(snapshot.books.map(_book).toList()),
    );
    _addText(
      archive,
      'gratitude.json',
      _prettyJson(snapshot.gratitudeEntries.map(_gratitude).toList()),
    );

    await _addLocalMedia(archive, snapshot);

    final encoded = ZipEncoder().encode(archive);
    if (encoded.isEmpty) {
      throw StateError('Não foi possível gerar a exportação.');
    }
    final temporaryDirectory = await _temporaryDirectoryProvider();
    final file = File('${temporaryDirectory.path}/$fileName');
    await file.writeAsBytes(encoded, flush: true);
    return ExportBundle(path: file.path, fileName: fileName);
  }

  Future<void> _addLocalMedia(Archive archive, AppSnapshot snapshot) async {
    for (final entry in snapshot.gratitudeEntries) {
      await _addFile(
        archive,
        entry.localImagePath,
        'media/gratitude/${entry.localDate}',
      );
    }
    for (final book in snapshot.books) {
      await _addFile(archive, book.localCoverPath, 'media/books/${book.id}');
    }
    for (final item in snapshot.wishlistItems) {
      await _addFile(archive, item.localImagePath, 'media/wishlist/${item.id}');
    }
  }

  Future<void> _addFile(
    Archive archive,
    String? sourcePath,
    String relativeDirectory,
  ) async {
    if (sourcePath == null || sourcePath.isEmpty) return;
    final source = File(sourcePath);
    if (!await source.exists()) return;
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) return;
    final sourceName = source.uri.pathSegments.isEmpty
        ? 'image.jpg'
        : source.uri.pathSegments.last;
    final safeName = sourceName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    archive.addFile(
      ArchiveFile('$relativeDirectory/$safeName', bytes.length, bytes),
    );
  }

  void _addText(Archive archive, String path, String value) {
    final bytes = utf8.encode(value);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  Map<String, dynamic> _settings(UserSettings settings) => {
    'waterGoalMl': settings.waterGoalMl,
    'quickWaterAmountsMl': settings.quickWaterAmountsMl,
    'allowanceAmountMinor': settings.allowanceAmountMinor,
    'allowanceDayOfMonth': settings.allowanceDayOfMonth,
    'rolloverMode': settings.rolloverMode.name,
    'notificationsEnabled': settings.notificationsEnabled,
    'reminderPreferences': settings.reminderPreferences.toJson(),
    'calendarConnected': settings.calendarConnected,
  };

  Map<String, dynamic> _shoppingItem(ShoppingItem item) => {
    'id': item.id,
    'name': item.name,
    'quantity': item.quantity,
    if (item.note != null && item.note!.isNotEmpty) 'note': item.note,
    'isChecked': item.isChecked,
    if (item.estimatedPriceMinor != null)
      'estimatedPriceMinor': item.estimatedPriceMinor,
    'position': item.position,
    if (item.checkedAt != null) 'checkedAt': item.checkedAt!.toIso8601String(),
  };

  Map<String, dynamic> _book(BookEntry book) => {
    'id': book.id,
    'title': book.title,
    if (book.author != null) 'author': book.author,
    'status': book.status.name,
    if (book.startedOn != null) 'startedOn': book.startedOn!.toIso8601String(),
    if (book.finishedOn != null)
      'finishedOn': book.finishedOn!.toIso8601String(),
    if (book.rating != null) 'rating': book.rating,
    if (book.review != null) 'review': book.review,
    if (book.isbn != null) 'isbn': book.isbn,
    'hasCover': book.localCoverPath != null || book.remoteCoverPath != null,
  };

  Map<String, dynamic> _gratitude(GratitudeEntry entry) => {
    'localDate': entry.localDate,
    if (entry.text.isNotEmpty) 'text': entry.text,
    'hasPhoto':
        entry.localImagePath != null || entry.remoteImagePaths.isNotEmpty,
  };

  String _waterCsv(List<WaterLog> logs) => _csv(
    ['id', 'amountMl', 'occurredAt', 'localDate'],
    logs.map(
      (item) => [item.id, item.amountMl, item.occurredAt, item.localDate],
    ),
  );

  String _bowelCsv(List<BowelLog> logs) => _csv(
    ['id', 'occurredAt', 'localDate', 'bristolType', 'comfort', 'note'],
    logs.map(
      (item) => [
        item.id,
        item.occurredAt,
        item.localDate,
        item.bristolType,
        item.comfort?.name,
        item.note,
      ],
    ),
  );

  String _exerciseCsv(List<ExerciseLog> logs) => _csv(
    [
      'id',
      'activityType',
      'durationMinutes',
      'startedAt',
      'localDate',
      'intensity',
      'note',
    ],
    logs.map(
      (item) => [
        item.id,
        item.activityType,
        item.durationMinutes,
        item.occurredAt,
        item.localDate,
        item.intensity?.name,
        item.note,
      ],
    ),
  );

  String _periodsCsv(UserSettings settings, List<TransactionEntry> entries) {
    final periods = entries.map((item) => item.period).toSet().toList()..sort();
    return _csv(
      ['period', 'allowanceAmountMinor', 'rolloverMode', 'balanceMinor'],
      periods.map(
        (period) => [
          period,
          settings.allowanceAmountMinor,
          settings.rolloverMode.name,
          _balanceFor(period, settings, entries),
        ],
      ),
    );
  }

  int _balanceFor(
    String period,
    UserSettings settings,
    List<TransactionEntry> entries,
  ) {
    final current = entries.where((item) => item.period == period);
    final income = current
        .where((item) => item.type != TransactionType.expense)
        .fold(0, (total, item) => total + item.amountMinor);
    final expense = current
        .where((item) => item.type == TransactionType.expense)
        .fold(0, (total, item) => total + item.amountMinor);
    return income - expense;
  }

  String _transactionsCsv(List<TransactionEntry> entries) => _csv(
    [
      'id',
      'type',
      'amountMinor',
      'currency',
      'occurredAt',
      'period',
      'category',
      'description',
      'note',
    ],
    entries.map(
      (item) => [
        item.id,
        item.type.name,
        item.amountMinor,
        'BRL',
        item.occurredAt,
        item.period,
        item.category,
        item.description,
        item.note,
      ],
    ),
  );

  String _wishlistCsv(List<WishlistItem> items) => _csv(
    [
      'id',
      'originalUrl',
      'siteHost',
      'title',
      'priceMinor',
      'currency',
      'status',
      'note',
      'hasImage',
    ],
    items.map(
      (item) => [
        item.id,
        item.originalUrl,
        item.siteHost,
        item.title,
        item.priceMinor,
        item.currency,
        item.status.name,
        item.note,
        item.localImagePath != null || item.remoteImagePath != null,
      ],
    ),
  );

  String _csv(List<String> headers, Iterable<List<Object?>> rows) {
    final lines = <String>[_csvRow(headers)];
    lines.addAll(rows.map(_csvRow));
    return '${lines.join('\n')}\n';
  }

  String _csvRow(Iterable<Object?> values) => values.map(_csvValue).join(',');

  String _csvValue(Object? value) {
    final raw = value is DateTime ? value.toIso8601String() : '${value ?? ''}';
    return '"${raw.replaceAll('"', '""')}"';
  }

  String _prettyJson(Object value) =>
      const JsonEncoder.withIndent('  ').convert(value);
}
