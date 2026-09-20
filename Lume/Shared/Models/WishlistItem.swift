import Foundation
import SwiftData

@Model
final class WishlistItem {
    var name: String
    var price: Double
    var originalPrice: Double?
    var sourceURLString: String?
    @Attribute(.externalStorage) var imageData: Data?
    var listName: String
    var notifyOnPriceDrop: Bool
    var dateAdded: Date
    var purchased: Bool

    init(
        name: String,
        price: Double,
        originalPrice: Double? = nil,
        sourceURLString: String? = nil,
        imageData: Data? = nil,
        listName: String = "Geral",
        notifyOnPriceDrop: Bool = true,
        dateAdded: Date = .now,
        purchased: Bool = false
    ) {
        self.name = name
        self.price = price
        self.originalPrice = originalPrice
        self.sourceURLString = sourceURLString
        self.imageData = imageData
        self.listName = listName
        self.notifyOnPriceDrop = notifyOnPriceDrop
        self.dateAdded = dateAdded
        self.purchased = purchased
    }

    var sourceHost: String? {
        guard let sourceURLString, let url = URL(string: sourceURLString) else { return nil }
        return url.host?.replacingOccurrences(of: "www.", with: "")
    }

    var discountPercent: Int? {
        guard let originalPrice, originalPrice > price, originalPrice > 0 else { return nil }
        return Int(((originalPrice - price) / originalPrice * 100).rounded())
    }
}
