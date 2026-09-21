import ActivityKit
import Foundation

/// Shape of the water Live Activity / Dynamic Island. Lives in Shared/ so the
/// app (which starts/updates it) and the widget extension (which renders it)
/// agree on the exact same type.
struct WaterActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentML: Int
        var goalML: Int
        var lastLoggedAt: Date

        var progress: Double {
            guard goalML > 0 else { return 0 }
            return min(1, Double(currentML) / Double(goalML))
        }
    }

    var startedAt: Date
}
