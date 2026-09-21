import SwiftUI
import SwiftData

/// A simple daily-totals list behind the Água card's "Histórico" button.
struct WaterHistorySheet: View {
    var entries: [WaterEntry]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var entryToDelete: WaterEntry?
    @State private var showingDeleteConfirmation = false

    private var groupedEntries: [(Date, [WaterEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.date.startOfDay }
        return grouped.keys.sorted(by: >).prefix(30).map { day in
            (day, grouped[day]!.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(leadingTitle: "", title: "Histórico de água", trailingTitle: "Fechar", onLeading: {}, onTrailing: { dismiss() })
                .padding(.horizontal, 24)
                .padding(.top, 18)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(groupedEntries, id: \.0) { day, dayEntries in
                        VStack(spacing: 0) {
                            HStack {
                                Text(day.isToday ? "Hoje" : LumeDateFormat.dayMonthAbbrev(day))
                                    .font(LumeType.sans(15, weight: .semibold))
                                    .foregroundStyle(LumeColor.ink)
                                Spacer()
                                Text("\(LumeCurrency.integer(dayEntries.reduce(0) { $0 + $1.amountML })) ml")
                                    .font(LumeType.serif(18))
                                    .foregroundStyle(LumeColor.greenTextDeep)
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .padding(.bottom, 8)

                            ForEach(Array(dayEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                                if index > 0 {
                                    Divider()
                                        .overlay(LumeColor.greenDeep.opacity(0.1))
                                        .padding(.leading, 18)
                                }
                                HStack(spacing: 10) {
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(LumeColor.waterBlue)
                                    Text(LumeDateFormat.time(entry.date))
                                        .font(LumeType.sans(13.5))
                                        .foregroundStyle(LumeColor.textFaint)
                                    Spacer()
                                    Text("+\(LumeCurrency.integer(entry.amountML)) ml")
                                        .font(LumeType.sans(14.5, weight: .bold))
                                        .foregroundStyle(LumeColor.greenTextDeep)
                                    Menu {
                                        Button("Remover", role: .destructive) {
                                            entryToDelete = entry
                                            showingDeleteConfirmation = true
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(LumeColor.textFainter)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                            }
                        }
                        .lumeSoftGlass(cornerRadius: 18, shadow: false)
                    }

                    if groupedEntries.isEmpty {
                        Text("Ainda sem registros.")
                            .font(LumeType.sans(14))
                            .foregroundStyle(LumeColor.textMuted)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .confirmationDialog("Remover este registro de água?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Remover", role: .destructive) {
                deletePendingEntry()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func deletePendingEntry() {
        guard let entryToDelete else { return }
        modelContext.delete(entryToDelete)
        try? modelContext.save()
        self.entryToDelete = nil
    }
}
