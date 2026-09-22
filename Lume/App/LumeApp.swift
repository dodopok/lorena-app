import SwiftUI
import SwiftData

@main
struct LumeApp: App {
    let container = LumeModelContainer.make()
    @StateObject private var route = LumeRoute()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        LumeCloudBackupService.registerBackgroundTask()
        LumeCloudBackupService.scheduleNextBackup()
    }

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
                    _ = await LumeCloudBackupService.shared.backupIfNeeded()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        route.consumeStoredShare()
                        Task {
                            _ = await LumeCloudBackupService.shared.backupIfNeeded()
                        }
                    }
                }
        }
        .modelContainer(container)
    }
}
