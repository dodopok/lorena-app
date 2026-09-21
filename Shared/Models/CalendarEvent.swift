import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var id: UUID
    var title: String
    var location: String?
    var startDate: Date
    var endDate: Date?
    var categoryRaw: String
    var remindToLogExpense: Bool
    var loggedExpense: Bool

    init(
        id: UUID = UUID(),
        title: String,
        location: String? = nil,
        startDate: Date,
        endDate: Date? = nil,
        category: AgendaCategory = .pessoal,
        remindToLogExpense: Bool = false,
        loggedExpense: Bool = false
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.categoryRaw = category.rawValue
        self.remindToLogExpense = remindToLogExpense
        self.loggedExpense = loggedExpense
    }

    var category: AgendaCategory {
        get { AgendaCategory(rawValue: categoryRaw) ?? .pessoal }
        set { categoryRaw = newValue.rawValue }
    }

    var timeRangeLabel: String {
        guard let endDate else { return LumeDateFormat.time(startDate) }
        return "\(LumeDateFormat.time(startDate)) – \(LumeDateFormat.time(endDate))"
    }
}
