import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:lume/core/auth/auth_gateway.dart';
import 'package:lume/core/links/link_metadata.dart';
import 'package:lume/app/models.dart';

void main() {
  test('normaliza resposta estruturada sem aceitar URLs perigosas', () {
    final metadata = LinkMetadata.fromJson({
      'canonicalUrl': 'https://shop.example/item',
      'title': 'Produto',
      'imageUrl': 'https://cdn.example/image.jpg',
      'priceMinor': 12990,
      'currency': 'brl',
      'source': 'json_ld',
      'warnings': ['revise'],
    });

    expect(metadata.siteHost, 'shop.example');
    expect(metadata.currency, 'BRL');
    expect(metadata.source, LinkMetadataSource.jsonLd);
    expect(metadata.warnings, ['revise']);
    expect(
      () => LinkMetadata.fromJson({
        'canonicalUrl': 'https://shop.example/item',
        'imageUrl': 'http://user:pass@localhost/image.jpg',
      }),
      returnsNormally,
    );
    expect(
      LinkMetadata.fromJson({
        'canonicalUrl': 'https://shop.example/item',
        'imageUrl': 'http://user:pass@localhost/image.jpg',
      }).imageUrl,
      isNull,
    );
  });

  test('chama endpoint callable somente com token Firebase', () async {
    late http.Request request;
    final client = MockClient((incoming) async {
      request = incoming;
      return http.Response(
        jsonEncode({
          'result': {
            'canonicalUrl': 'https://shop.example/item',
            'siteHost': 'shop.example',
            'title': 'Produto',
            'priceMinor': 5000,
            'currency': 'BRL',
            'source': 'open_graph',
          },
        }),
        200,
      );
    });
    final gateway = FunctionLinkMetadataGateway(
      endpoint:
          'https://us-central1-lume-13125.cloudfunctions.net/extractLinkMetadata',
      authGateway: _FakeAuthGateway(),
      client: client,
    );

    final result = await gateway.extract(
      Uri.parse('https://shop.example/item'),
    );

    expect(request.headers['authorization'], 'Bearer test-token');
    expect(
      jsonDecode(request.body)['data']['url'],
      'https://shop.example/item',
    );
    expect(result?.title, 'Produto');
    expect(result?.priceMinor, 5000);
    expect(result?.source, LinkMetadataSource.openGraph);
  });
}

class _FakeAuthGateway implements AuthGateway {
  @override
  String? get userId => 'user-1';

  @override
  Future<String?> getIdToken() async => 'test-token';

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> reauthenticate() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}
