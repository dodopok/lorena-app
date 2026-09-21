import Foundation
import SwiftData

enum BookStatus: String, Codable, CaseIterable, Hashable {
    case reading
    case read
    case wantToRead

    var label: String {
        switch self {
        case .reading: "Lendo agora"
        case .read: "Lido"
        case .wantToRead: "Quero ler"
        }
    }
}

@Model
final class Book {
    var title: String
    var author: String
    var statusRaw: String
    var currentPage: Int
    var totalPages: Int
    var rating: Int
    var review: String?
    /// Seed hex color used to derive the two-stop cover gradient.
    var coverColorHex: String
    /// Optional cover selected from Google Books. The color remains as a local fallback.
    var coverURLString: String?
    /// Optional photo chosen manually from the user's library.
    @Attribute(.externalStorage) var coverImageData: Data?
    var dateAdded: Date

    init(
        title: String,
        author: String,
        status: BookStatus = .wantToRead,
        currentPage: Int = 0,
        totalPages: Int = 0,
        rating: Int = 0,
        review: String? = nil,
        coverColorHex: String = "E4D6E6",
        coverURLString: String? = nil,
        coverImageData: Data? = nil,
        dateAdded: Date = .now
    ) {
        self.title = title
        self.author = author
        self.statusRaw = status.rawValue
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.rating = rating
        self.review = review
        self.coverColorHex = coverColorHex
        self.coverURLString = coverURLString
        self.coverImageData = coverImageData
        self.dateAdded = dateAdded
    }

    var status: BookStatus {
        get { BookStatus(rawValue: statusRaw) ?? .wantToRead }
        set { statusRaw = newValue.rawValue }
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }
}
