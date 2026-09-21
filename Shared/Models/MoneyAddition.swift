import Foundation
import SwiftData

@Model
final class MoneyAddition {
    var title: String
    var amount: Double
    var date: Date

    init(title: String = "Dinheiro adicionado", amount: Double, date: Date = .now) {
        self.title = title
        self.amount = amount
        self.date = date
    }
}
