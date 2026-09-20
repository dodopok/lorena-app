import Foundation

/// Holds in-progress answers across the three onboarding steps until the
/// last step saves them into a real `UserProfile`.
@Observable
final class OnboardingDraft {
    var step: Int = 0
    var name: String = ""
    var authMethod: AuthMethod = .local
    var waterGoalML: Int = 2000
    var allowanceDigits: String = "120000" // R$ 1.200,00
    var allowanceDay: Int = 5

    var allowanceAmount: Double { LumeCurrency.amount(fromDigits: allowanceDigits) }
}
