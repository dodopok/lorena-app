import SwiftUI

/// The five-tab shell, floating glass bar over whichever tab is active.
struct RootTabContainer: View {
    @State private var selection: LumeTab = .hoje

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .hoje: TodayView()
                case .agenda: AgendaContainerView()
                case .bemEstar: BemEstarView()
                case .financas: FinanceView()
                case .cantinho: CornerContainerView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LumeTabBar(selection: $selection)
                .padding(.bottom, 6)
        }
    }
}
