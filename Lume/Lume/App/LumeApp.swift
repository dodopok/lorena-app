import SwiftUI
import SwiftData

@main
struct LumeApp: App {
    let container = LumeModelContainer.make()
    @StateObject private var route = LumeRoute()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(route)
                .onOpenURL { url in
                    route.receive(url)
                }
                .task {
                    LiveActivityController.shared.endAllActivities()
                    route.consumeStoredShare()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        route.consumeStoredShare()
                    }
                }
        }
        .modelContainer(container)
    }
}
