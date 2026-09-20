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

/// Best-effort wishlist link reader: Apple's LinkPresentation reliably gets
/// the title and a preview image for almost any site. Price isn't part of
/// that API, so we separately fetch the raw page and look for the common
/// price meta tags / JSON-LD fields shops expose. When a shop blocks that
/// (many do), price/name/image simply come back nil and the composer falls
/// back to manual entry — exactly what the design calls for.
enum LinkMetadataFetcher {
    static func fetch(url: URL) async -> FetchedLinkMetadata {
        async let appleMetadata = fetchAppleMetadata(url: url)
        async let prices = fetchPrices(url: url)
        let (title, imageData) = await appleMetadata
        let (price, originalPrice) = await prices
        return FetchedLinkMetadata(title: title, imageData: imageData, price: price, originalPrice: originalPrice)
    }

    private static func fetchAppleMetadata(url: URL) async -> (String?, Data?) {
        let provider = LPMetadataProvider()
        guard let metadata = try? await provider.startFetchingMetadata(for: url) else {
            return (nil, nil)
        }
        let imageProvider = metadata.imageProvider ?? metadata.iconProvider
        let imageData = await loadImageData(from: imageProvider)
        return (metadata.title, imageData)
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
    #else
    private static func loadImageData(from provider: NSItemProvider?) async -> Data? { nil }
    #endif

    private static func fetchPrices(url: URL) async -> (Double?, Double?) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return (nil, nil) }
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return (nil, nil)
        }

        let price = firstMatch(in: html, patterns: [
            #""price"\s*:\s*"?([0-9]+\.[0-9]{2})"?"#,
            #"property=["']product:price:amount["']\s+content=["']([0-9]+\.[0-9]{2})["']"#,
            #"itemprop=["']price["'][^>]*content=["']([0-9]+\.[0-9]{2})["']"#,
        ])
        let originalPrice = firstMatch(in: html, patterns: [
            #""originalPrice"\s*:\s*"?([0-9]+\.[0-9]{2})"?"#,
            #""listPrice"\s*:\s*"?([0-9]+\.[0-9]{2})"?"#,
            #"property=["']product:original_price:amount["']\s+content=["']([0-9]+\.[0-9]{2})["']"#,
        ])
        return (price, originalPrice)
    }

    private static func firstMatch(in html: String, patterns: [String]) -> Double? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, range: range),
               match.numberOfRanges > 1,
               let valueRange = Range(match.range(at: 1), in: html) {
                return Double(html[valueRange])
            }
        }
        return nil
    }
}
