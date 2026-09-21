import SwiftUI
import SwiftData
import UIKit

/// Screens 13 + 14 — paste a link, watch it read itself, edit anything that
/// didn't come through automatically.
struct WishlistLinkCaptureView: View {
    private let initialURL: URL?
    private let initialListName: String?
    private let itemToEdit: WishlistItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WishlistItem.dateAdded, order: .reverse) private var existingItems: [WishlistItem]
    @Query(sort: \ShoppingList.dateCreated, order: .forward) private var shoppingLists: [ShoppingList]

    @State private var urlString = ""
    @State private var isLoading = false
    @State private var hasFetched = false
    @State private var title = ""
    @State private var priceDigits = ""
    @State private var originalPriceDigits = ""
    @State private var imageData: Data?
    @State private var listName = "Geral"
    @State private var notifyOnDrop = true
    @State private var sourceHost: String?
    @State private var showingNewList = false
    @State private var didAutoPaste = false

    init(initialURL: URL? = nil, initialListName: String? = nil, itemToEdit: WishlistItem? = nil) {
        self.initialURL = initialURL
        self.initialListName = initialListName
        self.itemToEdit = itemToEdit
        _urlString = State(initialValue: itemToEdit?.sourceURLString ?? initialURL?.absoluteString ?? "")
        _hasFetched = State(initialValue: itemToEdit != nil)
        _title = State(initialValue: itemToEdit?.name ?? "")
        _priceDigits = State(initialValue: itemToEdit.map { String(Int(($0.price * 100).rounded())) } ?? "")
        _originalPriceDigits = State(initialValue: itemToEdit?.originalPrice.map { String(Int(($0 * 100).rounded())) } ?? "")
        _imageData = State(initialValue: itemToEdit?.imageData)
        _listName = State(initialValue: itemToEdit?.listName ?? initialListName ?? "Geral")
        _notifyOnDrop = State(initialValue: itemToEdit?.notifyOnPriceDrop ?? true)
        _sourceHost = State(initialValue: itemToEdit?.sourceHost)
    }

    private var listNames: [String] {
        var names = Set(existingItems.map(\.listName))
        names.formUnion(shoppingLists.map(\.name))
        names.insert("Geral")
        return names.sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: itemToEdit == nil ? "Novo desejo" : "Editar desejo",
                trailingTitle: "Salvar",
                trailingEnabled: hasFetched && !title.trimmingCharacters(in: .whitespaces).isEmpty,
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 16) {
                    linkField

                    if isLoading {
                        loadingPreview
                        Text("Lendo a página… nome, preço e imagem entram sozinhos.")
                            .font(LumeType.sans(14.5))
                            .foregroundStyle(LumeColor.textMuted)
                            .multilineTextAlignment(.center)
                    } else if hasFetched {
                        filledPreview
                        editableFields
                    } else {
                        Text("Se a loja não deixar ler, os campos ficam abertos para você preencher.")
                            .font(LumeType.sans(13.5))
                            .foregroundStyle(LumeColor.textMuted)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.4)))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(LumeColor.brand.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))

                        Button("Preencher manualmente") {
                            withAnimation { hasFetched = true }
                        }
                        .font(LumeType.sans(14, weight: .bold))
                        .foregroundStyle(LumeColor.brand)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingNewList) {
            NewShoppingListSheet(existingNames: listNames) { newName in
                listName = newName
            }
        }
        .onAppear {
            guard itemToEdit == nil, !didAutoPaste, !hasFetched else { return }
            didAutoPaste = true
            if initialURL != nil {
                fetch()
            } else {
                pasteFromClipboard()
            }
        }
    }

    private var linkField: some View {
        HStack(spacing: 12) {
            Circle().fill(LumeColor.greenDeep).frame(width: 9, height: 9)
            TextField("Cole o link do produto", text: $urlString)
                .font(LumeType.sans(15))
                .foregroundStyle(LumeColor.ink)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(1)
                .onSubmit(fetch)
            Button {
                pasteFromClipboard()
            } label: {
                Text("Colar")
                    .font(LumeType.sans(13.5, weight: .heavy))
                    .foregroundStyle(LumeColor.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.75)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.95), lineWidth: 1))
    }

    private var loadingPreview: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(LumeColor.paper).frame(width: 88, height: 88)
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 99).fill(LumeColor.paper).frame(height: 14)
                RoundedRectangle(cornerRadius: 99).fill(LumeColor.paper).frame(width: 120, height: 14)
                RoundedRectangle(cornerRadius: 99).fill(LumeColor.paper).frame(width: 80, height: 22).padding(.top, 4)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white.opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.white.opacity(0.85), lineWidth: 1))
        .lumeSheen(RoundedRectangle(cornerRadius: 26, style: .continuous), duration: 1.9)
    }

    private var filledPreview: some View {
        VStack(spacing: 0) {
            ZStack {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [LumeColor.amberChipBg, LumeColor.lavenderChipBgFaint], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .frame(height: 196)
            .clipped()

            VStack(alignment: .leading, spacing: 10) {
                if let sourceHost {
                    HStack(spacing: 8) {
                        Circle().fill(LumeColor.greenDeep).frame(width: 7, height: 7)
                        Text(sourceHost).font(LumeType.sans(12.5)).foregroundStyle(LumeColor.textFaint)
                    }
                }

                TextField("Nome do produto", text: $title)
                    .font(LumeType.serif(22))
                    .foregroundStyle(LumeColor.ink)

                VStack(alignment: .leading, spacing: 4) {
                    LumeAmountField(digits: $priceDigits, fontSize: 30, color: LumeColor.brand, autofocus: false)
                    if let original = originalPriceValue, original > LumeCurrency.amount(fromDigits: priceDigits) {
                        Text("de \(LumeCurrency.full(original))")
                            .font(LumeType.sans(13.5))
                            .foregroundStyle(LumeColor.textFainter)
                            .strikethrough()
                    }
                }
            }
            .padding(18)
        }
        .background(.white.opacity(0.62))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: LumeColor.brandPlumStart.opacity(0.1), radius: 14, x: 0, y: 8)
    }

    private var editableFields: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Lista", selection: $listName) {
                    ForEach(listNames, id: \.self) { Text($0).tag($0) }
                }
                Divider()
                Button("Criar nova lista", systemImage: "plus") {
                    showingNewList = true
                }
            } label: {
                labeledCard(label: "Lista", value: "\(listName) ▾")
            }

            Button {
                notifyOnDrop.toggle()
            } label: {
                labeledCard(label: "Avisar se baixar", value: notifyOnDrop ? "Sim" : "Não")
            }
            .buttonStyle(.plain)
        }
    }

    private func labeledCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(LumeType.sans(12.5)).foregroundStyle(LumeColor.textFaint)
            Text(value).font(LumeType.sans(15.5, weight: .bold)).foregroundStyle(LumeColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var originalPriceValue: Double? {
        originalPriceDigits.isEmpty ? nil : LumeCurrency.amount(fromDigits: originalPriceDigits)
    }

    private func pasteFromClipboard() {
        guard let clipboardURL = clipboardURL() else { return }
        urlString = clipboardURL.absoluteString
        fetch()
    }

    private func clipboardURL() -> URL? {
        if let url = UIPasteboard.general.url,
           ["http", "https"].contains(url.scheme?.lowercased()) {
            return url
        }
        guard let text = UIPasteboard.general.string else { return nil }
        guard let url = normalizedURL(from: text),
              ["http", "https"].contains(url.scheme?.lowercased()),
              url.host != nil else { return nil }
        return url
    }

    private func fetch() {
        guard let url = normalizedURL(from: urlString) else {
            withAnimation { hasFetched = true }
            return
        }
        sourceHost = url.host?.replacingOccurrences(of: "www.", with: "")
        isLoading = true
        hasFetched = false
        title = ""
        priceDigits = ""
        originalPriceDigits = ""
        imageData = nil
        Task {
            let result = await LinkMetadataFetcher.fetch(url: url)
            await MainActor.run {
                isLoading = false
                hasFetched = true
                title = meaningfulTitle(result.title) ?? fallbackTitle(from: url)
                imageData = result.imageData
                if let price = result.price {
                    priceDigits = centsDigits(price)
                }
                if let original = result.originalPrice {
                    originalPriceDigits = centsDigits(original)
                }
            }
        }
    }

    private func meaningfulTitle(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
        if normalized == "mercadolivre" || normalized == "mercadolibre" {
            return nil
        }
        return value
    }

    private func fallbackTitle(from url: URL) -> String {
        let components = url.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }

        let candidate: String
        if let upIndex = components.firstIndex(where: { $0.lowercased() == "up" }),
           upIndex > 0 {
            candidate = components[upIndex - 1]
        } else {
            candidate = components.last ?? url.host ?? "Produto"
        }

        let decoded = candidate.removingPercentEncoding ?? candidate
        let words = decoded
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        return words.joined(separator: " ").capitalized
    }

    private func normalizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(string: "https://\(trimmed)")
    }

    private func centsDigits(_ value: Double) -> String {
        String(Int((value * 100).rounded()))
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        if let itemToEdit {
            itemToEdit.name = trimmedTitle
            itemToEdit.price = LumeCurrency.amount(fromDigits: priceDigits)
            itemToEdit.originalPrice = originalPriceValue
            itemToEdit.sourceURLString = normalizedURL(from: urlString)?.absoluteString
            itemToEdit.imageData = imageData
            itemToEdit.listName = listName
            itemToEdit.notifyOnPriceDrop = notifyOnDrop
        } else {
            let item = WishlistItem(
                name: trimmedTitle,
                price: LumeCurrency.amount(fromDigits: priceDigits),
                originalPrice: originalPriceValue,
                sourceURLString: normalizedURL(from: urlString)?.absoluteString,
                imageData: imageData,
                listName: listName,
                notifyOnPriceDrop: notifyOnDrop
            )
            modelContext.insert(item)
        }
        try? modelContext.save()
        dismiss()
    }
}
