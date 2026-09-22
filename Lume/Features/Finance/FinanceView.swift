import SwiftUI
import SwiftData

struct FinanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \MoneyAddition.date, order: .reverse) private var moneyAdditions: [MoneyAddition]

    @State private var categoryFilter: FinanceCategory?
    @State private var showingNewExpense = false
    @State private var showingNewMoneyAddition = false
    @State private var expenseToEdit: Expense?
    @State private var showingDeleteConfirmation = false
    @State private var expenseToDelete: Expense?

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
                            subtitle: "Próxima mesada em \(nextAllowanceLabel).",
                            subtitleBelowAmount: true,
                            bottomInset: 56
                        )
                        .overlay(alignment: .bottom) { progressFooter }
                        .lumeRiseIn()

                        chipRow

                        if categoryFilter == nil && !moneyAdditions.isEmpty {
                            moneyAdditionsSection
                        }

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
                                            ExpenseRow(
                                                expense: expense,
                                                onEdit: {
                                                    expenseToEdit = expense
                                                },
                                                onDelete: {
                                                    expenseToDelete = expense
                                                    showingDeleteConfirmation = true
                                                }
                                            )
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

                LumeFloatingActionMenu(accessibilityLabel: "Adicionar movimentação financeira") {
                    Button {
                        showingNewExpense = true
                    } label: {
                        Label("Novo gasto", systemImage: "cart.fill")
                    }
                    Button {
                        showingNewMoneyAddition = true
                    } label: {
                        Label("Dinheiro recebido", systemImage: "plus.circle.fill")
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewExpense) {
                NewExpenseView()
            }
            .sheet(isPresented: $showingNewMoneyAddition) {
                NewMoneyAdditionView()
            }
            .sheet(item: $expenseToEdit) { expense in
                NewExpenseView(expenseToEdit: expense)
            }
            .confirmationDialog("Apagar este gasto?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Apagar", role: .destructive) {
                    deletePendingExpense()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Essa ação não pode ser desfeita.")
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
                Text("de \(LumeCurrency.full(cycleBudget))")
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

    private var moneyAdditionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            LumeEyebrow(text: "Entradas")
            VStack(spacing: 0) {
                ForEach(Array(moneyAdditions.enumerated()), id: \.element.persistentModelID) { index, addition in
                    if index > 0 {
                        Divider()
                            .overlay(LumeColor.greenDeep.opacity(0.1))
                            .padding(.leading, 72)
                    }
                    MoneyAdditionRow(addition: addition)
                }
            }
            .lumeSoftGlass(cornerRadius: 24, shadow: false)
        }
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

    private var cycleAdded: Double {
        moneyAdditions.filter { $0.date >= cycleStart }.reduce(0) { $0 + $1.amount }
    }

    private var cycleBudget: Double {
        (profile?.allowanceAmount ?? 0) + cycleAdded
    }

    private var availableBalance: Double {
        cycleBudget - cycleSpent
    }

    private var usedFraction: Double {
        guard cycleBudget > 0 else { return 0 }
        return cycleSpent / cycleBudget
    }

    private var nextAllowanceLabel: String {
        guard let profile else { return "" }
        return LumeDateFormat.dayMonthAbbrev(profile.nextAllowanceDate())
    }

    private func deletePendingExpense() {
        guard let expenseToDelete else { return }
        modelContext.delete(expenseToDelete)
        try? modelContext.save()
        self.expenseToDelete = nil
    }
}

private struct MoneyAdditionRow: View {
    var addition: MoneyAddition

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(LumeColor.greenChipBg)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(LumeColor.greenText)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(addition.title)
                    .font(LumeType.sans(15.5, weight: .bold))
                    .foregroundStyle(LumeColor.ink)
                    .lineLimit(1)
                Text(LumeDateFormat.time(addition.date))
                    .font(LumeType.sans(13))
                    .foregroundStyle(LumeColor.textFaint)
            }

            Spacer()

            Text("+\(LumeCurrency.full(addition.amount))")
                .font(LumeType.serif(19))
                .foregroundStyle(LumeColor.greenTextDeep)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

private struct ExpenseRow: View {
    var expense: Expense
    var onEdit: () -> Void
    var onDelete: () -> Void

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

            Menu {
                Button("Editar") { onEdit() }
                Button("Apagar", role: .destructive) { onDelete() }
            } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(LumeColor.textFainter)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}
