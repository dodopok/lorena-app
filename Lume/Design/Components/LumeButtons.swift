import SwiftUI

/// Solid, full-width call-to-action button — "Continuar", "Guardar desejo", etc.
struct LumePrimaryButton: View {
    var title: String
    var color: Color = LumeColor.brand
    var isEnabled: Bool = true
    var height: CGFloat = 56
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LumeType.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.45)
        .disabled(!isEnabled)
        .sensoryFeedback(.impact(weight: .medium), trigger: isEnabled)
    }
}

/// Full-width translucent Liquid Glass button — "Usar só neste iPhone", secondary actions.
struct LumeGlassButton: View {
    var title: String
    var textColor: Color = LumeColor.textSecondary
    var height: CGFloat = 56
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LumeType.sans(16, weight: .bold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.glass)
    }
}

/// Quiet text-only button — "Pular", "Cancelar".
struct LumeTextButton: View {
    var title: String
    var color: Color = LumeColor.textFaint
    var weight: Font.Weight = .semibold
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LumeType.sans(15, weight: weight))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Round glass icon button — the +/- steppers, the round "+" in Agenda headers.
struct LumeGlassIconButton: View {
    var systemImage: String
    var size: CGFloat = 58
    var iconSize: CGFloat = 22
    var tint: Color = LumeColor.brand
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.glass)
    }
}

/// Round *solid* icon button — the pink "+" FAB in Finanças, the water-goal
/// stepper's "+" in onboarding. Unlike `LumeGlassIconButton`, this one is a
/// flat filled circle, matching the mockup's non-glass primary controls.
struct LumeSolidIconButton: View {
    var systemImage: String
    var size: CGFloat = 58
    var iconSize: CGFloat = 22
    var color: Color = LumeColor.brand
    var pulses: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(color))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(OptionalPulse(enabled: pulses, color: color))
    }
}

/// Floating add action shared by list screens, positioned above the app tab bar.
struct LumeFloatingActionButton: View {
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        LumeSolidIconButton(
            systemImage: "plus",
            size: 62,
            iconSize: 26,
            color: LumeColor.brand,
            pulses: true,
            action: action
        )
        .accessibilityLabel(accessibilityLabel)
        .shadow(color: LumeColor.brand.opacity(0.4), radius: 16, x: 0, y: 10)
        .padding(.trailing, 22)
        .padding(.bottom, 118)
    }
}

/// Menu variant of the shared floating add action, for screens with multiple
/// kinds of items to create.
struct LumeFloatingActionMenu<Actions: View>: View {
    var accessibilityLabel: String
    @ViewBuilder var actions: () -> Actions

    init(accessibilityLabel: String, @ViewBuilder actions: @escaping () -> Actions) {
        self.accessibilityLabel = accessibilityLabel
        self.actions = actions
    }

    var body: some View {
        Menu {
            actions()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(Circle().fill(LumeColor.brand))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .lumePulse(Circle(), color: LumeColor.brand)
        .shadow(color: LumeColor.brand.opacity(0.4), radius: 16, x: 0, y: 10)
        .padding(.trailing, 22)
        .padding(.bottom, 118)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct OptionalPulse: ViewModifier {
    var enabled: Bool
    var color: Color

    func body(content: Content) -> some View {
        if enabled {
            content.lumePulse(Circle(), color: color)
        } else {
            content
        }
    }
}

/// Small rounded pill chip used for filters and category selectors.
struct LumeChip: View {
    var title: String
    var isSelected: Bool
    var selectedColor: Color = LumeColor.brand
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LumeType.sans(13.5, weight: isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? .white : LumeColor.textSecondary)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .frame(minHeight: 38)
                .background {
                    if isSelected {
                        Capsule().fill(selectedColor)
                    } else {
                        Capsule()
                            .fill(.white.opacity(0.55))
                            .overlay(Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A three-way segmented glass control — "Dia / Semana / Mês", "Gratidão / Livros / Desejos".
struct LumeSegmentedControl<Option: Hashable>: View {
    var options: [(value: Option, label: String)]
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 5) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    withAnimation(.easeOut(duration: 0.22)) { selection = option.value }
                } label: {
                    Text(option.label)
                        .font(LumeType.sans(13.5, weight: isSelected ? .heavy : .bold))
                        .foregroundStyle(isSelected ? .white : LumeColor.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule().fill(LumeColor.brand)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(.white.opacity(0.5))
        .overlay(Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1))
        .clipShape(Capsule())
    }
}
