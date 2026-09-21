import SwiftUI
import SwiftData

/// Onboarding until a profile exists, the tab shell after, with an optional
/// Face ID gate layered on top.
struct RootView: View {
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Environment(\.scenePhase) private var scenePhase
    @State private var lockController = AppLockController()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if let profile, profile.hasCompletedOnboarding {
                ZStack {
                    RootTabContainer()
                    if lockController.isLocked {
                        LockGateView { lockController.unlock() }
                            .transition(.opacity)
                    }
                }
            } else {
                OnboardingContainerView {}
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lockController.isLocked)
        .preferredColorScheme(.light)
        .task {
            guard let profile else { return }
            NotificationScheduler.shared.scheduleDefaultReminders(for: profile)
            if profile.faceIDEnabled {
                lockController.isLocked = true
                lockController.unlock()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            guard let profile, profile.faceIDEnabled else { return }
            if newPhase == .background {
                lockController.isLocked = true
            } else if newPhase == .active, oldPhase == .background {
                lockController.unlock()
            }
        }
    }
}
