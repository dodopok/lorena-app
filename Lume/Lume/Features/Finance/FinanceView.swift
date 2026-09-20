import SwiftUI
import SwiftData

struct FinanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var categoryFilter: FinanceCategory?
    @State private var showingNewExpense = false

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.amberOrb, size: 320, opacity: 0.5, blur: 60, alignment: .topLeading, offset: CGSize(width: -80, height: -40), duration: 17),
        OrbSpec(color: LumeColor.roseOrb, size: 280, opacity: 0.5, blur: 56, alignment: .bottomTrailing, offset: CGSize(width: -90, height: -60), duration: 21, reversed: true),
    ]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                LumeColor.canvas.ignoresSafeArea()
                LumeOrbBackground(orbs: orbs)

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        AvailableBalanceCard(
                            available: availableBalance,
                            subtitle: "Próxima mesada em \(nextAllowanceLabel)."
                        )
                        .overlay(alignment: .bottom) { progressFooter }
                        .lumeRiseIn()

                        chipRow

                        VStack(spacing: 18) {
                            ForEach(groupedByDay, id: \.0) { label, dayExpenses in
                                VStack(alignment: .leading, spacing: 10) {
                                    LumeEyebrow(text: label)
                                    VStack(spacing: 0) {
                                        ForEach(Array(dayExpenses.enumerated()), id: \.element.persistentModelID) { index, expense in
                                            if index > 0 {
                                                Divider()
                                                    .overlay(LumeColor.brandPlumStart.opacity(0.08))
                                                    .padding(.leading, 72)
                                            }
                                            ExpenseRow(expense: expense)
                                        }
                                    }
                                    .lumeSoftGlass(cornerRadius: 24, shadow: false)
                                }
                            }

                            if groupedByDay.isEmpty {
                                emptyState
                            }
                        }

                        Color.clear.frame(height: 130)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }

                LumeSolidIconButton(systemImage: "plus", size: 62, iconSize: 26, color: LumeColor.brand, pulses: true) {
                    showingNewExpense = true
                }
                .shadow(color: LumeColor.brand.opacity(0.4), radius: 16, x: 0, y: 10)
                .padding(.trailing, 22)
                .padding(.bottom, 130)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewExpense) {
                NewExpenseView()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Finanças")
                .font(LumeType.serif(32))
                .foregroundStyle(LumeColor.ink)
            Spacer()
            Text(LumeDateFormat.monthFull(.now))
                .font(LumeType.sans(13.5, weight: .bold))
                .foregroundStyle(LumeColor.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .lumeSoftGlass(cornerRadius: 999, opacity: 0.6, shadow: false)
        }
    }

    private var progressFooter: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                Capsule()
                    .fill(.white.opacity(0.22))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LumeColor.roseBadge)
                            .frame(width: geo.size.width * min(1, usedFraction))
                    }
            }
            .frame(height: 8)

            HStack {
                Text("\(LumeCurrency.full(cycleSpent)) usados")
                Spacer()
                Text("de \(LumeCurrency.full(profile?.allowanceAmount ?? 0))")
            }
            .font(LumeType.sans(12.5))
            .foregroundStyle(LumeColor.brandOnPlumLabel)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                LumeChip(title: "Tudo", isSelected: categoryFilter == nil) { categoryFilter = nil }
                ForEach(FinanceCategory.allCases) { category in
                    LumeChip(title: category.label, isSelected: categoryFilter == category) {
                        categoryFilter = categoryFilter == category ? nil : category
                    }
                }
            }
        }
        .lumeRiseIn(delay: 0.08)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf")
                .font(.system(size: 28))
                .foregroundStyle(LumeColor.textFainter)
            Text("Nenhum gasto por aqui ainda.")
                .font(LumeType.sans(14.5))
                .foregroundStyle(LumeColor.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var filteredExpenses: [Expense] {
        guard let categoryFilter else { return allExpenses }
        return allExpenses.filter { $0.category == categoryFilter }
    }

    private var groupedByDay: [(String, [Expense])] {
        let groups = Dictionary(grouping: filteredExpenses) { $0.date.startOfDay }
        return groups.keys.sorted(by: >).map { day in
            let label: String
            if day.isToday { label = "Hoje" }
            else if day.isYesterday { label = "Ontem" }
            else { label = LumeDateFormat.dayMonthAbbrev(day) }
            return (label, groups[day]!.sorted { $0.date > $1.date })
        }
    }

    private var cycleStart: Date { profile?.currentCycleStart() ?? .now.startOfDay }

    private var cycleSpent: Double {
        allExpenses.filter { $0.date >= cycleStart }.reduce(0) { $0 + $1.amount }
    }

    private var availableBalance: Double {
        (profile?.allowanceAmount ?? 0) - cycleSpent
    }

    private var usedFraction: Double {
        guard let allowance = profile?.allowanceAmount, allowance > 0 else { return 0 }
        return cycleSpent / allowance
    }

    private var nextAllowanceLabel: String {
        guard let profile else { return "" }
        return LumeDateFormat.dayMonthAbbrev(profile.nextAllowanceDate())
    }
}

private struct ExpenseRow: View {
    var expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(expense.category.iconBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: expense.category.symbolName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(LumeColor.textSecondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(LumeType.sans(15.5, weight: .bold))
                    .foregroundStyle(LumeColor.ink)
                    .lineLimit(1)
                Text("\(expense.category.label) · \(LumeDateFormat.time(expense.date))")
                    .font(LumeType.sans(13))
                    .foregroundStyle(LumeColor.textFaint)
            }

            Spacer()

            Text("−\(LumeCurrency.full(expense.amount))")
                .font(LumeType.serif(19))
                .foregroundStyle(LumeColor.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}
