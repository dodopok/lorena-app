import Foundation
import SwiftData

enum WatchStatus: String, Codable, CaseIterable, Hashable {
    case watching
    case watched
    case wantToWatch

    var label: String {
        switch self {
        case .watching: "Assistindo"
        case .watched: "Assistido"
        case .wantToWatch: "Quero assistir"
        }
    }
}

@Model
final class MovieShow {
    var title: String
    var kind: String
    var year: Int?
    var imageURLString: String?
    var sourceURLString: String?
    var statusRaw: String
    var rating: Int?
    var review: String?
    var dateAdded: Date

    init(
        title: String,
        kind: String,
        year: Int? = nil,
        imageURLString: String? = nil,
        sourceURLString: String? = nil,
        status: WatchStatus = .wantToWatch,
        rating: Int? = nil,
        review: String? = nil,
        dateAdded: Date = .now
    ) {
        self.title = title
        self.kind = kind
        self.year = year
        self.imageURLString = imageURLString
        self.sourceURLString = sourceURLString
        self.statusRaw = status.rawValue
        self.rating = rating
        self.review = review
        self.dateAdded = dateAdded
    }

    var status: WatchStatus {
        get { WatchStatus(rawValue: statusRaw) ?? .wantToWatch }
        set { statusRaw = newValue.rawValue }
    }
}
