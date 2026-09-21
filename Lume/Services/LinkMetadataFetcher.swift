import Foundation
import LinkPresentation
#if canImport(UIKit)
import UIKit
#endif

struct FetchedLinkMetadata {
    var title: String?
    var imageData: Data?
    var price: Double?
    var originalPrice: Double?
}

/// Reads the common metadata formats used by online stores. LinkPresentation
/// remains the last fallback, but the page itself is preferred because it has
/// the product image and price even when Apple's preview provider only returns
/// the store's generic icon.
enum LinkMetadataFetcher {
    private struct PageMetadata {
        var title: String?
        var imageURL: URL?
        var price: Double?
        var originalPrice: Double?
    }

    private struct StructuredValues {
        var titles: [String] = []
        var images: [String] = []
        var prices: [String] = []
        var originalPrices: [String] = []
    }

    static func fetch(url: URL) async -> FetchedLinkMetadata {
        async let appleMetadata = fetchAppleMetadata(url: url)
        async let html = fetchPage(url: url)

        let (appleTitle, appleImageData) = await appleMetadata
        let page = await html.map { parsePage($0, baseURL: url) } ?? PageMetadata()

        let pageImageData = await loadImageData(from: page.imageURL)

        return FetchedLinkMetadata(
            title: page.title ?? appleTitle,
            imageData: pageImageData ?? appleImageData,
            price: page.price,
            originalPrice: page.originalPrice
        )
    }

    private static func fetchPage(url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await URLSession.shared.data(for: request) else { return nil }
        if let http = response as? HTTPURLResponse, !(200..<400).contains(http.statusCode) {
            return nil
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    }

    private static func fetchAppleMetadata(url: URL) async -> (String?, Data?) {
        let provider = LPMetadataProvider()
        guard let metadata = try? await provider.startFetchingMetadata(for: url) else {
            return (nil, nil)
        }
        let imageProvider = metadata.imageProvider
        let imageData = await loadImageData(from: imageProvider)
        return (metadata.title, imageData)
    }

    private static func parsePage(_ html: String, baseURL: URL) -> PageMetadata {
        var titleCandidates: [String] = []
        var imageCandidates: [String] = []
        var priceCandidates: [String] = []
        var originalPriceCandidates: [String] = []

        let metaPattern = #"<meta\b[^>]*>"#
        for tag in matches(in: html, pattern: metaPattern, options: [.caseInsensitive]) {
            let attributes = attributes(in: tag)
            let property = attributes["property"]?.lowercased()
            let name = attributes["name"]?.lowercased()
            let itemprop = attributes["itemprop"]?.lowercased()
            let key = property ?? name ?? itemprop ?? ""
            guard let value = attributes["content"] ?? attributes["value"] else { continue }

            switch key {
            case "og:title", "twitter:title", "product:name", "itemprop:name":
                titleCandidates.append(value)
            case "og:image:secure_url", "og:image", "twitter:image", "twitter:image:src", "image", "image_url":
                imageCandidates.append(value)
            case "product:price:amount", "og:price:amount", "product:price", "price", "itemprop:price":
                priceCandidates.append(value)
            case "product:original_price:amount", "product:price:original", "compare_at_price", "list_price", "itemprop:highPrice":
                originalPriceCandidates.append(value)
            default:
                break
            }
        }

        let titlePattern = #"<title\b[^>]*>(.*?)</title>"#
        titleCandidates.append(contentsOf: matches(in: html, pattern: titlePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]))

        var structured = StructuredValues()
        let jsonLDPattern = #"<script\b[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script>"#
        for script in matches(in: html, pattern: jsonLDPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            parseStructuredJSON(script, into: &structured)
        }
        titleCandidates.append(contentsOf: structured.titles)
        imageCandidates.append(contentsOf: structured.images)
        priceCandidates.append(contentsOf: structured.prices)
        originalPriceCandidates.append(contentsOf: structured.originalPrices)

        // Shopify, VTEX and other storefronts often expose product JSON in a
        // normal application/json script instead of JSON-LD.
        titleCandidates.append(contentsOf: rawValues(in: html, keys: ["productName", "product_name"]))
        imageCandidates.append(contentsOf: rawValues(in: html, keys: ["imageUrl", "image_url", "productImage", "image"]))
        priceCandidates.append(contentsOf: rawValues(in: html, keys: ["price", "Price", "sellingPrice", "selling_price", "salePrice", "sale_price", "spotPrice", "currentPrice"]))
        originalPriceCandidates.append(contentsOf: rawValues(in: html, keys: ["originalPrice", "original_price", "compareAtPrice", "compare_at_price", "listPrice", "list_price", "PriceWithoutDiscount", "wasPrice"]))

        return PageMetadata(
            title: firstText(in: titleCandidates),
            imageURL: firstImageURL(in: imageCandidates, baseURL: baseURL),
            price: firstPrice(in: priceCandidates),
            originalPrice: firstPrice(in: originalPriceCandidates)
        )
    }

    private static func parseStructuredJSON(_ script: String, into values: inout StructuredValues) {
        let decoded = htmlDecoded(decodeEmbeddedString(script))
        guard let data = decoded.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else { return }
        collectStructuredValues(from: object, into: &values)
    }

    private static func collectStructuredValues(from value: Any, into values: inout StructuredValues) {
        if let object = value as? [String: Any] {
            for (key, child) in object {
                let normalizedKey = key.lowercased()
                switch normalizedKey {
                case "name", "headline", "productname", "product_name":
                    if let text = child as? String { values.titles.append(text) }
                case "image", "imageurl", "image_url":
                    if let text = child as? String { values.images.append(text) }
                case "price", "lowprice", "currentprice", "saleprice", "sellingprice", "selling_price", "spotprice":
                    if let text = child as? String { values.prices.append(text) }
                    else if let number = child as? NSNumber { values.prices.append(number.stringValue) }
                case "originalprice", "original_price", "compareatprice", "compare_at_price", "listprice", "list_price", "pricewithoutdiscount", "wasprice", "highprice":
                    if let text = child as? String { values.originalPrices.append(text) }
                    else if let number = child as? NSNumber { values.originalPrices.append(number.stringValue) }
                default:
                    break
                }
                collectStructuredValues(from: child, into: &values)
            }
        } else if let array = value as? [Any] {
            for child in array {
                collectStructuredValues(from: child, into: &values)
            }
        }
    }

    private static func rawValues(in html: String, keys: [String]) -> [String] {
        let escapedKeys = keys.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        let pattern = "\\\"(?:\(escapedKeys))\\\"\\s*:\\s*(?:\\\"([^\\\"]*)\\\"|([-+]?[0-9]+(?:[.,][0-9]+)?))"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }

        let range = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            if let textRange = Range(match.range(at: 1), in: html) { return String(html[textRange]) }
            if let numberRange = Range(match.range(at: 2), in: html) { return String(html[numberRange]) }
            return nil
        }
    }

    private static func attributes(in tag: String) -> [String: String] {
        let pattern = #"([A-Za-z_:][A-Za-z0-9_.:-]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [:] }
        let range = NSRange(tag.startIndex..., in: tag)
        var result: [String: String] = [:]
        for match in regex.matches(in: tag, range: range) {
            guard let nameRange = Range(match.range(at: 1), in: tag),
                  let valueRange = Range(match.range(at: 2), in: tag)
                    ?? Range(match.range(at: 3), in: tag)
                    ?? Range(match.range(at: 4), in: tag) else { continue }
            result[String(tag[nameRange]).lowercased()] = String(tag[valueRange])
        }
        return result
    }

    private static func matches(in text: String, pattern: String, options: NSRegularExpression.Options = []) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[valueRange])
        }
    }

    private static func firstText(in candidates: [String]) -> String? {
        for candidate in candidates {
            let value = htmlDecoded(decodeEmbeddedString(candidate))
                .replacingOccurrences(of: "\n", with: " ")
                .split(whereSeparator: { $0.isWhitespace })
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { return value }
        }
        return nil
    }

    private static func firstImageURL(in candidates: [String], baseURL: URL) -> URL? {
        let urls = candidates.compactMap { imageURL(from: $0, baseURL: baseURL) }
        return urls.first(where: { $0.scheme?.lowercased() == "https" }) ?? urls.first
    }

    private static func firstPrice(in candidates: [String]) -> Double? {
        candidates.compactMap(parsePrice).first
    }

    private static func parsePrice(_ raw: String) -> Double? {
        let decoded = htmlDecoded(decodeEmbeddedString(raw))
        let pattern = #"[-+]?\d[\d.,]*"#
        guard let number = matches(in: decoded, pattern: "(\(pattern))").first else { return nil }

        let comma = number.lastIndex(of: ",")
        let dot = number.lastIndex(of: ".")
        let normalized: String
        if let comma, let dot {
            if comma > dot {
                normalized = number.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = number.replacingOccurrences(of: ",", with: "")
            }
        } else if comma != nil {
            normalized = number.replacingOccurrences(of: ",", with: ".")
        } else if number.filter({ $0 == "." }).count > 1 {
            let parts = number.split(separator: ".")
            normalized = parts.dropLast().joined() + "." + (parts.last ?? "")
        } else {
            normalized = number
        }

        guard var value = Double(normalized), value >= 0 else { return nil }
        if !number.contains(",") && !number.contains(".") && value >= 10_000 {
            value /= 100
        }
        return value
    }

    private static func imageURL(from raw: String, baseURL: URL) -> URL? {
        var string = htmlDecoded(decodeEmbeddedString(raw))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !string.isEmpty else { return nil }
        if string.hasPrefix("//") { string = "https:\(string)" }

        let url: URL?
        if let absolute = URL(string: string), absolute.scheme != nil {
            url = absolute
        } else {
            url = URL(string: string, relativeTo: baseURL)?.absoluteURL
        }
        guard let url else { return nil }

        if url.scheme?.lowercased() == "http",
           var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.scheme = "https"
            return components.url ?? url
        }
        return url
    }

    private static func decodeEmbeddedString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\u002F", with: "/")
            .replacingOccurrences(of: "\\u002f", with: "/")
            .replacingOccurrences(of: "\\u0026", with: "&")
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "\\\"", with: "\"")
    }

    private static func htmlDecoded(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    #if canImport(UIKit)
    private static func loadImageData(from provider: NSItemProvider?) async -> Data? {
        guard let provider, provider.canLoadObject(ofClass: UIImage.self) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                let data = (object as? UIImage)?.jpegData(compressionQuality: 0.85)
                continuation.resume(returning: data)
            }
        }
    }

    private static func loadImageData(from url: URL?) async -> Data? {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request) else { return nil }
        if let http = response as? HTTPURLResponse, !(200..<400).contains(http.statusCode) { return nil }
        guard let image = UIImage(data: data) else { return nil }
        return image.jpegData(compressionQuality: 0.85) ?? data
    }
    #else
    private static func loadImageData(from provider: NSItemProvider?) async -> Data? { nil }
    private static func loadImageData(from url: URL?) async -> Data? { nil }
    #endif
}
