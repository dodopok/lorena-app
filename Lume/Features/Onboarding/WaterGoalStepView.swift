import SwiftUI

/// Screen 02 — pick a daily water goal. The ring's fill is a decorative
/// preview (not tied to real progress, since nothing's been logged yet).
struct WaterGoalStepView: View {
    @Bindable var draft: OnboardingDraft
    var onContinue: () -> Void

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.greenOrb, size: 280, opacity: 0.5, blur: 58, alignment: .topLeading, offset: CGSize(width: -60, height: 120), duration: 15),
        OrbSpec(color: LumeColor.roseOrb, size: 240, opacity: 0.5, blur: 54, alignment: .bottomTrailing, offset: CGSize(width: -60, height: -40), duration: 19, reversed: true),
    ]

    var body: some View {
        ZStack {
            LumeColor.canvas.ignoresSafeArea()
            LumeOrbBackground(orbs: orbs)

            VStack(alignment: .leading, spacing: 0) {
                OnboardingProgressBar(filledCount: 2)

                Text("Quanta água por dia?")
                    .font(LumeType.serif(34))
                    .foregroundStyle(LumeColor.ink)
                    .padding(.top, 28)
                    .lumeRiseIn()

                Text("Dá para mudar quando quiser.")
                    .font(LumeType.sans(15.5))
                    .foregroundStyle(LumeColor.textTertiary)
                    .padding(.top, 8)

                HStack {
                    Spacer()
                    WaterFillRing(progress: 0.46, diameter: 250, valueText: LumeCurrency.integer(draft.waterGoalML), unitText: "ML / DIA")
                    Spacer()
                }
                .padding(.top, 32)
                .lumeRiseIn(delay: 0.05)

                HStack(spacing: 16) {
                    LumeGlassIconButton(systemImage: "minus", size: 58, iconSize: 22, tint: LumeColor.brand) {
                        adjust(-100)
                    }
                    Text("passo 100 ml")
                        .font(LumeType.mono(12))
                        .foregroundStyle(LumeColor.textFaint)
                        .frame(width: 90)
                    LumeSolidIconButton(systemImage: "plus", size: 58, iconSize: 22, color: LumeColor.brand, pulses: true) {
                        adjust(100)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 28)

                Spacer()

                VStack(spacing: 4) {
                    LumePrimaryButton(title: "Continuar", action: onContinue)
                    LumeTextButton(title: "Pular", color: LumeColor.textFaint, action: onContinue)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
    }

    private func adjust(_ delta: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            draft.waterGoalML = min(5000, max(500, draft.waterGoalML + delta))
        }
    }
}
