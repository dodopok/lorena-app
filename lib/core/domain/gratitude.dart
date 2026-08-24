import 'date_rules.dart';

class GratitudeEntry {
  GratitudeEntry({
    required this.id,
    required this.userId,
    required this.localDate,
    this.text,
    Iterable<String> images = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : images = List.unmodifiable(images),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toUtc() {
    if (id.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('id e userId são obrigatórios');
    }
    DateRules.parseDate(localDate);
    if (!hasContent) throw ArgumentError('gratidão precisa de texto ou imagem');
  }

  final String id;
  final String userId;
  final String localDate;
  final String? text;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasContent =>
      (text?.trim().isNotEmpty ?? false) || images.isNotEmpty;

  GratitudeEntry copyWith({
    String? text,
    Iterable<String>? images,
    DateTime? updatedAt,
  }) => GratitudeEntry(
    id: id,
    userId: userId,
    localDate: localDate,
    text: text ?? this.text,
    images: images ?? this.images,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
  );
}
