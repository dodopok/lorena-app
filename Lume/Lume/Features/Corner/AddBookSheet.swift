import SwiftUI
import SwiftData

struct AddBookSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = 300
    @State private var status: BookStatus = .wantToRead
    @State private var rating = 0
    @State private var coverHex = coverOptions[0]

    private static let coverOptions = ["E4D6E6", "F2E2D6", "DCE9E0", "F5D6E0", "D7D2EA", "F7DFC4"]

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: "Novo livro",
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

                    if status == .read {
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundStyle(LumeColor.brand)
                                    .onTapGesture { rating = star }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        LumeEyebrow(text: "Capa")
                        HStack(spacing: 10) {
                            ForEach(Self.coverOptions, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().strokeBorder(LumeColor.ink.opacity(coverHex == hex ? 0.6 : 0), lineWidth: 2))
                                    .onTapGesture { coverHex = hex }
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
        let book = Book(
            title: trimmed,
            author: author.trimmingCharacters(in: .whitespaces),
            status: status,
            currentPage: 0,
            totalPages: status == .reading ? totalPages : 0,
            rating: rating,
            coverColorHex: coverHex
        )
        modelContext.insert(book)
        try? modelContext.save()
        dismiss()
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
