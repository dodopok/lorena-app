enum WishlistStatus { wanted, purchased, archived }

/// Favorito/desejo preenchido manualmente, sem dependência de rede ou Flutter.
class WishlistItem {
  WishlistItem({
    required this.id,
    required this.userId,
    required this.originalUrl,
    this.canonicalUrl,
    String? siteHost,
    this.title,
    this.store,
    this.priceMinor,
    this.currency,
    this.status = WishlistStatus.wanted,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.purchasedAt,
  }) : siteHost = siteHost ?? _validatedUri(originalUrl).host,
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toUtc() {
    if (id.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('id e userId são obrigatórios');
    }
    _validateUrl(originalUrl);
    if (canonicalUrl != null) _validateUrl(canonicalUrl!);
    if (this.siteHost.trim().isEmpty) {
      throw ArgumentError.value(
        this.siteHost,
        'siteHost',
        'não pode ser vazio',
      );
    }
    if (priceMinor != null && priceMinor! < 0) {
      throw ArgumentError.value(
        priceMinor,
        'priceMinor',
        'deve ser positivo ou zero',
      );
    }
    if (priceMinor != null && _normalizeCurrency(currency) == null) {
      throw ArgumentError('preço informado exige moeda');
    }
    if (currency != null) _validateCurrency(currency!);
    if (status == WishlistStatus.purchased && purchasedAt == null) {
      throw ArgumentError('item comprado exige purchasedAt');
    }
    if (status != WishlistStatus.purchased && purchasedAt != null) {
      throw ArgumentError('purchasedAt só pode existir para item comprado');
    }
  }

  final String id;
  final String userId;
  final String originalUrl;
  final String? canonicalUrl;
  final String siteHost;
  final String? title;
  final String? store;
  final int? priceMinor;
  final String? currency;
  final WishlistStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? purchasedAt;

  /// Ausente significa “preço desconhecido”; zero é um preço conhecido.
  bool get hasKnownPrice => priceMinor != null;

  WishlistItem withStatus(WishlistStatus nextStatus, {DateTime? at}) {
    final timestamp = at ?? DateTime.now().toUtc();
    return WishlistItem(
      id: id,
      userId: userId,
      originalUrl: originalUrl,
      canonicalUrl: canonicalUrl,
      siteHost: siteHost,
      title: title,
      store: store,
      priceMinor: priceMinor,
      currency: currency,
      status: nextStatus,
      createdAt: createdAt,
      updatedAt: timestamp,
      purchasedAt: nextStatus == WishlistStatus.purchased ? timestamp : null,
    );
  }

  static Uri _validatedUri(String value) {
    _validateUrl(value);
    return Uri.parse(value);
  }

  static void _validateUrl(String value) {
    final uri = Uri.tryParse(value);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        (scheme != 'http' && scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        value,
        'url',
        'deve ser uma URL http/https sem credenciais',
      );
    }
  }

  static String? _normalizeCurrency(String? value) => value?.toUpperCase();

  static void _validateCurrency(String value) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(value.toUpperCase())) {
      throw ArgumentError.value(
        value,
        'currency',
        'deve ser um código ISO de três letras',
      );
    }
  }
}

/// Soma preços conhecidos apenas entre itens não arquivados e por moeda.
///
/// O mapa vazio é a representação segura de “nenhum preço conhecido”. Como
/// cada moeda tem sua própria chave, nunca há conversão ou mistura implícita.
Map<String, int> knownWishlistTotals(Iterable<WishlistItem> items) {
  final totals = <String, int>{};
  for (final item in items) {
    if (item.status == WishlistStatus.archived || !item.hasKnownPrice) continue;
    final currency = item.currency!.toUpperCase();
    totals[currency] = (totals[currency] ?? 0) + item.priceMinor!;
  }
  return Map.unmodifiable(totals);
}
