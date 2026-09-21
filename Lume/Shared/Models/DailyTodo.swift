import Foundation
import SwiftData

@Model
final class DailyTodo {
    var title: String
    var date: Date
    var isCompleted: Bool
    var createdAt: Date

    init(title: String, date: Date = .now.startOfDay, isCompleted: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.date = date.startOfDay
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
