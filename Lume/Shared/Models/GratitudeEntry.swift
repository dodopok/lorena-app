import Foundation
import SwiftData

@Model
final class GratitudeEntry {
    var text: String
    var date: Date
    @Attribute(.externalStorage) var photoData: Data?

    init(text: String, date: Date = .now, photoData: Data? = nil) {
        self.text = text
        self.date = date
        self.photoData = photoData
    }
}
