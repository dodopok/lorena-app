import SwiftUI
import SwiftData
import UIKit

struct BooksTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]

    @State private var showingAddBook = false
    @State private var showingPageUpdate = false
    @State private var bookToEdit: Book?
    @State private var bookToDelete: Book?
    @State private var showingDeleteConfirmation = false

    private var readingBook: Book? { books.first { $0.status == .reading } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let readingBook {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 18) {
                            BookCoverView(seedHex: readingBook.coverColorHex, coverURLString: readingBook.coverURLString, coverImageData: readingBook.coverImageData, width: 86, height: 126)

                            VStack(alignment: .leading, spacing: 8) {
                                LumeEyebrow(text: "Lendo agora")
                                Text(readingBook.title)
                                    .font(LumeType.serif(22))
                                    .foregroundStyle(LumeColor.ink)
                                    .lineLimit(2)
                                Text(readingBook.author)
                                    .font(LumeType.sans(13))
                                    .foregroundStyle(LumeColor.textFaint)

                                GeometryReader { geo in
                                    Capsule().fill(LumeColor.brandPlumStart.opacity(0.1))
                                        .overlay(alignment: .leading) {
                                            Capsule().fill(LumeColor.brand)
                                                .frame(width: geo.size.width * readingBook.progress)
                                        }
                                }
                                .frame(height: 7)

                                Text("página \(readingBook.currentPage) de \(readingBook.totalPages)")
                                    .font(LumeType.sans(12.5))
                                    .foregroundStyle(LumeColor.textFaint)
                            }
                        }
                    }
                    .padding(20)
                    .lumeSoftGlass(cornerRadius: 28)
                    .lumeRiseIn()
                    .contextMenu { bookActions(for: readingBook) }

                    Button {
                        showingPageUpdate = true
                    } label: {
                        Text("Atualizar página")
                            .font(LumeType.sans(15, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LumeColor.brand))
                            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { showingAddBook = true } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "book").font(.system(size: 26)).foregroundStyle(LumeColor.textFainter)
                            Text("Nenhum livro em andamento — adicionar um?")
                                .font(LumeType.sans(14)).foregroundStyle(LumeColor.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                    .buttonStyle(.plain)
                    .lumeSoftGlass(cornerRadius: 28, shadow: false)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Biblioteca").font(LumeType.sans(17, weight: .heavy)).foregroundStyle(LumeColor.ink)
                        Spacer()
                        Button {
                            showingAddBook = true
                        } label: {
                            Text("Adicionar")
                                .font(LumeType.sans(14, weight: .bold))
                                .foregroundStyle(LumeColor.brand)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // A review needs room for five stars and its action label. Three
                    // narrow columns made the control wrap into an awkward second line
                    // on the phone, so books use the same comfortable two-column rhythm
                    // as films and the wishlist.
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(Array(books.enumerated()), id: \.element.persistentModelID) { index, book in
                            VStack(alignment: .leading, spacing: 8) {
                                BookCoverView(seedHex: book.coverColorHex, coverURLString: book.coverURLString, coverImageData: book.coverImageData, width: nil, height: 174)
                                    Text(book.title)
                                    .font(LumeType.sans(12, weight: .bold))
                                    .foregroundStyle(LumeColor.ink)
                                    .lineLimit(2)
                                Text(statusLabel(book))
                                    .font(LumeType.sans(11))
                                    .foregroundStyle(LumeColor.textFaint)

                                Button {
                                    bookToEdit = book
                                } label: {
                                    HStack(spacing: 7) {
                                        LumeStarDisplay(rating: book.rating, size: 11)
                                        Text(book.rating == 0 ? "Avaliar" : "Editar avaliação")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(LumeColor.brand)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(book.rating == 0 ? "Avaliar livro" : "Editar avaliação do livro")
                                .accessibilityHint("Abre as estrelas e o campo de resenha")
                            }
                            .lumeRiseIn(delay: Double(index) * 0.05)
                            .contextMenu { bookActions(for: book) }
                        }
                    }
                }

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showingAddBook) { AddBookSheet() }
        .sheet(item: $bookToEdit) { book in
            AddBookSheet(bookToEdit: book)
        }
        .sheet(isPresented: $showingPageUpdate) {
            if let readingBook { UpdatePageSheet(book: readingBook) }
        }
        .confirmationDialog(
            "Apagar este livro?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Apagar", role: .destructive) { deletePendingBook() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("O livro e o progresso dele serão removidos.")
        }
    }

    private func statusLabel(_ book: Book) -> String {
        switch book.status {
        case .reading: return "lendo agora"
        case .read: return "lido"
        case .wantToRead: return "quero ler"
        }
    }

    @ViewBuilder
    private func bookActions(for book: Book) -> some View {
        Button("Avaliar e resenhar", systemImage: "star.bubble") { bookToEdit = book }
        Button("Editar") { bookToEdit = book }
        Button("Remover", role: .destructive) {
            bookToDelete = book
            showingDeleteConfirmation = true
        }
    }

    private func deletePendingBook() {
        guard let bookToDelete else { return }
        modelContext.delete(bookToDelete)
        try? modelContext.save()
        self.bookToDelete = nil
    }
}

struct BookCoverView: View {
    var seedHex: String
    var coverURLString: String? = nil
    var coverImageData: Data? = nil
    var width: CGFloat?
    var height: CGFloat

    var body: some View {
        let top = Color(hex: seedHex)
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [top, top.darkened()], startPoint: .topLeading, endPoint: .bottomTrailing))
            if let coverImageData, let uiImage = UIImage(data: coverImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let coverURLString, let url = URL(string: coverURLString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: LumeColor.brandPlumStart.opacity(0.16), radius: 8, x: 0, y: 7)
    }
}
