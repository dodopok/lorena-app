import Foundation

struct GoogleBookResult: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let authors: String
    let coverURL: URL?
    let sourceName: String
}

/// Searches Google Books first and falls back to Open Library when the public
/// Google endpoint is unavailable or rate-limited. The app only stores the
/// selected image URL; the existing color cover remains available whenever a
/// result has no image or the network is unavailable.
enum GoogleBooksService {
    private struct Response: Decodable {
        let items: [Volume]?
    }

    private struct Volume: Decodable {
        let id: String
        let volumeInfo: VolumeInfo
    }

    private struct VolumeInfo: Decodable {
        let title: String?
        let authors: [String]?
        let imageLinks: ImageLinks?
    }

    private struct ImageLinks: Decodable {
        let smallThumbnail: String?
        let thumbnail: String?
        let small: String?
        let medium: String?
        let large: String?
        let extraLarge: String?
    }

    private struct OpenLibraryResponse: Decodable {
        let docs: [OpenLibraryVolume]
    }

    private struct OpenLibraryVolume: Decodable {
        let key: String?
        let title: String?
        let authorNames: [String]?
        let coverID: Int?

        enum CodingKeys: String, CodingKey {
            case key
            case title
            case authorNames = "author_name"
            case coverID = "cover_i"
        }
    }

    static func search(title: String) async -> [GoogleBookResult] {
        let query = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return [] }

        let googleResults = await searchGoogleBooks(query: query)
        guard googleResults.isEmpty else { return googleResults }
        return await searchOpenLibrary(query: query)
    }

    private static func searchGoogleBooks(query: String) async -> [GoogleBookResult] {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "intitle:\(query)"),
            URLQueryItem(name: "maxResults", value: "8"),
            URLQueryItem(name: "printType", value: "books")
        ]
        guard let url = components?.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let decoded = try? JSONDecoder().decode(Response.self, from: data) else {
            return []
        }

        return (decoded.items ?? []).compactMap { makeResult(from: $0) }
    }

    private static func searchOpenLibrary(query: String) async -> [GoogleBookResult] {
        var components = URLComponents(string: "https://openlibrary.org/search.json")
        components?.queryItems = [
            URLQueryItem(name: "title", value: query),
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "fields", value: "key,title,author_name,cover_i")
        ]
        guard let url = components?.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let decoded = try? JSONDecoder().decode(OpenLibraryResponse.self, from: data) else {
            return []
        }

        return decoded.docs.compactMap { volume in
            guard let title = volume.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty,
                  let coverID = volume.coverID else {
                return nil
            }

            return GoogleBookResult(
                id: "openlibrary-\(volume.key ?? UUID().uuidString)",
                title: title,
                authors: (volume.authorNames ?? []).joined(separator: ", "),
                coverURL: URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-M.jpg?default=false"),
                sourceName: "Open Library"
            )
        }
    }

    private static func makeResult(from volume: Volume) -> GoogleBookResult? {
        guard let bookTitle = volume.volumeInfo.title,
              !bookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let links = volume.volumeInfo.imageLinks
        let rawImageURL: String?
        if let links, let extraLarge = links.extraLarge {
            rawImageURL = extraLarge
        } else if let links, let large = links.large {
            rawImageURL = large
        } else if let links, let medium = links.medium {
            rawImageURL = medium
        } else if let links, let small = links.small {
            rawImageURL = small
        } else if let links, let thumbnail = links.thumbnail {
            rawImageURL = thumbnail
        } else {
            rawImageURL = links?.smallThumbnail
        }
        let coverURL = rawImageURL.flatMap { raw in
            var components = URLComponents(string: raw)
            components?.scheme = "https"
            return components?.url
        }

        return GoogleBookResult(
            id: volume.id,
            title: bookTitle,
            authors: (volume.volumeInfo.authors ?? []).joined(separator: ", "),
            coverURL: coverURL,
            sourceName: "Google Books"
        )
    }
}
