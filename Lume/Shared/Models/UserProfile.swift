import Foundation
import SwiftData

/// A single row holds the whole household's settings — Lume is a one-person
/// app with no accounts, so we just ensure exactly one `UserProfile` exists.
@Model
final class UserProfile {
    var name: String
    var waterGoalML: Int
    var allowanceAmount: Double
    var allowanceDay: Int
    var authMethodRaw: String
    var faceIDEnabled: Bool
    var waterRemindersEnabled: Bool
    var gratitudeReminderEnabled: Bool
    var postEventExpenseReminderEnabled: Bool
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    init(
        name: String = "",
        waterGoalML: Int = 2000,
        allowanceAmount: Double = 0,
        allowanceDay: Int = 5,
        authMethodRaw: String = AuthMethod.local.rawValue,
        faceIDEnabled: Bool = false,
        waterRemindersEnabled: Bool = true,
        gratitudeReminderEnabled: Bool = true,
        postEventExpenseReminderEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = .now
    ) {
        self.name = name
        self.waterGoalML = waterGoalML
        self.allowanceAmount = allowanceAmount
        self.allowanceDay = allowanceDay
        self.authMethodRaw = authMethodRaw
        self.faceIDEnabled = faceIDEnabled
        self.waterRemindersEnabled = waterRemindersEnabled
        self.gratitudeReminderEnabled = gratitudeReminderEnabled
        self.postEventExpenseReminderEnabled = postEventExpenseReminderEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
    }

    var initial: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "L"
    }

    var authMethod: AuthMethod {
        get { AuthMethod(rawValue: authMethodRaw) ?? .local }
        set { authMethodRaw = newValue.rawValue }
    }

    /// The next date the allowance lands, given today.
    func nextAllowanceDate(from date: Date = .now) -> Date {
        let calendar = LumeDateFormat.calendar
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = allowanceDay
        let candidate = calendar.date(from: components) ?? date
        if candidate > date { return candidate }
        return calendar.date(byAdding: .month, value: 1, to: candidate) ?? candidate
    }

    /// The start of the current allowance cycle (the most recent allowance date on/before today).
    func currentCycleStart(from date: Date = .now) -> Date {
        let calendar = LumeDateFormat.calendar
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = allowanceDay
        let candidate = calendar.date(from: components) ?? date
        if candidate <= date { return candidate }
        return calendar.date(byAdding: .month, value: -1, to: candidate) ?? candidate
    }
}

enum AuthMethod: String, Codable, Hashable {
    case apple
    case local
}
