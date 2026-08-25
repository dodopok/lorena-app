import dns from 'node:dns/promises';
import http from 'node:http';
import https from 'node:https';
import net from 'node:net';
import zlib from 'node:zlib';

export const MAX_REDIRECTS = 3;
export const MAX_COMPRESSED_BYTES = 512 * 1024;
export const MAX_HTML_BYTES = 2 * 1024 * 1024;
export const REQUEST_TIMEOUT_MS = 8_000;

export type MetadataSource = 'json_ld' | 'open_graph' | 'manual';

export interface LinkMetadata {
  canonicalUrl: string;
  siteHost: string;
  title?: string;
  imageUrl?: string;
  priceMinor?: number;
  currency?: string;
  source: MetadataSource;
  warnings: string[];
}

export class LinkExtractionError extends Error {
  constructor(
    message: string,
    readonly code:
      | 'invalid-argument'
      | 'failed-precondition'
      | 'resource-exhausted'
      | 'unavailable',
  ) {
    super(message);
  }
}

type SafeTarget = {
  url: URL;
  address: string;
  family: 4 | 6;
};

export async function extractLinkMetadata(rawUrl: string): Promise<LinkMetadata | null> {
  let target = await resolveSafeTarget(rawUrl);
  for (let redirects = 0; redirects <= MAX_REDIRECTS; redirects += 1) {
    const response = await requestHtml(target);
    if (response.statusCode >= 300 && response.statusCode < 400) {
      const location = response.headers.location;
      if (!location) {
        throw new LinkExtractionError('O site retornou um redirecionamento incompleto.', 'unavailable');
      }
      if (redirects === MAX_REDIRECTS) {
        throw new LinkExtractionError('O site redirecionou muitas vezes.', 'failed-precondition');
      }
      target = await resolveSafeTarget(new URL(location, target.url).toString());
      continue;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw new LinkExtractionError('O site não permitiu a leitura desta página.', 'unavailable');
    }
    const contentType = response.headers['content-type'] ?? '';
    if (!/text\/html|application\/xhtml\+xml/i.test(contentType)) {
      throw new LinkExtractionError('A página não é HTML público.', 'failed-precondition');
    }
    const html = await decodeBody(response.body, response.headers['content-encoding']);
    return await parseProductHtml(html, target.url);
  }
  throw new LinkExtractionError('Não foi possível seguir o link.', 'unavailable');
}

export async function resolveSafeTarget(rawUrl: string, base?: URL): Promise<SafeTarget> {
  let url: URL;
  try {
    url = new URL(rawUrl, base);
  } catch {
    throw new LinkExtractionError('Informe uma URL http(s) válida.', 'invalid-argument');
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new LinkExtractionError('Somente URLs HTTP/HTTPS podem ser consultadas.', 'invalid-argument');
  }
  if (url.username || url.password || (url.port && url.port !== '80' && url.port !== '443')) {
    throw new LinkExtractionError('A URL possui uma porta ou credencial não permitida.', 'invalid-argument');
  }
  const hostname = url.hostname.replace(/^\[|\]$/g, '').toLowerCase();
  if (!hostname || isBlockedHostname(hostname)) {
    throw new LinkExtractionError('Este endereço não pode ser consultado.', 'invalid-argument');
  }
  const addresses = await dns.lookup(hostname, { all: true, verbatim: true });
  if (addresses.length === 0 || addresses.some((entry) => isBlockedIp(entry.address))) {
    throw new LinkExtractionError('O endereço resolve para uma rede não permitida.', 'invalid-argument');
  }
  const selected = addresses[0];
  return {
    url,
    address: selected.address,
    family: selected.family === 6 ? 6 : 4,
  };
}

export async function parseProductHtml(
  html: string,
  pageUrl: URL,
  options: { validateImageUrl?: boolean } = {},
): Promise<LinkMetadata | null> {
  const metadata = new Map<string, string>();
  const metaPattern = /<meta\b([^>]+)>/gi;
  for (const match of html.matchAll(metaPattern)) {
    const attributes = attributesFromTag(match[1]);
    const key = (
      attributes.property ??
      attributes.name ??
      attributes.itemprop ??
      ''
    ).toLowerCase();
    const content = decodeEntities(attributes.content ?? '').trim();
    if (key && content) metadata.set(key, content);
  }

  const canonical = canonicalFromHtml(html, pageUrl) ?? pageUrl;
  const jsonLd = readJsonLd(html);
  const product = findProduct(jsonLd);
  const jsonTitle = product ? boundedText(product.name) : undefined;
  const jsonImage = product ? imageFromValue(product.image) : undefined;
  const jsonOffer = product ? offerFromProduct(product) : undefined;
  const metaTitle =
    boundedText(metadata.get('og:title')) ??
    boundedText(metadata.get('twitter:title')) ??
    boundedText(metadata.get('title')) ??
    boundedText(metadata.get('name'));
  const metaImage =
    metadata.get('og:image') ??
    metadata.get('twitter:image') ??
    metadata.get('twitter:image:src') ??
    metadata.get('image');
  const metaPrice = parsePrice(
    metadata.get('product:price:amount') ??
      metadata.get('og:price:amount') ??
      metadata.get('price'),
  );
  const metaCurrency = normalizeCurrency(
    metadata.get('product:price:currency') ??
      metadata.get('og:price:currency') ??
      metadata.get('pricecurrency') ??
      metadata.get('priceCurrency'),
  );
  const title = jsonTitle ?? metaTitle ?? boundedText(titleFromHtml(html));
  const imageCandidate = jsonImage ?? metaImage;
  const imageUrl = imageCandidate ? safeRelatedUrl(imageCandidate, canonical) : undefined;
  const priceMinor = jsonOffer?.priceMinor ?? metaPrice;
  const currency = jsonOffer?.currency ?? metaCurrency ?? (priceMinor == null ? undefined : 'BRL');
  const source: MetadataSource = jsonTitle || jsonImage || jsonOffer
    ? 'json_ld'
    : metaTitle || metaImage || metaPrice != null
      ? 'open_graph'
      : 'manual';
  const warnings: string[] = [];
  if (!title && !imageUrl && priceMinor == null) {
    warnings.push('Nenhum dado estruturado foi encontrado; revise manualmente.');
  }
  let validatedImageUrl: string | undefined;
  if (imageUrl && options.validateImageUrl !== false) {
    try {
      const imageTarget = await resolveSafeTarget(imageUrl.toString());
      validatedImageUrl = imageTarget.url.toString();
    } catch {
      warnings.push('A imagem encontrada não está em um endereço público permitido.');
    }
  } else if (imageUrl) {
    validatedImageUrl = imageUrl.toString();
  }
  if (source === 'manual' && !warnings.length) {
    warnings.push('Os dados encontrados são parciais; revise antes de salvar.');
  }
  return {
    canonicalUrl: canonical.toString(),
    siteHost: canonical.hostname,
    ...(title ? { title } : {}),
    ...(validatedImageUrl ? { imageUrl: validatedImageUrl } : {}),
    ...(priceMinor != null ? { priceMinor } : {}),
    ...(currency ? { currency } : {}),
    source,
    warnings,
  };
}

function requestHtml(target: SafeTarget): Promise<{
  statusCode: number;
  headers: http.IncomingHttpHeaders;
  body: Buffer;
}> {
  return new Promise((resolve, reject) => {
    const transport = target.url.protocol === 'https:' ? https : http;
    const request = transport.request(
      {
        hostname: target.url.hostname,
        port: target.url.port || (target.url.protocol === 'https:' ? 443 : 80),
        path: `${target.url.pathname || '/'}${target.url.search}`,
        method: 'GET',
        headers: {
          accept: 'text/html,application/xhtml+xml;q=0.9',
          'accept-language': 'pt-BR,pt;q=0.9,en;q=0.8',
          'user-agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
            + 'AppleWebKit/605.1.15 (KHTML, like Gecko) '
            + 'Version/17.0 Mobile/15E148 Safari/604.1',
          'accept-encoding': 'gzip, deflate, br',
        },
        timeout: REQUEST_TIMEOUT_MS,
        // Pin the DNS result used for validation to prevent a second lookup
        // from sending the request to a different address.
        lookup: (_hostname: string, _options: object, callback: Function) =>
          callback(null, target.address, target.family),
      },
      (response) => {
        readLimited(response, MAX_COMPRESSED_BYTES)
          .then((body) => resolve({
            statusCode: response.statusCode ?? 0,
            headers: response.headers,
            body,
          }))
          .catch(reject);
      },
    );
    request.once('timeout', () => request.destroy(new Error('timeout')));
    request.once('error', reject);
    request.end();
  });
}

async function decodeBody(body: Buffer, encoding?: string | string[]): Promise<string> {
  const value = Array.isArray(encoding) ? encoding[0] : encoding ?? '';
  let decoded: Buffer;
  try {
    if (/gzip/i.test(value)) decoded = zlib.gunzipSync(body);
    else if (/deflate/i.test(value)) decoded = zlib.inflateSync(body);
    else if (/br/i.test(value)) decoded = zlib.brotliDecompressSync(body);
    else decoded = body;
  } catch {
    throw new LinkExtractionError('Não foi possível descompactar a página.', 'failed-precondition');
  }
  if (decoded.byteLength > MAX_HTML_BYTES) {
    throw new LinkExtractionError('A página é maior que o limite permitido.', 'failed-precondition');
  }
  return decoded.toString('utf8');
}

function readLimited(stream: NodeJS.ReadableStream, limit: number): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let size = 0;
    stream.on('data', (chunk: Buffer | string) => {
      const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
      size += buffer.byteLength;
      if (size > limit) {
        (stream as NodeJS.ReadableStream & { destroy(error?: Error): void }).destroy(
          new Error('limit'),
        );
        reject(new LinkExtractionError('A resposta é maior que o limite permitido.', 'failed-precondition'));
        return;
      }
      chunks.push(buffer);
    });
    stream.once('end', () => resolve(Buffer.concat(chunks)));
    stream.once('error', (error) => reject(error));
  });
}

function attributesFromTag(raw: string): Record<string, string> {
  const result: Record<string, string> = {};
  const pattern = /([:\w-]+)\s*=\s*["']([^"']*)["']/gi;
  for (const match of raw.matchAll(pattern)) result[match[1].toLowerCase()] = decodeEntities(match[2]);
  return result;
}

function canonicalFromHtml(html: string, pageUrl: URL): URL | undefined {
  const pattern = /<link\b([^>]+)>/gi;
  for (const match of html.matchAll(pattern)) {
    const attributes = attributesFromTag(match[1]);
    if ((attributes.rel ?? '').toLowerCase().split(/\s+/).includes('canonical')) {
      return safeRelatedUrl(attributes.href, pageUrl);
    }
  }
  return undefined;
}

function titleFromHtml(html: string): string | undefined {
  const match = /<title\b[^>]*>([\s\S]*?)<\/title>/i.exec(html);
  return match ? decodeEntities(match[1].replace(/<[^>]+>/g, ' ')) : undefined;
}

function readJsonLd(html: string): unknown[] {
  const values: unknown[] = [];
  const pattern = /<script\b([^>]*type\s*=\s*["']application\/ld\+json["'][^>]*)>([\s\S]*?)<\/script>/gi;
  for (const match of html.matchAll(pattern)) {
    try {
      values.push(JSON.parse(decodeEntities(match[2].trim())));
    } catch {
      // A malformed third-party script is treated as a fallback condition.
    }
  }
  return values;
}

function findProduct(values: unknown[]): Record<string, any> | undefined {
  const queue = [...values];
  let visited = 0;
  while (queue.length && visited < 500) {
    const value = queue.shift();
    visited += 1;
    if (Array.isArray(value)) {
      queue.push(...value);
      continue;
    }
    if (!value || typeof value !== 'object') continue;
    const object = value as Record<string, any>;
    const type = object['@type'];
    const types = Array.isArray(type) ? type : [type];
    if (types.some((entry) => typeof entry === 'string' && entry.toLowerCase() === 'product')) return object;
    for (const child of Object.values(object)) {
      if (child && typeof child === 'object') queue.push(child);
    }
  }
  return undefined;
}

function offerFromProduct(product: Record<string, any>): { priceMinor?: number; currency?: string } | undefined {
  const rawOffers = product.offers;
  const offers = Array.isArray(rawOffers) ? rawOffers : [rawOffers];
  for (const rawOffer of offers) {
    if (!rawOffer || typeof rawOffer !== 'object') continue;
    const offer = rawOffer as Record<string, any>;
    const priceMinor = parsePrice(offer.price ?? offer.lowPrice);
    const currency = normalizeCurrency(offer.priceCurrency);
    if (priceMinor != null || currency) return { priceMinor, currency: currency ?? (priceMinor == null ? undefined : 'BRL') };
  }
  return undefined;
}

function imageFromValue(value: unknown): string | undefined {
  if (typeof value === 'string') return value;
  if (Array.isArray(value)) {
    for (const item of value) {
      const image = imageFromValue(item);
      if (image) return image;
    }
  }
  if (value && typeof value === 'object') {
    const object = value as Record<string, any>;
    if (typeof object.url === 'string') return object.url;
    if (typeof object.contentUrl === 'string') return object.contentUrl;
  }
  return undefined;
}

function safeRelatedUrl(raw: string | undefined, base: URL): URL | undefined {
  if (!raw) return undefined;
  try {
    const url = new URL(raw, base);
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return undefined;
    if (url.username || url.password || (url.port && url.port !== '80' && url.port !== '443')) return undefined;
    return url;
  } catch {
    return undefined;
  }
}

function parsePrice(raw: unknown): number | undefined {
  if (typeof raw !== 'string' && typeof raw !== 'number') return undefined;
  const text = String(raw).replace(/[^\d,.-]/g, '').trim();
  if (!text) return undefined;
  let normalized = text;
  const comma = text.lastIndexOf(',');
  const dot = text.lastIndexOf('.');
  if (comma >= 0 && dot >= 0) {
    normalized = comma > dot
      ? text.replace(/\./g, '').replace(',', '.')
      : text.replace(/,/g, '');
  } else if (comma >= 0) {
    normalized = text.length - comma - 1 === 2 ? text.replace(',', '.') : text.replace(/,/g, '');
  }
  const value = Number(normalized);
  if (!Number.isFinite(value) || value < 0 || value > 1000000000) return undefined;
  return Math.round(value * 100);
}

function normalizeCurrency(raw: unknown): string | undefined {
  if (typeof raw !== 'string' || !/^[A-Za-z]{3}$/.test(raw.trim())) return undefined;
  return raw.trim().toUpperCase();
}

function boundedText(raw: unknown): string | undefined {
  if (typeof raw !== 'string') return undefined;
  const value = decodeEntities(raw).replace(/\s+/g, ' ').trim();
  return value ? value.slice(0, 180) : undefined;
}

function decodeEntities(value: string): string {
  return value
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&#(\d+);/g, (_, code: string) => String.fromCodePoint(Number(code)));
}

function isBlockedHostname(hostname: string): boolean {
  return hostname === 'localhost' || hostname.endsWith('.localhost') || hostname.endsWith('.local') || hostname === 'metadata.google.internal' || hostname === 'metadata.google' || hostname === '169.254.169.254';
}

export function isBlockedIp(address: string): boolean {
  if (net.isIP(address) === 4) return isBlockedIpv4(address);
  if (net.isIP(address) === 6) return isBlockedIpv6(address);
  return true;
}

function isBlockedIpv4(address: string): boolean {
  const parts = address.split('.').map(Number);
  if (parts.length !== 4 || parts.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) return true;
  const value = parts.reduce((total, part) => total * 256 + part, 0);
  const inRange = (start: number, end: number) => value >= start && value <= end;
  return parts[0] === 0 ||
    parts[0] === 10 ||
    parts[0] === 127 ||
    inRange(0x64400000, 0x647fffff) ||
    inRange(0xa9fe0000, 0xa9feffff) ||
    inRange(0xac100000, 0xac1fffff) ||
    inRange(0xc0000000, 0xc00000ff) ||
    inRange(0xc0000200, 0xc00002ff) ||
    inRange(0xc0a80000, 0xc0a8ffff) ||
    inRange(0xc6120000, 0xc613ffff) ||
    inRange(0xc6336400, 0xc63364ff) ||
    inRange(0xcb007100, 0xcb0071ff) ||
    parts[0] >= 224;
}

function isBlockedIpv6(address: string): boolean {
  const value = ipv6ToBigInt(address);
  if (value == null) return true;
  const inRange = (prefix: bigint, bits: number) => value >> BigInt(128 - bits) === prefix;
  if (inRange(0n, 128) || inRange(1n, 128) || inRange(0xfc000000000000000000000000000000n >> 121n, 7) || inRange(0xfe800000000000000000000000000000n >> 118n, 10) || inRange(0xff000000000000000000000000000000n >> 120n, 8)) return true;
  if (value >> 32n === 0xffffn) {
    const ipv4 = Number(value & 0xffffffffn);
    return isBlockedIpv4(
      `${ipv4 >>> 24}.${(ipv4 >>> 16) & 255}.${(ipv4 >>> 8) & 255}.${ipv4 & 255}`,
    );
  }
  return false;
}

function ipv6ToBigInt(address: string): bigint | undefined {
  let value = address.toLowerCase();
  if (value.includes('.')) {
    const lastColon = value.lastIndexOf(':');
    const ipv4 = value.slice(lastColon + 1);
    const parts = ipv4.split('.').map(Number);
    if (parts.length !== 4 || parts.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) return undefined;
    const hex = `${((parts[0] << 8) | parts[1]).toString(16)}:${((parts[2] << 8) | parts[3]).toString(16)}`;
    value = `${value.slice(0, lastColon + 1)}${hex}`;
  }
  const sections = value.split('::');
  if (sections.length > 2) return undefined;
  const left = sections[0] ? sections[0].split(':') : [];
  const right = sections.length === 2 && sections[1] ? sections[1].split(':') : [];
  if (sections.length === 1 && left.length !== 8) return undefined;
  if (left.concat(right).some((part) => !/^[0-9a-f]{1,4}$/.test(part))) return undefined;
  const missing = 8 - left.length - right.length;
  if (missing < 0 || (sections.length === 1 && missing !== 0)) return undefined;
  const groups = [...left, ...Array.from({ length: missing }, () => '0'), ...right];
  return groups.reduce((total, group) => (total << 16n) + BigInt(`0x${group}`), 0n);
}
