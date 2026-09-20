import SwiftUI

/// The "Cancelar · Title · Salvar" header used by every modal composer
/// (Banheiro, Novo gasto, Exercício, Gratidão, Novo desejo).
struct LumeSheetHeader: View {
    var leadingTitle: String
    var title: String
    var trailingTitle: String
    var trailingEnabled: Bool = true
    var trailingIsDestructive: Bool = false
    var onLeading: () -> Void
    var onTrailing: () -> Void

    var body: some View {
        HStack {
            Button(action: onLeading) {
                Text(leadingTitle)
                    .font(LumeType.sans(15.5, weight: .bold))
                    .foregroundStyle(LumeColor.textFaint)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(LumeType.serif(21))
                .foregroundStyle(LumeColor.ink)

            Spacer()

            Button(action: onTrailing) {
                Text(trailingTitle)
                    .font(LumeType.sans(15.5, weight: .heavy))
                    .foregroundStyle(trailingColor)
            }
            .buttonStyle(.plain)
            .disabled(!trailingEnabled)
        }
    }

    private var trailingColor: Color {
        if trailingIsDestructive { return LumeColor.errorText }
        return trailingEnabled ? LumeColor.brand : LumeColor.brand.opacity(0.35)
    }
}

/// Uppercase mono section label used inside cards and lists ("HOJE", "CATEGORIA"...).
struct LumeSectionLabel: View {
    var text: String
    var trailing: String?
    var trailingColor: Color = LumeColor.brand
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            LumeEyebrow(text: text)
            Spacer()
            if let trailing {
                if let trailingAction {
                    Button(action: trailingAction) {
                        Text(trailing)
                            .font(LumeType.sans(14, weight: .bold))
                            .foregroundStyle(trailingColor)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(trailing)
                        .font(LumeType.sans(14, weight: .bold))
                        .foregroundStyle(trailingColor)
                }
            }
        }
    }
}
