import ActivityKit
import Foundation

/// Starts/updates the water Live Activity. Lives in Shared/ because both the
/// app (logging water from Hoje/Bem-estar) and the widget extension's App
/// Intent (logging "+300" straight from the Dynamic Island) need to drive
/// the exact same activity.
///
/// Main-actor isolated because the controller is shared state used by both
/// the SwiftUI app and the widget extension's intent.
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()
    /// Live Activities are paused for now so the water status does not occupy
    /// the Dynamic Island. Re-enable this flag when that surface is ready.
    private static let isEnabled = false

    private init() {}

    func logWater(totalML: Int, goalML: Int) {
        guard Self.isEnabled, ActivityAuthorizationInfo().areActivitiesEnabled else {
            endAllActivities()
            return
        }
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

    func endAllActivities() {
        Task {
            for activity in Activity<WaterActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func staleDate() -> Date {
        Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(6 * 3600)
    }
}
