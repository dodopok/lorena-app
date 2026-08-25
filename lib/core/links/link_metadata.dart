import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/models.dart';
import '../auth/auth_gateway.dart';

class LinkMetadata {
  const LinkMetadata({
    required this.canonicalUrl,
    required this.siteHost,
    this.title,
    this.imageUrl,
    this.priceMinor,
    this.currency,
    this.source = LinkMetadataSource.manual,
    this.warnings = const [],
    this.fetchedAt,
  });

  final String canonicalUrl;
  final String siteHost;
  final String? title;
  final String? imageUrl;
  final int? priceMinor;
  final String? currency;
  final LinkMetadataSource source;
  final List<String> warnings;
  final DateTime? fetchedAt;

  factory LinkMetadata.fromJson(Map<String, dynamic> map) {
    final canonical = _safeHttpUrl(map['canonicalUrl']);
    if (canonical == null) {
      throw const LinkMetadataException(
        'A extração retornou uma URL inválida.',
      );
    }
    final title = _boundedText(map['title'], 180);
    final imageUrl = _safeHttpUrl(map['imageUrl']);
    final rawPrice = map['priceMinor'];
    final priceMinor = rawPrice is num && rawPrice.isFinite
        ? rawPrice.toInt()
        : null;
    if (priceMinor != null && (priceMinor < 0 || priceMinor > 100000000000)) {
      throw const LinkMetadataException(
        'A extração retornou um preço inválido.',
      );
    }
    final rawCurrency = map['currency'];
    final currency =
        rawCurrency is String &&
            RegExp(r'^[A-Za-z]{3}$').hasMatch(rawCurrency.trim())
        ? rawCurrency.trim().toUpperCase()
        : null;
    final sourceName = map['source'] is String
        ? (map['source'] as String).replaceAll('_', '')
        : '';
    final source = LinkMetadataSource.values.firstWhere(
      (value) => value.name.toLowerCase() == sourceName.toLowerCase(),
      orElse: () => LinkMetadataSource.manual,
    );
    final warnings = map['warnings'] is List
        ? (map['warnings'] as List)
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .take(8)
              .toList()
        : const <String>[];
    final fetchedAt = map['fetchedAt'] is String
        ? DateTime.tryParse(map['fetchedAt'] as String)
        : null;
    return LinkMetadata(
      canonicalUrl: canonical.toString(),
      siteHost: canonical.host,
      title: title,
      imageUrl: imageUrl?.toString(),
      priceMinor: priceMinor,
      currency: priceMinor == null ? null : currency ?? 'BRL',
      source: source,
      warnings: warnings,
      fetchedAt: fetchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'canonicalUrl': canonicalUrl,
    'siteHost': siteHost,
    if (title != null && title!.isNotEmpty) 'title': title,
    if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    if (priceMinor != null) 'priceMinor': priceMinor,
    if (currency != null) 'currency': currency,
    'source': source.name,
    if (warnings.isNotEmpty) 'warnings': warnings,
    if (fetchedAt != null) 'fetchedAt': fetchedAt!.toIso8601String(),
  };
}

abstract interface class LinkMetadataGateway {
  Future<LinkMetadata?> extract(Uri url);
}

class LinkMetadataException implements Exception {
  const LinkMetadataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client for the authenticated callable HTTP endpoint. The endpoint is a
/// build-time value so local builds never make an accidental network request.
class FunctionLinkMetadataGateway implements LinkMetadataGateway {
  FunctionLinkMetadataGateway({
    required String endpoint,
    required AuthGateway authGateway,
    http.Client? client,
  }) : _endpoint = _safeEndpoint(endpoint),
       _authGateway = authGateway,
       _client = client ?? http.Client();

  final Uri _endpoint;
  final AuthGateway _authGateway;
  final http.Client _client;

  @override
  Future<LinkMetadata?> extract(Uri url) async {
    final safeUrl = _safeHttpUrl(url.toString());
    if (safeUrl == null) {
      throw const LinkMetadataException('Informe uma URL http(s) válida.');
    }
    final token = await _authGateway.getIdToken();
    if (token == null || token.isEmpty) {
      throw const LinkMetadataException(
        'Entre no Lume para preencher o produto.',
      );
    }
    final response = await _client
        .post(
          _endpoint,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {'url': safeUrl.toString()},
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const LinkMetadataException(
        'A autorização para preencher o produto expirou.',
      );
    }
    if (response.statusCode != 200) {
      throw const LinkMetadataException(
        'Não foi possível preencher os dados deste produto.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const LinkMetadataException(
        'A extração retornou uma resposta inválida.',
      );
    }
    final data = decoded['result'] ?? decoded['data'];
    if (data == null) return null;
    if (data is! Map) {
      throw const LinkMetadataException('A extração retornou dados inválidos.');
    }
    return LinkMetadata.fromJson(Map<String, dynamic>.from(data));
  }

  static Uri _safeEndpoint(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw ArgumentError.value(raw, 'endpoint', 'must be an HTTPS URL');
    }
    return uri;
  }
}

Uri? _safeHttpUrl(Object? raw) {
  if (raw is! String) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.port != 0 && uri.port != 80 && uri.port != 443) {
    return null;
  }
  return uri;
}

String? _boundedText(Object? raw, int maxLength) {
  if (raw is! String) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  return value.length <= maxLength ? value : value.substring(0, maxLength);
}
