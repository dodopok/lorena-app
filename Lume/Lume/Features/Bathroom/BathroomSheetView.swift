import SwiftUI
import SwiftData

/// Screen 05 — just a tally. One tap adds a timestamp, nothing else is ever
/// asked or stored: no scale, no notes.
struct BathroomSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BathroomEntry.date, order: .reverse) private var allEntries: [BathroomEntry]

    private var todayEntries: [BathroomEntry] { allEntries.filter(\.date.isToday) }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Fechar",
                title: "Banheiro",
                trailingTitle: "Pronto",
                onLeading: { dismiss() },
                onTrailing: { dismiss() }
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 22) {
                    Text("Só a contagem do dia. Nada além disso é guardado.")
                        .font(LumeType.sans(14.5))
                        .foregroundStyle(LumeColor.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 6)

                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(.white.opacity(0.6))
                        Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1)
                        VStack(spacing: 6) {
                            Text("\(todayEntries.count)")
                                .font(LumeType.serif(88))
                                .foregroundStyle(LumeColor.greenTextDeep)
                                .contentTransition(.numericText())
                                .animation(.default, value: todayEntries.count)
                            LumeEyebrow(text: "vezes hoje", color: LumeColor.greenText, size: 11)
                        }
                    }
                    .frame(width: 212, height: 212)
                    .shadow(color: LumeColor.brandPlumStart.opacity(0.14), radius: 20, x: 0, y: 10)
                    .lumePulse(Circle(), color: LumeColor.greenDeep, duration: 3.4)

                    HStack(spacing: 12) {
                        LumeGlassIconButton(systemImage: "minus", size: 60, iconSize: 24, tint: LumeColor.textSecondary) {
                            undoLast()
                        }

                        Button(action: logOne) {
                            Text("Registrar mais uma")
                                .font(LumeType.sans(17, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 60)
                        .background(LumeColor.greenDeep, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .buttonStyle(.plain)
                    }

                    if !todayEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            LumeEyebrow(text: "Hoje")
                            VStack(spacing: 0) {
                                ForEach(Array(todayEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                                    if index > 0 {
                                        Divider().overlay(LumeColor.brandPlumStart.opacity(0.08))
                                    }
                                    HStack {
                                        Text(LumeDateFormat.time(entry.date))
                                            .font(LumeType.sans(15))
                                            .foregroundStyle(LumeColor.ink)
                                        Spacer()
                                        Button("desfazer") { undo(entry) }
                                            .font(LumeType.sans(13.5))
                                            .foregroundStyle(LumeColor.textFaint)
                                            .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                }
                            }
                            .lumeSoftGlass(cornerRadius: 22, shadow: false)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func logOne() {
        modelContext.insert(BathroomEntry())
        try? modelContext.save()
    }

    private func undoLast() {
        guard let last = todayEntries.first else { return }
        undo(last)
    }

    private func undo(_ entry: BathroomEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}
