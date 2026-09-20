import SwiftUI

enum CornerTab: String, Hashable {
    case gratitude, books, wishlist
}

struct CornerContainerView: View {
    @State private var tab: CornerTab = .gratitude

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.roseOrb, size: 300, opacity: 0.5, blur: 58, alignment: .topLeading, offset: CGSize(width: -70, height: -50), duration: 17),
        OrbSpec(color: LumeColor.lavenderOrb, size: 280, opacity: 0.45, blur: 58, alignment: .topTrailing, offset: CGSize(width: 90, height: 400), duration: 21, reversed: true),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LumeColor.canvas.ignoresSafeArea()
                LumeOrbBackground(orbs: orbs)

                VStack(spacing: 14) {
                    Text("Cantinho")
                        .font(LumeType.serif(32))
                        .foregroundStyle(LumeColor.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .lumeRiseIn()

                    LumeSegmentedControl(
                        options: [(CornerTab.gratitude, "Gratidão"), (.books, "Livros"), (.wishlist, "Desejos")],
                        selection: $tab
                    )
                    .padding(.horizontal, 20)

                    Group {
                        switch tab {
                        case .gratitude: GratitudeTabView()
                        case .books: BooksTabView()
                        case .wishlist: WishlistTabView()
                        }
                    }
                }
                .padding(.top, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
