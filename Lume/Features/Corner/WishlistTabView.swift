import SwiftUI
import SwiftData
import UIKit

struct WishlistTabView: View {
    @Query(sort: \WishlistItem.dateAdded, order: .reverse) private var items: [WishlistItem]
    @Query(sort: \ShoppingList.dateCreated, order: .forward) private var shoppingLists: [ShoppingList]
    @EnvironmentObject private var route: LumeRoute
    @State private var filter: String = "Todos"
    @State private var showingCapture = false
    @State private var showingNewList = false
    @State private var captureInitialURL: URL?
    @State private var itemToEdit: WishlistItem?

    private var listNames: [String] {
        var names = Set(items.map(\.listName))
        names.formUnion(shoppingLists.map(\.name))
        names.insert("Geral")
        return names.sorted()
    }

    private var filteredItems: [WishlistItem] {
        switch filter {
        case "Todos": items.filter { !$0.purchased }
        case "Comprados": items.filter(\.purchased)
        default: items.filter { $0.listName == filter && !$0.purchased }
        }
    }

    private var listForNewItem: String? {
        guard filter != "Todos", filter != "Comprados" else { return nil }
        return filter
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        LumeChip(title: "Todos", isSelected: filter == "Todos") { filter = "Todos" }
                        ForEach(listNames, id: \.self) { name in
                            LumeChip(title: name, isSelected: filter == name) { filter = name }
                        }
                        LumeChip(title: "Comprados", isSelected: filter == "Comprados") { filter = "Comprados" }
                        Button { showingNewList = true } label: {
                            Label("Nova lista", systemImage: "plus")
                                .font(LumeType.sans(13.5, weight: .bold))
                                .foregroundStyle(LumeColor.brand)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(.white.opacity(0.55)))
                                .overlay(Capsule().strokeBorder(LumeColor.brand.opacity(0.3), lineWidth: 1))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .zIndex(2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.persistentModelID) { index, item in
                        WishlistCard(item: item, onEdit: { itemToEdit = item })
                            .lumeRiseIn(delay: Double(index) * 0.05)
                    }
                }

                Color.clear.frame(height: 170)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            }

            LumeFloatingActionButton(accessibilityLabel: "Adicionar produto") {
                showingCapture = true
            }
        }
        .sheet(isPresented: $showingCapture, onDismiss: {
            captureInitialURL = nil
        }) {
            WishlistLinkCaptureView(
                initialURL: captureInitialURL,
                initialListName: listForNewItem
            )
        }
        .sheet(item: $itemToEdit) { item in
            WishlistLinkCaptureView(itemToEdit: item)
        }
        .sheet(isPresented: $showingNewList) {
            NewShoppingListSheet(existingNames: listNames)
        }
        .onAppear(perform: consumeIncomingLink)
        .onChange(of: route.pendingSharedURL) { _, _ in
            consumeIncomingLink()
        }
    }

    private func consumeIncomingLink() {
        guard !showingCapture, let url = route.pendingSharedURL else { return }
        captureInitialURL = url
        route.pendingSharedURL = nil
        showingCapture = true
    }
}

private struct WishlistCard: View {
    var item: WishlistItem
    var onEdit: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button(action: openProduct) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage).resizable().scaledToFill()
                    } else {
                        LinearGradient(colors: [LumeColor.amberChipBg, LumeColor.roseSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                .frame(height: 124)
                .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(LumeType.sans(13.5, weight: .bold))
                        .foregroundStyle(LumeColor.ink)
                        .lineLimit(2)
                    Text(LumeCurrency.full(item.price))
                        .font(LumeType.serif(19))
                        .foregroundStyle(LumeColor.brand)

                    if let discount = item.discountPercent {
                        Text("baixou \(discount)%")
                            .font(LumeType.sans(11, weight: .heavy))
                            .foregroundStyle(LumeColor.greenText)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(LumeColor.greenChipBg))
                    } else {
                        Text("guardado em \(LumeDateFormat.dayMonthAbbrev(item.dateAdded))")
                            .font(LumeType.sans(11.5))
                            .foregroundStyle(LumeColor.textFaint)
                    }
                }
                .padding(EdgeInsets(top: 12, leading: 14, bottom: 14, trailing: 14))
            }
            .background(.white.opacity(0.6))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: LumeColor.brandPlumStart.opacity(0.08), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityHint(item.sourceURLString == nil ? "Sem link" : "Abre o produto no site")
        .contextMenu {
            Button("Editar") { onEdit() }
            Button(item.purchased ? "Marcar como não comprado" : "Marcar como comprado") {
                item.purchased.toggle()
                try? modelContext.save()
            }
            Button("Remover", role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
            }
        }
    }

    private func openProduct() {
        guard let sourceURLString = item.sourceURLString,
              let url = URL(string: sourceURLString) else { return }
        openURL(url)
    }
}

struct NewShoppingListSheet: View {
    let existingNames: [String]
    var onCreated: (String) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: "Nova lista",
                trailingTitle: "Criar",
                trailingEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 8) {
                Text("Dê um nome para organizar seus produtos.")
                    .font(LumeType.sans(14))
                    .foregroundStyle(LumeColor.textMuted)

                TextField("Ex.: Casa, maquiagem, viagem…", text: $name)
                    .font(LumeType.sans(17, weight: .semibold))
                    .foregroundStyle(LumeColor.ink)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.72)))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))

                if let errorMessage {
                    Text(errorMessage)
                        .font(LumeType.sans(13.5, weight: .semibold))
                        .foregroundStyle(LumeColor.errorText)
                }
            }
            .padding(24)

            Spacer()
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !existingNames.contains(where: { $0.compare(trimmed, options: .caseInsensitive) == .orderedSame }) else {
            errorMessage = "Essa lista já existe."
            return
        }
        modelContext.insert(ShoppingList(name: trimmed))
        try? modelContext.save()
        onCreated(trimmed)
        dismiss()
    }
}
