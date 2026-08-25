import assert from 'node:assert/strict';
import test from 'node:test';

import {
  isBlockedIp,
  parseProductHtml,
} from './extractor';

test('bloqueia redes privadas, loopback, link-local e metadata', () => {
  assert.equal(isBlockedIp('127.0.0.1'), true);
  assert.equal(isBlockedIp('10.0.0.1'), true);
  assert.equal(isBlockedIp('169.254.169.254'), true);
  assert.equal(isBlockedIp('192.168.1.20'), true);
  assert.equal(isBlockedIp('::1'), true);
  assert.equal(isBlockedIp('fc00::1'), true);
  assert.equal(isBlockedIp('fe80::1'), true);
  assert.equal(isBlockedIp('2001:4860:4860::8888'), false);
});

test('extrai Product JSON-LD com fallback seguro de preço e imagem', async () => {
  const result = await parseProductHtml(
    `<!doctype html><html><head>
      <link rel="canonical" href="https://shop.example/item/1">
      <script type="application/ld+json">{
        "@type":"Product",
        "name":"Caderno bonito",
        "image":"https://cdn.example/item.jpg",
        "offers":{"price":"129,90","priceCurrency":"BRL"}
      }</script>
    </head></html>`,
    new URL('https://shop.example/item/1'),
    { validateImageUrl: false },
  );
  assert.deepEqual(result, {
    canonicalUrl: 'https://shop.example/item/1',
    siteHost: 'shop.example',
    title: 'Caderno bonito',
    imageUrl: 'https://cdn.example/item.jpg',
    priceMinor: 12990,
    currency: 'BRL',
    source: 'json_ld',
    warnings: [],
  });
});

test('usa Open Graph quando não há Product JSON-LD', async () => {
  const result = await parseProductHtml(
    `<meta property="og:title" content="Caneca">
     <meta property="og:image" content="/caneca.jpg">
     <meta property="product:price:amount" content="49.90">
     <meta property="product:price:currency" content="BRL">`,
    new URL('https://shop.example/item/2'),
    { validateImageUrl: false },
  );
  assert.equal(result?.source, 'open_graph');
  assert.equal(result?.title, 'Caneca');
  assert.equal(result?.imageUrl, 'https://shop.example/caneca.jpg');
  assert.equal(result?.priceMinor, 4990);
});
