import SwiftUI
import SwiftData

/// Screen 17 — amount first, then what it was for. The chip below the
/// number always shows what stays available after this expense.
///
/// Computes the available balance itself (rather than trusting a value
/// passed in by the caller) so it's always correct no matter which screen
/// presents it.
struct NewExpenseView: View {
    var eventToLink: CalendarEvent?
    var expenseToEdit: Expense?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \MoneyAddition.date, order: .reverse) private var moneyAdditions: [MoneyAddition]

    @State private var digits = ""
    @State private var title = ""
    @State private var category: FinanceCategory = .mercado
    @FocusState private var titleFocused: Bool

    private var amount: Double { LumeCurrency.amount(fromDigits: digits) }

    init(eventToLink: CalendarEvent? = nil, expenseToEdit: Expense? = nil) {
        self.eventToLink = eventToLink
        self.expenseToEdit = expenseToEdit
        _digits = State(initialValue: expenseToEdit.map { String(Int(($0.amount * 100).rounded())) } ?? "")
        _title = State(initialValue: expenseToEdit?.title ?? "")
        _category = State(initialValue: expenseToEdit?.category ?? .mercado)
    }

    private var availableBalance: Double {
        guard let profile = profiles.first else { return 0 }
        let cycleStart = profile.currentCycleStart()
        let spent = allExpenses
            .filter { expense in
                let isEditing = expenseToEdit.map { $0.persistentModelID == expense.persistentModelID } ?? false
                return expense.date >= cycleStart && !isEditing
            }
            .reduce(0) { $0 + $1.amount }
        let added = moneyAdditions
            .filter { $0.date >= cycleStart }
            .reduce(0) { $0 + $1.amount }
        return profile.allowanceAmount + added - spent
    }

    private var remaining: Double { availableBalance - amount }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: expenseToEdit == nil ? "Novo gasto" : "Editar gasto",
                trailingTitle: "Salvar",
                trailingEnabled: amount > 0,
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 14) {
                        LumeAmountField(digits: $digits, fontSize: 60)

                        HStack(spacing: 8) {
                            Circle().fill(LumeColor.brand).frame(width: 8, height: 8)
                            Text("Ficam \(LumeCurrency.full(remaining)) disponíveis")
                                .font(LumeType.sans(13.5, weight: .bold))
                                .foregroundStyle(LumeColor.brandDeep)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(.white.opacity(0.7)))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Descrição")
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                        TextField("Com o que foi?", text: $title)
                            .font(LumeType.sans(17, weight: .semibold))
                            .foregroundStyle(LumeColor.ink)
                            .focused($titleFocused)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .lumeSoftGlass(cornerRadius: 20, opacity: 0.65, shadow: false)

                    VStack(alignment: .leading, spacing: 10) {
                        LumeEyebrow(text: "Categoria")
                        LumeWrapChips(items: FinanceCategory.allCases, selection: $category) { $0.label }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let eventToLink {
                title = eventToLink.title
                category = .saude
            }
        }
    }

    private func save() {
        guard amount > 0 else { return }
        let name = title.trimmingCharacters(in: .whitespaces).isEmpty ? category.label : title
        if let expenseToEdit {
            expenseToEdit.title = name
            expenseToEdit.amount = amount
            expenseToEdit.category = category
        } else {
            modelContext.insert(Expense(title: name, amount: amount, category: category))
        }
        if let eventToLink {
            eventToLink.loggedExpense = true
        }
        try? modelContext.save()
        dismiss()
    }
}

/// A wrapping row of selectable chips, used for category pickers.
struct LumeWrapChips<Item: Hashable>: View {
    var items: [Item]
    @Binding var selection: Item
    var label: (Item) -> String

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                LumeChip(title: label(item), isSelected: item == selection) { selection = item }
            }
        }
    }
}

/// A minimal wrapping HStack — chips flow onto new lines instead of scrolling.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width.isFinite ? width : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
