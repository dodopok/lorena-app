import Foundation
import SwiftData

@Model
final class Expense {
    var title: String
    var amount: Double
    var categoryRaw: String
    var date: Date

    init(title: String, amount: Double, category: FinanceCategory, date: Date = .now) {
        self.title = title
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.date = date
    }

    var category: FinanceCategory {
        get { FinanceCategory(rawValue: categoryRaw) ?? .mercado }
        set { categoryRaw = newValue.rawValue }
    }
}
