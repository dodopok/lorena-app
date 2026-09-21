import SwiftUI

/// The upcoming-appointment card — time + countdown on the left, title/place on the right.
struct NextEventCard: View {
    var event: CalendarEvent

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(LumeDateFormat.time(event.startDate))
                    .font(LumeType.serif(28))
                    .foregroundStyle(LumeColor.ink)
                LumeEyebrow(text: LumeDateFormat.relativeCountdown(to: event.startDate), size: 10.5)
            }
            .frame(minWidth: 58)

            Rectangle()
                .fill(LumeColor.brandPlumStart.opacity(0.14))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(LumeType.sans(16, weight: .heavy))
                    .foregroundStyle(LumeColor.ink)
                    .lineLimit(1)
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(LumeType.sans(13.5))
                        .foregroundStyle(LumeColor.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LumeColor.textFainter)
        }
        .padding(18)
        .lumeSoftGlass(cornerRadius: 26)
    }
}

/// The "Água de hoje" card — small ring + three quick-add buttons.
struct WaterQuickCard: View {
    var currentML: Int
    var goalML: Int
    var onAdd: (Int) -> Void

    var body: some View {
        HStack(spacing: 18) {
            WaterFillRing(
                progress: goalML > 0 ? Double(currentML) / Double(goalML) : 0,
                diameter: 98,
                valueText: LumeCurrency.integer(currentML),
                unitText: "/ \(LumeCurrency.integer(goalML))"
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("Água de hoje")
                    .font(LumeType.sans(17, weight: .heavy))
                    .foregroundStyle(LumeColor.ink)
                Text("Um copo a mais também conta.")
                    .font(LumeType.sans(13.5))
                    .foregroundStyle(LumeColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    quickAddButton(200, filled: false)
                    quickAddButton(300, filled: false)
                    quickAddButton(500, filled: true)
                }
                .padding(.top, 12)
            }
        }
        .padding(20)
        .lumeSoftGlass(cornerRadius: 26)
    }

    private func quickAddButton(_ amount: Int, filled: Bool) -> some View {
        Button {
            onAdd(amount)
        } label: {
            Text("+\(amount)")
                .font(LumeType.sans(14.5, weight: .heavy))
                .foregroundStyle(filled ? .white : LumeColor.greenText)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background {
                    let shape = RoundedRectangle(cornerRadius: 15, style: .continuous)
                    if filled {
                        shape.fill(LumeColor.greenDeep)
                    } else {
                        shape.fill(.white.opacity(0.55)).overlay(shape.strokeBorder(.white.opacity(0.8), lineWidth: 1))
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// One tile in the 3-across "Um toque" quick-log grid.
struct QuickTapTile: View {
    var symbol: String
    var tint: Color
    var iconBackground: Color
    var title: String
    var subtitle: String
    var titleColor: Color
    var subtitleColor: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tint)
                    )
                Spacer(minLength: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LumeType.sans(14.5, weight: .heavy))
                        .foregroundStyle(titleColor)
                    Text(subtitle)
                        .font(LumeType.sans(12.5))
                        .foregroundStyle(subtitleColor)
                        .lineLimit(1)
                }
            }
            .padding(EdgeInsets(top: 16, leading: 12, bottom: 14, trailing: 12))
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .lumeSoftGlass(cornerRadius: 24, shadow: false)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// A contextual next step for the home screen. It adds guidance without
/// repeating the water, bathroom and exercise cards above it.
struct TodayFocusCard: View {
    var waterML: Int
    var waterGoalML: Int
    var exerciseLogged: Bool
    var onWater: () -> Void
    var onExercise: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: focusIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(focusTint)
                .frame(width: 42, height: 42)
                .background(Circle().fill(focusBackground))

            VStack(alignment: .leading, spacing: 4) {
                Text("Um pequeno foco")
                    .font(LumeType.sans(14, weight: .heavy))
                    .foregroundStyle(LumeColor.ink)
                Text(focusMessage)
                    .font(LumeType.sans(13.5))
                    .foregroundStyle(LumeColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: focusAction) {
                Text(focusButton)
                    .font(LumeType.sans(12.5, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(LumeColor.brand))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .lumeSoftGlass(cornerRadius: 26, shadow: false)
    }

    private var focusIcon: String {
        exerciseLogged ? "drop.fill" : "figure.walk"
    }

    private var focusTint: Color {
        exerciseLogged ? LumeColor.waterBlueText : LumeColor.lavenderText
    }

    private var focusBackground: Color {
        exerciseLogged ? LumeColor.waterBlueLight.opacity(0.28) : LumeColor.lavenderChipBgFaint
    }

    private var focusMessage: String {
        if exerciseLogged {
            return waterML < waterGoalML ? "Uma pausa para água quando der mantém o dia leve." : "Você já cuidou do movimento e da água hoje."
        }
        return "Uma caminhada curta já conta — sem precisar fazer muito."
    }

    private var focusButton: String {
        exerciseLogged ? "Adicionar água" : "Registrar"
    }

    private var focusAction: () -> Void {
        exerciseLogged ? onWater : onExercise
    }
}

/// The plum "Disponível" hero card, shared between Hoje and Finanças.
struct AvailableBalanceCard: View {
    var available: Double
    var subtitle: String
    var showsSheen: Bool = true
    var subtitleBelowAmount: Bool = false
    var bottomInset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LumeEyebrow(text: "Disponível", color: LumeColor.brandOnPlumLabel)
            if subtitleBelowAmount {
                VStack(alignment: .leading, spacing: 2) {
                    balanceText
                    subtitleText
                }
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    balanceText
                    Spacer(minLength: 0)
                    subtitleText
                }
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 20 + bottomInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumePlumCard()
        .modifier(OptionalSheen(enabled: showsSheen))
    }

    private var balanceText: some View {
        Text(LumeCurrency.full(available))
            .font(LumeType.serif(44))
            .foregroundStyle(.white)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var subtitleText: some View {
        Text(subtitle)
            .font(LumeType.sans(13.5))
            .foregroundStyle(LumeColor.brandOnPlumLabel)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OptionalSheen: ViewModifier {
    var enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.lumeSheen(RoundedRectangle(cornerRadius: 30, style: .continuous), duration: 7)
        } else {
            content
        }
    }
}
