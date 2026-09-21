import SwiftUI

enum LumeTab: String, CaseIterable, Identifiable, Codable, Hashable {
    case hoje, agenda, bemEstar, financas, cantinho

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hoje: "Hoje"
        case .agenda: "Agenda"
        case .bemEstar: "Bem-estar"
        case .financas: "Finanças"
        case .cantinho: "Cantinho"
        }
    }

    var symbol: String {
        switch self {
        case .hoje: "sun.max.fill"
        case .agenda: "calendar"
        case .bemEstar: "drop.fill"
        case .financas: "wallet.pass.fill"
        case .cantinho: "book.fill"
        }
    }
}

/// The floating 5-tab Liquid Glass bar that replaces every tab-bar mock in the
/// design (they're all the same bar, just with a different active item).
struct LumeTabBar: View {
    @Binding var selection: LumeTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LumeTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .lumeGlass(cornerRadius: 30)
        .padding(.horizontal, 12)
    }

    private func tabButton(_ tab: LumeTab) -> some View {
        let isSelected = tab == selection
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(LumeColor.brand)
                            .frame(width: 48, height: 30)
                    }
                    Image(systemName: tab.symbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? .white : LumeColor.textFaint)
                }
                Text(tab.label)
                    .font(LumeType.sans(11, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? LumeColor.brand : LumeColor.textFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
