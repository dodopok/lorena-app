import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddBookSheet: View {
    var bookToEdit: Book?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = 300
    @State private var status: BookStatus = .wantToRead
    @State private var rating = 0
    @State private var review = ""
    @State private var coverHex = coverOptions[0]
    @State private var coverSearchResults: [GoogleBookResult] = []
    @State private var selectedCoverID: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var coverImageData: Data?
    @State private var coverChanged = false
    @State private var isSearchingCovers = false

    private static let coverOptions = ["E4D6E6", "F2E2D6", "DCE9E0", "F5D6E0", "D7D2EA", "F7DFC4"]

    init(bookToEdit: Book? = nil) {
        self.bookToEdit = bookToEdit
        _title = State(initialValue: bookToEdit?.title ?? "")
        _author = State(initialValue: bookToEdit?.author ?? "")
        _totalPages = State(initialValue: bookToEdit?.totalPages ?? 300)
        _status = State(initialValue: bookToEdit?.status ?? .wantToRead)
        _rating = State(initialValue: bookToEdit?.rating ?? 0)
        _review = State(initialValue: bookToEdit?.review ?? "")
        _coverHex = State(initialValue: bookToEdit?.coverColorHex ?? Self.coverOptions[0])
        _coverImageData = State(initialValue: bookToEdit?.coverImageData)
    }

    var body: some View {
        let hasManualCover = coverImageData != nil

        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: bookToEdit == nil ? "Novo livro" : "Editar livro",
                trailingTitle: "Salvar",
                trailingEnabled: !title.trimmingCharacters(in: .whitespaces).isEmpty,
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 16) {
                    labeledField("Título") { TextField("Nome do livro", text: $title).font(LumeType.sans(17, weight: .semibold)) }
                    labeledField("Autora ou autor") { TextField("Opcional", text: $author).font(LumeType.sans(16)) }

                    coverSearch

                    HStack(spacing: 10) {
                        ForEach([BookStatus.wantToRead, .reading, .read], id: \.self) { option in
                            LumeChip(title: option.label, isSelected: status == option) { status = option }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if status == .reading {
                        labeledField("Total de páginas") {
                            Stepper("\(totalPages) páginas", value: $totalPages, in: 10...2000, step: 10)
                                .font(LumeType.sans(15, weight: .semibold))
                        }
                    }

                    reviewSection

                    VStack(alignment: .leading, spacing: 10) {
                        LumeEyebrow(text: "Capa")
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Label(hasManualCover ? "Trocar foto da capa" : "Adicionar foto da capa", systemImage: "photo")
                                .font(LumeType.sans(14, weight: .bold))
                                .foregroundStyle(LumeColor.brand)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.62)))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        if let coverImageData, let image = UIImage(data: coverImageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 82, height: 116)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        HStack(spacing: 10) {
                            ForEach(Self.coverOptions, id: \.self) { hex in
                                Button {
                                    coverHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 32, height: 32)
                                        .overlay(Circle().strokeBorder(LumeColor.ink.opacity(coverHex == hex ? 0.6 : 0), lineWidth: 2))
                                        .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task(id: title) {
            let query = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard query.count >= 2 else {
                coverSearchResults = []
                isSearchingCovers = false
                return
            }

            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            isSearchingCovers = true
            let results = await GoogleBooksService.search(title: query)
            guard !Task.isCancelled else { return }
            coverSearchResults = results
            isSearchingCovers = false
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadPhoto(newItem)
        }
    }

    private var coverSearch: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                LumeEyebrow(text: "Escolher capa")
                Spacer()
                if isSearchingCovers {
                    ProgressView()
                        .controlSize(.small)
                        .tint(LumeColor.brand)
                } else if !coverSearchResults.isEmpty {
                    Text(coverSearchResults[0].sourceName)
                        .font(LumeType.sans(11.5, weight: .bold))
                        .foregroundStyle(LumeColor.textFaint)
                }
            }

            if coverSearchResults.isEmpty && !isSearchingCovers {
                Text("Digite o título para encontrar capas automaticamente.")
                    .font(LumeType.sans(13.5))
                    .foregroundStyle(LumeColor.textMuted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(coverSearchResults) { result in
                            Button {
                                selectCover(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    GoogleBookCoverView(result: result)
                                        .frame(width: 82, height: 116)
                                        .overlay {
                                            if selectedCoverID == result.id {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(LumeColor.brand, lineWidth: 3)
                                            }
                                        }
                                    Text(result.title)
                                        .font(LumeType.sans(11.5, weight: .bold))
                                        .foregroundStyle(LumeColor.ink)
                                        .lineLimit(2)
                                        .frame(width: 82, alignment: .leading)
                                    if !result.authors.isEmpty {
                                        Text(result.authors)
                                            .font(LumeType.sans(10.5))
                                            .foregroundStyle(LumeColor.textFaint)
                                            .lineLimit(1)
                                            .frame(width: 82, alignment: .leading)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.48)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1))
    }

    private func labeledField(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(LumeType.sans(12.5)).foregroundStyle(LumeColor.textFaint)
            content().foregroundStyle(LumeColor.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumeSoftGlass(cornerRadius: 20, opacity: 0.65, shadow: false)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let selectedCoverURL = coverSearchResults.first(where: { $0.id == selectedCoverID })?.coverURL?.absoluteString
        if let bookToEdit {
            bookToEdit.title = trimmed
            bookToEdit.author = author.trimmingCharacters(in: .whitespaces)
            bookToEdit.status = status
            bookToEdit.totalPages = status == .reading ? totalPages : 0
            bookToEdit.currentPage = min(bookToEdit.currentPage, max(bookToEdit.totalPages, 0))
            bookToEdit.rating = rating
            bookToEdit.review = review.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : review.trimmingCharacters(in: .whitespacesAndNewlines)
            bookToEdit.coverColorHex = coverHex
            if coverChanged {
                bookToEdit.coverImageData = coverImageData
                bookToEdit.coverURLString = selectedCoverURL
            }
        } else {
            let book = Book(
                title: trimmed,
                author: author.trimmingCharacters(in: .whitespaces),
                status: status,
                currentPage: 0,
                totalPages: status == .reading ? totalPages : 0,
                rating: rating,
                review: review.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : review.trimmingCharacters(in: .whitespacesAndNewlines),
                coverColorHex: coverHex,
                coverURLString: selectedCoverURL,
                coverImageData: coverImageData
            )
            modelContext.insert(book)
        }
        try? modelContext.save()
        dismiss()
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LumeEyebrow(text: "Sua avaliação")
            LumeStarRating(rating: $rating, size: 27)

            Text("Resenha (opcional)")
                .font(LumeType.sans(12.5, weight: .semibold))
                .foregroundStyle(LumeColor.textFaint)

            TextEditor(text: $review)
                .font(LumeType.sans(15.5))
                .foregroundStyle(LumeColor.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 112)
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

    private func selectCover(_ result: GoogleBookResult) {
        selectedCoverID = result.id
        coverImageData = nil
        coverChanged = true
        title = result.title
        if !result.authors.isEmpty {
            author = result.authors
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            await MainActor.run {
                coverImageData = data
                selectedCoverID = nil
                coverChanged = true
            }
        }
    }
}

private struct GoogleBookCoverView: View {
    let result: GoogleBookResult

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [LumeColor.lavenderChipBg, LumeColor.roseSoft], startPoint: .topLeading, endPoint: .bottomTrailing))

            if let coverURL = result.coverURL {
                AsyncImage(url: coverURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct UpdatePageSheet: View {
    var book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var page: Double

    init(book: Book) {
        self.book = book
        _page = State(initialValue: Double(book.currentPage))
    }

    var body: some View {
        VStack(spacing: 24) {
            LumeSheetHeader(leadingTitle: "Cancelar", title: "Página atual", trailingTitle: "Salvar", onLeading: { dismiss() }, onTrailing: save)

            VStack(spacing: 10) {
                Text("\(Int(page))")
                    .font(LumeType.serif(56))
                    .foregroundStyle(LumeColor.ink)
                Text("de \(book.totalPages) páginas")
                    .font(LumeType.sans(14))
                    .foregroundStyle(LumeColor.textFaint)
            }

            Slider(value: $page, in: 0...Double(max(book.totalPages, 1)), step: 1)
                .tint(LumeColor.brand)

            Spacer()
        }
        .padding(24)
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        book.currentPage = Int(page)
        if book.currentPage >= book.totalPages, book.totalPages > 0 {
            book.status = .read
        }
        try? modelContext.save()
        dismiss()
    }
}
