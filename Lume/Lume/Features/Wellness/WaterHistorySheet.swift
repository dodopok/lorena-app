import SwiftUI

/// A simple daily-totals list behind the Água card's "Histórico" button.
struct WaterHistorySheet: View {
    var entries: [WaterEntry]
    @Environment(\.dismiss) private var dismiss

    private var dailyTotals: [(Date, Int)] {
        let grouped = Dictionary(grouping: entries) { $0.date.startOfDay }
        return grouped.keys.sorted(by: >).prefix(30).map { day in
            (day, grouped[day]!.reduce(0) { $0 + $1.amountML })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(leadingTitle: "", title: "Histórico de água", trailingTitle: "Fechar", onLeading: {}, onTrailing: { dismiss() })
                .padding(.horizontal, 24)
                .padding(.top, 18)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(dailyTotals, id: \.0) { day, total in
                        HStack {
                            Text(day.isToday ? "Hoje" : LumeDateFormat.dayMonthAbbrev(day))
                                .font(LumeType.sans(15, weight: .semibold))
                                .foregroundStyle(LumeColor.ink)
                            Spacer()
                            Text("\(LumeCurrency.integer(total)) ml")
                                .font(LumeType.serif(18))
                                .foregroundStyle(LumeColor.greenTextDeep)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .lumeSoftGlass(cornerRadius: 18, shadow: false)
                    }

                    if dailyTotals.isEmpty {
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
    }
}
