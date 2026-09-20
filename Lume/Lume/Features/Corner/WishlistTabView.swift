import SwiftUI
import SwiftData
import UIKit

struct WishlistTabView: View {
    @Query(sort: \WishlistItem.dateAdded, order: .reverse) private var items: [WishlistItem]
    @State private var filter: String = "Todos"
    @State private var showingCapture = false

    private var listNames: [String] {
        Array(Set(items.filter { !$0.purchased }.map(\.listName))).sorted()
    }

    private var filteredItems: [WishlistItem] {
        switch filter {
        case "Todos": items.filter { !$0.purchased }
        case "Comprados": items.filter(\.purchased)
        default: items.filter { $0.listName == filter && !$0.purchased }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        LumeChip(title: "Todos", isSelected: filter == "Todos") { filter = "Todos" }
                        ForEach(listNames, id: \.self) { name in
                            LumeChip(title: name, isSelected: filter == name) { filter = name }
                        }
                        LumeChip(title: "Comprados", isSelected: filter == "Comprados") { filter = "Comprados" }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.persistentModelID) { index, item in
                        WishlistCard(item: item)
                            .lumeRiseIn(delay: Double(index) * 0.05)
                    }

                    Button { showingCapture = true } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(LumeColor.brand))
                            VStack(spacing: 2) {
                                Text("Colar link").font(LumeType.sans(13.5, weight: .bold)).foregroundStyle(LumeColor.brand)
                                Text("ou compartilhar da loja").font(LumeType.sans(11.5)).foregroundStyle(LumeColor.textFaint)
                            }
                            .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 206)
                    }
                    .buttonStyle(.plain)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.4)))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(LumeColor.brand.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                }

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .sheet(isPresented: $showingCapture) { WishlistLinkCaptureView() }
    }
}

private struct WishlistCard: View {
    var item: WishlistItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
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
        .contextMenu {
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
}
