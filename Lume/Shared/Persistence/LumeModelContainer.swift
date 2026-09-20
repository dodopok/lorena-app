import Foundation
import SwiftData

/// Builds the one SwiftData container Lume uses everywhere — the main app,
/// the widget extension's Live Activity views, and the App Intents that
/// handle taps from the Dynamic Island. Storing it in the shared App Group
/// container is what lets all three read and write the same data.
enum LumeModelContainer {
    static let appGroupID = "group.com.dodopok.lume"

    static var schema: Schema {
        Schema([
            UserProfile.self,
            WaterEntry.self,
            BathroomEntry.self,
            Expense.self,
            CalendarEvent.self,
            GratitudeEntry.self,
            Book.self,
            WishlistItem.self,
            ExerciseEntry.self,
        ])
    }

    static func make() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupID)
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Não foi possível criar o ModelContainer do Lume: \(error)")
        }
    }
}
