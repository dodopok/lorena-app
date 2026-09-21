import Foundation
import SwiftData

@Model
final class ShoppingList {
    var name: String
    var dateCreated: Date

    init(name: String, dateCreated: Date = .now) {
        self.name = name
        self.dateCreated = dateCreated
    }
}
