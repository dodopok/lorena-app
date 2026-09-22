import Foundation
import SwiftData

/// Builds the SwiftData container Lume uses everywhere — the main app, the
/// widget extension's Live Activity views, and the App Intents that handle
/// taps from the Dynamic Island. When the App Group is provisioned, all three
/// processes share the same store. A local fallback keeps the app usable when
/// a development or TestFlight profile has not received that capability yet.
enum LumeModelContainer {
    static let appGroupID = "group.com.dodopok.lume"

    static var schema: Schema {
        Schema([
            UserProfile.self,
            WaterEntry.self,
            BathroomEntry.self,
            Expense.self,
            MoneyAddition.self,
            CalendarEvent.self,
            DailyTodo.self,
            GratitudeEntry.self,
            Book.self,
            MovieShow.self,
            WishlistItem.self,
            ShoppingList.self,
            ExerciseEntry.self,
            WordDayProgress.self,
        ])
    }

    static func make() -> ModelContainer {
        do {
            return try makeForCurrentStore()
        } catch {
            fatalError("Não foi possível criar o ModelContainer do Lume: \(error)")
        }
    }

    /// Opens the same App Group or local store selected by `make()`, for
    /// background work that needs its own SwiftData context.
    static func makeForCurrentStore() throws -> ModelContainer {
        let configuration: ModelConfiguration
        // Backups use CKContainer directly. SwiftData's automatic CloudKit
        // sync rejects this schema because many model fields are required.
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil {
            configuration = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupID),
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
