import SwiftUI
import SwiftData

@main
struct LumeApp: App {
    let container = LumeModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
