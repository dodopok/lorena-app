import SwiftUI
import SwiftData

struct NewMoneyAdditionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var digits = ""
    @State private var title = ""

    private var amount: Double { LumeCurrency.amount(fromDigits: digits) }

    var body: some View {
        VStack(spacing: 0) {
            LumeSheetHeader(
                leadingTitle: "Cancelar",
                title: "Adicionar dinheiro",
                trailingTitle: "Salvar",
                trailingEnabled: amount > 0,
                onLeading: { dismiss() },
                onTrailing: save
            )
            .padding(.horizontal, 24)
            .padding(.top, 18)

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        LumeAmountField(digits: $digits, fontSize: 60, color: LumeColor.greenTextDeep)
                        Text("Esse valor aumenta o disponível deste ciclo.")
                            .font(LumeType.sans(13.5))
                            .foregroundStyle(LumeColor.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Descrição")
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                        TextField("Ex.: mesada extra", text: $title)
                            .font(LumeType.sans(17, weight: .semibold))
                            .foregroundStyle(LumeColor.ink)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .lumeSoftGlass(cornerRadius: 20, opacity: 0.65, shadow: false)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        guard amount > 0 else { return }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        modelContext.insert(MoneyAddition(title: name.isEmpty ? "Dinheiro adicionado" : name, amount: amount))
        try? modelContext.save()
        dismiss()
    }
}
