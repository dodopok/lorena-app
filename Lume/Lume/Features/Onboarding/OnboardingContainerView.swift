import SwiftUI
import SwiftData

/// Hosts the three onboarding steps and saves the finished profile.
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var draft = OnboardingDraft()
    var onComplete: () -> Void

    var body: some View {
        Group {
            switch draft.step {
            case 0:
                WelcomeStepView(draft: draft) {
                    withAnimation(.easeInOut(duration: 0.35)) { draft.step = 1 }
                }
            case 1:
                WaterGoalStepView(draft: draft) {
                    withAnimation(.easeInOut(duration: 0.35)) { draft.step = 2 }
                }
            default:
                AllowanceStepView(draft: draft) {
                    saveAndFinish()
                }
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.35), value: draft.step)
    }

    private func saveAndFinish() {
        let profile = UserProfile(
            name: draft.name.trimmingCharacters(in: .whitespaces),
            waterGoalML: draft.waterGoalML,
            allowanceAmount: draft.allowanceAmount,
            allowanceDay: draft.allowanceDay,
            authMethodRaw: draft.authMethod.rawValue,
            hasCompletedOnboarding: true
        )
        modelContext.insert(profile)
        try? modelContext.save()
        NotificationScheduler.shared.scheduleDefaultReminders(for: profile)
        onComplete()
    }
}
