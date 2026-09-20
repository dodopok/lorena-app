import AppIntents
import Foundation
import SwiftData

/// Backs the "+300" button on the Live Activity / Dynamic Island — runs right
/// there, in the widget extension process, without opening the app.
struct LogWaterIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Registrar água"
    static var description = IntentDescription("Adiciona água ao total de hoje.")

    @Parameter(title: "Quantidade (ml)")
    var amountML: Int

    init() {
        amountML = 300
    }

    init(amountML: Int) {
        self.amountML = amountML
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = LumeModelContainer.make()
        let context = ModelContext(container)

        context.insert(WaterEntry(amountML: amountML))
        try? context.save()

        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        let goal = profile?.waterGoalML ?? 2000

        let todayStart = Date.now.startOfDay
        let allEntries = (try? context.fetch(FetchDescriptor<WaterEntry>())) ?? []
        let total = allEntries.filter { $0.date >= todayStart }.reduce(0) { $0 + $1.amountML }

        LiveActivityController.shared.logWater(totalML: total, goalML: goal)

        return .result()
    }
}
