import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/domain/wishlist.dart';

WishlistItem item({
  String id = 'item',
  String url = 'https://loja.example/produto',
  int? priceMinor,
  String? currency,
  WishlistStatus status = WishlistStatus.wanted,
}) => WishlistItem(
  id: id,
  userId: 'user-1',
  originalUrl: url,
  title: 'Produto',
  store: 'Loja',
  priceMinor: priceMinor,
  currency: currency,
  status: status,
  purchasedAt: status == WishlistStatus.purchased
      ? DateTime.utc(2026, 8, 24)
      : null,
);

void main() {
  test('aceita URL http/https e rejeita esquemas perigosos e credenciais', () {
    expect(item(url: 'http://loja.example/item').siteHost, 'loja.example');
    expect(() => item(url: 'javascript:alert(1)'), throwsArgumentError);
    expect(() => item(url: 'data:text/html,oi'), throwsArgumentError);
    expect(() => item(url: 'file:///tmp/item'), throwsArgumentError);
    expect(
      () => item(url: 'https://user:secret@loja.example/item'),
      throwsArgumentError,
    );
    expect(() => item(url: 'https:///sem-host'), throwsArgumentError);
  });

  test('distingue preço ausente de preço zero e mantém moeda', () {
    expect(item(id: 'unknown').hasKnownPrice, isFalse);
    expect(
      item(id: 'free', priceMinor: 0, currency: 'BRL').hasKnownPrice,
      isTrue,
    );
    expect(() => item(priceMinor: 1000), throwsArgumentError);
    expect(() => item(priceMinor: 1000, currency: 'real'), throwsArgumentError);
  });

  test('atualiza status imutavelmente e preenche/limpa comprado em', () {
    final wanted = item();
    final purchased = wanted.withStatus(
      WishlistStatus.purchased,
      at: DateTime.utc(2026, 8, 24),
    );
    final archived = purchased.withStatus(
      WishlistStatus.archived,
      at: DateTime.utc(2026, 8, 25),
    );

    expect(wanted.status, WishlistStatus.wanted);
    expect(purchased.status, WishlistStatus.purchased);
    expect(purchased.purchasedAt, DateTime.utc(2026, 8, 24));
    expect(archived.status, WishlistStatus.archived);
    expect(archived.purchasedAt, isNull);
  });

  test('totaliza preços conhecidos por moeda e ignora arquivados', () {
    final totals = knownWishlistTotals([
      item(id: 'a', priceMinor: 2599, currency: 'BRL'),
      item(id: 'b', priceMinor: 0, currency: 'BRL'),
      item(id: 'c', priceMinor: 1000, currency: 'USD'),
      item(
        id: 'd',
        priceMinor: 999,
        currency: 'BRL',
        status: WishlistStatus.archived,
      ),
      item(id: 'e'),
    ]);

    expect(totals, {'BRL': 2599, 'USD': 1000});
    expect(() => totals['BRL'] = 1, throwsUnsupportedError);
  });

  test('URL sozinha é suficiente para salvar favorito manual', () {
    final saved = WishlistItem(
      id: 'url-only',
      userId: 'user-1',
      originalUrl: 'https://example.com',
    );
    expect(saved.title, isNull);
    expect(saved.store, isNull);
    expect(saved.status, WishlistStatus.wanted);
  });
}
