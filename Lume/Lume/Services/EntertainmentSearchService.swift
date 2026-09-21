import Foundation

struct EntertainmentSearchResult: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let kind: String
    let year: Int?
    let imageURL: URL?
    let sourceURL: URL?
}

/// Uses IMDb's public autocomplete feed so each result can open its IMDb title
/// page without requiring an API key or an account inside Lume.
enum EntertainmentSearchService {
    private struct Response: Decodable, Sendable {
        let d: [Suggestion]
    }

    private struct Suggestion: Decodable, Sendable {
        let id: String?
        let title: String?
        let type: String?
        let year: Int?
        let image: Image?

        enum CodingKeys: String, CodingKey {
            case id
            case title = "l"
            case type = "q"
            case year = "y"
            case image = "i"
        }

        struct Image: Decodable, Sendable {
            let imageURL: String?

            enum CodingKeys: String, CodingKey {
                case imageURL = "imageUrl"
            }
        }
    }

    static func search(title: String) async -> [EntertainmentSearchResult] {
        let query = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return [] }

        let results = await searchIMDb(query: query)

        var seen = Set<String>()
        return results.compactMap { result in
            let key = result.title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            guard !key.isEmpty, seen.insert(key).inserted else { return nil }
            return result
        }
        .prefix(16)
        .map { $0 }
    }

    private static func searchIMDb(query: String) async -> [EntertainmentSearchResult] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://v3.sg.media-imdb.com/suggestion/x/\(encodedQuery).json") else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.d.compactMap { item in
                guard let id = item.id, let title = item.title, !title.isEmpty else { return nil }
                let normalizedType = item.type?.lowercased() ?? ""
                guard normalizedType.contains("feature")
                        || normalizedType.contains("movie")
                        || normalizedType.contains("series")
                        || normalizedType.contains("tv") else { return nil }
                let kind = normalizedType.contains("tv") || normalizedType.contains("series") ? "Série" : "Filme"
                return EntertainmentSearchResult(
                    id: id,
                    title: title,
                    kind: kind,
                    year: item.year,
                    imageURL: item.image?.imageURL.flatMap(URL.init(string:)),
                    sourceURL: URL(string: "https://www.imdb.com/title/\(id)/")
                )
            }
        } catch {
            return []
        }
    }
}
