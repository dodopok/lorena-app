import Foundation
import UserNotifications

/// Local-only notifications — water nudges through the day, a nightly
/// gratitude prompt, and per-event "did you log that expense?" reminders.
/// Nothing here talks to a server; everything is scheduled on-device.
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()
    private let waterHours = [10, 13, 16, 19]

    private init() {}

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    /// Reconciles the recurring water/gratidão notifications with the
    /// profile's current toggles. Safe to call any time a toggle changes.
    func scheduleDefaultReminders(for profile: UserProfile) {
        requestAuthorizationIfNeeded()

        center.removePendingNotificationRequests(withIdentifiers: waterHours.map { "lume.water.reminder.\($0)" })
        center.removePendingNotificationRequests(withIdentifiers: ["lume.gratitude.reminder"])

        if profile.waterRemindersEnabled {
            scheduleWaterReminders()
        }
        if profile.gratitudeReminderEnabled {
            scheduleGratitudeReminder()
        }
    }

    private func scheduleWaterReminders() {
        for hour in waterHours {
            let content = UNMutableNotificationContent()
            content.title = "Lume"
            content.body = waterCopy(for: hour)
            content.sound = .default

            var comps = DateComponents()
            comps.hour = hour
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: "lume.water.reminder.\(hour)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    private func waterCopy(for hour: Int) -> String {
        switch hour {
        case 10: "Um copo d'água pra começar bem o dia."
        case 13: "Hora de mais um copo d'água."
        case 16: "Que tal um pouco de água agora?"
        default: "Faltam alguns copos até a meta de hoje."
        }
    }

    private func scheduleGratitudeReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Lume"
        content.body = "Algo bom aconteceu hoje?"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 21
        comps.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "lume.gratitude.reminder", content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedules (or cancels) the "did you log that expense?" nudge for one event.
    func scheduleExpenseReminder(for event: CalendarEvent, enabled: Bool = true) {
        let identifier = "lume.expense.reminder.\(event.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        let fireDate = (event.endDate ?? event.startDate).addingTimeInterval(3600)
        guard fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Lume"
        content.body = "Como foi em \(event.title)? Se pagou algo, dá para anotar daqui mesmo."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelExpenseReminder(for event: CalendarEvent) {
        center.removePendingNotificationRequests(withIdentifiers: ["lume.expense.reminder.\(event.id.uuidString)"])
    }
}
