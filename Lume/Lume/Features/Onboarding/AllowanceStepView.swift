import SwiftUI

/// Screen 03 — the monthly allowance and which day it lands, the last
/// onboarding step. Saving here is what completes onboarding.
struct AllowanceStepView: View {
    @Bindable var draft: OnboardingDraft
    var onFinish: () -> Void

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.amberOrb, size: 300, opacity: 0.55, blur: 58, alignment: .topTrailing, offset: CGSize(width: 90, height: 80), duration: 16),
        OrbSpec(color: LumeColor.roseOrb, size: 240, opacity: 0.5, blur: 52, alignment: .topLeading, offset: CGSize(width: -70, height: 340), duration: 20, reversed: true),
    ]

    var body: some View {
        ZStack {
            LumeColor.canvas.ignoresSafeArea()
            LumeOrbBackground(orbs: orbs)

            VStack(alignment: .leading, spacing: 0) {
                OnboardingProgressBar(filledCount: 3)

                Text("Sua mesada do mês")
                    .font(LumeType.serif(34))
                    .foregroundStyle(LumeColor.ink)
                    .padding(.top, 28)
                    .lumeRiseIn()

                Text("É o valor que entra todo mês. O Lume cuida do resto.")
                    .font(LumeType.sans(15.5))
                    .foregroundStyle(LumeColor.textTertiary)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 10) {
                    LumeEyebrow(text: "Valor mensal", color: LumeColor.amberLabel)
                    LumeAmountField(digits: $draft.allowanceDigits, fontSize: 50, color: LumeColor.ink)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lumeSoftGlass(cornerRadius: 28)
                .padding(.top, 22)
                .lumeRiseIn(delay: 0.08)

                HStack(spacing: 10) {
                    Menu {
                        Picker("Dia", selection: $draft.allowanceDay) {
                            ForEach(1...28, id: \.self) { day in
                                Text("Dia \(day)").tag(day)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Cai todo dia")
                                .font(LumeType.sans(12.5))
                                .foregroundStyle(LumeColor.textFaint)
                            Text("\(draft.allowanceDay)")
                                .font(LumeType.sans(19, weight: .heavy))
                                .foregroundStyle(LumeColor.ink)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                    }
                    .lumeSoftGlass(cornerRadius: 20, opacity: 0.5)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("O que sobrar")
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                        Text("Fica pra você")
                            .font(LumeType.sans(16.5, weight: .heavy))
                            .foregroundStyle(LumeColor.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .lumeSoftGlass(cornerRadius: 20, opacity: 0.5)
                }
                .padding(.top, 12)
                .lumeRiseIn(delay: 0.14)

                Spacer()

                LumePrimaryButton(title: "Continuar", action: onFinish)
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
    }
}
