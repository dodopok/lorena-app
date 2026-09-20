import ActivityKit
import Foundation

/// Starts/updates the water Live Activity. Lives in Shared/ because both the
/// app (logging water from Hoje/Bem-estar) and the widget extension's App
/// Intent (logging "+300" straight from the Dynamic Island) need to drive
/// the exact same activity.
///
/// Deliberately not `@MainActor`: ActivityKit's `Activity` APIs don't require
/// it, and staying unisolated lets both plain SwiftUI view code and the
/// widget extension's `@MainActor` intent call `logWater` without friction.
final class LiveActivityController {
    static let shared = LiveActivityController()
    private init() {}

    func logWater(totalML: Int, goalML: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = WaterActivityAttributes.ContentState(currentML: totalML, goalML: goalML, lastLoggedAt: .now)
        let content = ActivityContent(state: state, staleDate: staleDate())

        if let activity = Activity<WaterActivityAttributes>.activities.first(where: { $0.attributes.startedAt.isSameDay(as: .now) }) {
            Task { await activity.update(content) }
            return
        }

        Task {
            for activity in Activity<WaterActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            let attributes = WaterActivityAttributes(startedAt: .now)
            _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
        }
    }

    private func staleDate() -> Date {
        Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(6 * 3600)
    }
}
