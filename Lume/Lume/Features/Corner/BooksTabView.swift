import SwiftUI
import SwiftData

struct BooksTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]

    @State private var showingAddBook = false
    @State private var showingPageUpdate = false

    private var readingBook: Book? { books.first { $0.status == .reading } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let readingBook {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 18) {
                            BookCoverView(seedHex: readingBook.coverColorHex, width: 86, height: 126)

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

                    Button {
                        showingPageUpdate = true
                    } label: {
                        Text("Atualizar página")
                            .font(LumeType.sans(15, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LumeColor.brand))
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
                        Button("Adicionar") { showingAddBook = true }
                            .font(LumeType.sans(14, weight: .bold))
                            .foregroundStyle(LumeColor.brand)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(books.enumerated()), id: \.element.persistentModelID) { index, book in
                            VStack(alignment: .leading, spacing: 8) {
                                BookCoverView(seedHex: book.coverColorHex, width: nil, height: 140)
                                Text(book.title)
                                    .font(LumeType.sans(12, weight: .bold))
                                    .foregroundStyle(LumeColor.ink)
                                    .lineLimit(2)
                                Text(statusLabel(book))
                                    .font(LumeType.sans(11))
                                    .foregroundStyle(LumeColor.textFaint)
                            }
                            .lumeRiseIn(delay: Double(index) * 0.05)
                        }
                    }
                }

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showingAddBook) { AddBookSheet() }
        .sheet(isPresented: $showingPageUpdate) {
            if let readingBook { UpdatePageSheet(book: readingBook) }
        }
    }

    private func statusLabel(_ book: Book) -> String {
        switch book.status {
        case .reading: "lendo agora"
        case .read: "lido · \(String(repeating: "★", count: max(0, min(5, book.rating))))"
        case .wantToRead: "quero ler"
        }
    }
}

struct BookCoverView: View {
    var seedHex: String
    var width: CGFloat?
    var height: CGFloat

    var body: some View {
        let top = Color(hex: seedHex)
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(LinearGradient(colors: [top, top.darkened()], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .shadow(color: LumeColor.brandPlumStart.opacity(0.16), radius: 8, x: 0, y: 7)
    }
}
