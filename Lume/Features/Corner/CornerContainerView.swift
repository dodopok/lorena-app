import SwiftUI

enum CornerTab: String, Hashable, CaseIterable {
    case gratitude, books, movies, wishlist, words

    var title: String {
        switch self {
        case .gratitude: "Gratidão"
        case .books: "Livros"
        case .movies: "Filmes"
        case .wishlist: "Desejos"
        case .words: "Palavras"
        }
    }
}

struct CornerContainerView: View {
    @State private var tab: CornerTab = .gratitude
    @EnvironmentObject private var route: LumeRoute

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

                    cornerTabs
                    .padding(.horizontal, 20)

                    Group {
                        switch tab {
                        case .gratitude: GratitudeTabView()
                        case .books: BooksTabView()
                        case .movies: MoviesTabView()
                        case .wishlist: WishlistTabView()
                        case .words: WordOfDayTabView()
                        }
                    }
                }
                .padding(.top, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if route.pendingSharedURL != nil {
                tab = .wishlist
            }
        }
        .onChange(of: route.pendingSharedURL) { _, newURL in
            if newURL != nil {
                tab = .wishlist
            }
        }
    }

    private var cornerTabs: some View {
        HStack(spacing: 5) {
            ForEach(CornerTab.allCases, id: \.self) { option in
                let isSelected = option == tab

                Button {
                    withAnimation(.easeOut(duration: 0.22)) { tab = option }
                } label: {
                    Group {
                        if option == .words {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 16, weight: isSelected ? .bold : .semibold))
                        } else {
                            Text(option.title)
                                .font(LumeType.sans(13.5, weight: isSelected ? .heavy : .bold))
                        }
                    }
                    .foregroundStyle(isSelected ? .white : LumeColor.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if isSelected { Capsule().fill(LumeColor.brand) }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityHint(option == .words ? "Abre o jogo Palavra do dia" : "Abre a seção (option.title)")
            }
        }
        .padding(5)
        .background(.white.opacity(0.5))
        .overlay(Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1))
        .clipShape(Capsule())
    }
}
