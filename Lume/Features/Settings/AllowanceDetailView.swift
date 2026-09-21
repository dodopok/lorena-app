import SwiftUI
import SwiftData

struct AllowanceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var digits: String = ""
    @State private var day: Int = 5

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            LumeColor.canvas.ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    LumeEyebrow(text: "Valor mensal", color: LumeColor.amberLabel)
                    LumeAmountField(digits: $digits, fontSize: 46)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lumeSoftGlass(cornerRadius: 26)

                Menu {
                    Picker("Dia", selection: $day) {
                        ForEach(1...28, id: \.self) { Text("Dia \($0)").tag($0) }
                    }
                } label: {
                    HStack {
                        Text("Cai todo dia").font(LumeType.sans(15.5)).foregroundStyle(LumeColor.ink)
                        Spacer()
                        Text("\(day) ▾").font(LumeType.sans(15, weight: .bold)).foregroundStyle(LumeColor.textFaint)
                    }
                    .padding(18)
                }
                .lumeSoftGlass(cornerRadius: 22, shadow: false)

                Spacer()

                LumePrimaryButton(title: "Salvar", action: save)
            }
            .padding(24)
            .padding(.top, 30)
        }
        .navigationTitle("Mesada")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            digits = String(Int((profile?.allowanceAmount ?? 0) * 100))
            day = profile?.allowanceDay ?? 5
        }
    }

    private func save() {
        guard let profile else { return }
        profile.allowanceAmount = LumeCurrency.amount(fromDigits: digits)
        profile.allowanceDay = day
        try? modelContext.save()
    }
}
