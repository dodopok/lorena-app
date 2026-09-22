import SwiftUI
import SwiftData

struct MoviesTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \MovieShow.dateAdded, order: .reverse) private var savedItems: [MovieShow]

    @State private var showingAddSearch = false
    @State private var movieToReview: MovieShow?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
              VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Minha lista")
                            .font(LumeType.sans(17, weight: .heavy))
                            .foregroundStyle(LumeColor.ink)
                        Spacer()
                        Text("\(savedItems.count) salvos")
                            .font(LumeType.sans(13))
                            .foregroundStyle(LumeColor.textFaint)
                    }

                    if savedItems.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "popcorn.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(LumeColor.textFainter)
                            Text("Toque no botão + para pesquisar um filme ou uma série.")
                                .font(LumeType.sans(14))
                                .foregroundStyle(LumeColor.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .lumeSoftGlass(cornerRadius: 24, shadow: false)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(savedItems, id: \.persistentModelID) { item in
                                MovieShowCard(item: item, onOpen: openSource, onReview: { movieToReview = $0 }, onDelete: delete)
                            }
                        }
                    }
                }

                Color.clear.frame(height: 170)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            }

            LumeFloatingActionButton(accessibilityLabel: "Adicionar filme ou série") {
                showingAddSearch = true
            }
        }
        .sheet(isPresented: $showingAddSearch) {
            MovieAddSearchSheet(savedItems: savedItems)
        }
        .sheet(item: $movieToReview) { movie in
            MovieShowReviewSheet(movie: movie)
        }
    }

    private func openSource(_ item: MovieShow) {
        guard let sourceURLString = item.sourceURLString, let url = URL(string: sourceURLString) else { return }
        openURL(url)
    }

    private func delete(_ item: MovieShow) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

private struct MovieAddSearchSheet: View {
    let savedItems: [MovieShow]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var results: [EntertainmentSearchResult] = []
    @State private var isSearching = false

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: "Adicionar título",
                trailingTitle: " ",
                trailingEnabled: false,
                onLeading: { dismiss() },
                onTrailing: {}
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 16) {
                    searchField

                    if isSearching {
                        ProgressView()
                            .tint(LumeColor.brand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else if !results.isEmpty {
                        searchResults
                    } else if query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                        Text("Nada encontrado por aqui.")
                            .font(LumeType.sans(14))
                            .foregroundStyle(LumeColor.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        Text("Busque um filme ou uma série e toque no resultado para adicionar.")
                            .font(LumeType.sans(14))
                            .foregroundStyle(LumeColor.textMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task(id: query) {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 2 else {
                results = []
                isSearching = false
                return
            }
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            let found = await EntertainmentSearchService.search(title: trimmed)
            guard !Task.isCancelled else { return }
            results = found
            isSearching = false
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LumeColor.textFainter)
            TextField("Buscar filme ou série", text: $query)
                .font(LumeType.sans(15.5))
                .foregroundStyle(LumeColor.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LumeColor.textFainter)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.7)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 10) {
            LumeEyebrow(text: "Resultados")
            LazyVStack(spacing: 10) {
                ForEach(results) { result in
                    Button { add(result) } label: {
                        HStack(spacing: 12) {
                            PosterView(imageURL: result.imageURL, height: 86)
                                .frame(width: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 5) {
                                Text(result.title)
                                    .font(LumeType.sans(14, weight: .bold))
                                    .foregroundStyle(LumeColor.ink)
                                    .lineLimit(2)
                                Text([result.kind, result.year.map(String.init)].compactMap { $0 }.joined(separator: " · "))
                                    .font(LumeType.sans(12))
                                    .foregroundStyle(LumeColor.textFaint)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(LumeColor.brand)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.68)))
                        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func add(_ result: EntertainmentSearchResult) {
        guard !savedItems.contains(where: { $0.title.caseInsensitiveCompare(result.title) == .orderedSame }) else {
            dismiss()
            return
        }
        modelContext.insert(MovieShow(
            title: result.title,
            kind: result.kind,
            year: result.year,
            imageURLString: result.imageURL?.absoluteString,
            sourceURLString: result.sourceURL?.absoluteString
        ))
        try? modelContext.save()
        dismiss()
    }
}

private struct MovieShowReviewSheet: View {
    let movie: MovieShow

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var rating: Int
    @State private var review: String

    init(movie: MovieShow) {
        self.movie = movie
        _rating = State(initialValue: movie.rating ?? 0)
        _review = State(initialValue: movie.review ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: "Avaliar \(movie.kind.lowercased())",
                trailingTitle: "Salvar",
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        PosterView(imageURL: movie.imageURLString.flatMap(URL.init(string:)), height: 168)
                            .frame(width: 118)
                        Text(movie.title)
                            .font(LumeType.serif(23))
                            .foregroundStyle(LumeColor.ink)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        LumeEyebrow(text: "Sua avaliação")
                        LumeStarRating(rating: $rating, size: 28)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.48)))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 10) {
                        LumeEyebrow(text: "Resenha")
                        TextEditor(text: $review)
                            .font(LumeType.sans(15.5))
                            .foregroundStyle(LumeColor.ink)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.7)))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
                            .overlay(alignment: .topLeading) {
                                if review.isEmpty {
                                    Text("O que você achou?")
                                        .font(LumeType.sans(15.5))
                                        .foregroundStyle(LumeColor.textFainter)
                                        .padding(.horizontal, 17)
                                        .padding(.top, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.45)))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1))
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        movie.rating = rating == 0 ? nil : rating
        let trimmed = review.trimmingCharacters(in: .whitespacesAndNewlines)
        movie.review = trimmed.isEmpty ? nil : trimmed
        try? modelContext.save()
        dismiss()
    }
}

private struct MovieShowCard: View {
    var item: MovieShow
    var onOpen: (MovieShow) -> Void
    var onReview: (MovieShow) -> Void
    var onDelete: (MovieShow) -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { onOpen(item) } label: {
                VStack(alignment: .leading, spacing: 8) {
                    PosterView(imageURL: item.imageURLString.flatMap(URL.init(string:)), height: 180)
                    Text(item.title)
                        .font(LumeType.sans(13.5, weight: .bold))
                        .foregroundStyle(LumeColor.ink)
                        .lineLimit(2)
                    Text([item.kind, item.year.map(String.init)].compactMap { $0 }.joined(separator: " · "))
                        .font(LumeType.sans(11.5))
                        .foregroundStyle(LumeColor.textFaint)
                    Text(item.status.label)
                        .font(LumeType.sans(11, weight: .bold))
                        .foregroundStyle(LumeColor.brand)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onReview(item)
            } label: {
                HStack(spacing: 7) {
                    LumeStarDisplay(rating: item.rating ?? 0, size: 11)
                    Text(item.rating == nil ? "Avaliar" : "Editar avaliação")
                        .font(LumeType.sans(11.5, weight: .bold))
                        .foregroundStyle(LumeColor.brand)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.rating == nil ? "Avaliar \(item.kind.lowercased())" : "Editar avaliação de \(item.kind.lowercased())")
            .accessibilityHint("Abre as estrelas e o campo de resenha")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.58)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
        .contextMenu {
            Button("Avaliar e resenhar", systemImage: "star.bubble") {
                onReview(item)
            }
            ForEach(WatchStatus.allCases, id: \.self) { status in
                Button(status.label) {
                    item.status = status
                    try? modelContext.save()
                }
            }
            Button("Remover", role: .destructive) { onDelete(item) }
        }
    }
}

private struct PosterView: View {
    var imageURL: URL?
    var height: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(colors: [LumeColor.lavenderChipBg, LumeColor.roseSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
