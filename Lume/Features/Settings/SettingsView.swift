import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @Query private var waterEntries: [WaterEntry]
    @Query private var bathroomEntries: [BathroomEntry]
    @Query private var expenses: [Expense]
    @Query private var moneyAdditions: [MoneyAddition]
    @Query private var events: [CalendarEvent]
    @Query private var todos: [DailyTodo]
    @Query private var gratitudeEntries: [GratitudeEntry]
    @Query private var books: [Book]
    @Query private var movies: [MovieShow]
    @Query private var wishlistItems: [WishlistItem]
    @Query private var shoppingLists: [ShoppingList]
    @Query private var exerciseEntries: [ExerciseEntry]

    @State private var showingEraseConfirm = false
    @State private var editingName = false
    @State private var draftName = ""

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.roseOrb, size: 300, opacity: 0.45, blur: 58, alignment: .topLeading, offset: CGSize(width: -80, height: -60), duration: 19),
        OrbSpec(color: LumeColor.lavenderOrb, size: 260, opacity: 0.42, blur: 56, alignment: .bottomTrailing, offset: CGSize(width: -70, height: -80), duration: 24, reversed: true),
    ]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            LumeColor.canvas.ignoresSafeArea()
            LumeOrbBackground(orbs: orbs)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Hoje")
                        }
                        .font(LumeType.sans(15.5, weight: .bold))
                        .foregroundStyle(LumeColor.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Text("Ajustes")
                        .font(LumeType.serif(32))
                        .foregroundStyle(LumeColor.ink)

                    profileRow

                    sectionLabel("Metas")
                    settingsGroup {
                        NavigationLink { WaterGoalDetailView() } label: {
                            row(title: "Meta de água", value: "\(LumeCurrency.integer(profile?.waterGoalML ?? 2000)) ml")
                        }
                        divider
                        NavigationLink { AllowanceDetailView() } label: {
                            row(title: "Mesada", value: "\(LumeCurrency.full(profile?.allowanceAmount ?? 0)) · dia \(profile?.allowanceDay ?? 5)")
                        }
                    }

                    sectionLabel("Lembretes")
                    settingsGroup {
                        toggleRow("Água ao longo do dia", isOn: waterReminderBinding)
                        divider
                        toggleRow("Gratidão à noite", isOn: gratitudeReminderBinding)
                    }

                    sectionLabel("Privacidade")
                    settingsGroup {
                        toggleRow("Abrir com Face ID", isOn: faceIDBinding)
                        divider
                        NavigationLink { MoreSettingsDetailView() } label: {
                            row(title: "Mais ajustes", value: "")
                        }
                        divider
                        Button { showingEraseConfirm = true } label: {
                            HStack {
                                Text("Apagar tudo").foregroundStyle(LumeColor.errorText)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(LumeColor.errorFaint)
                            }
                            .font(LumeType.sans(15.5))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 15)
                        }
                        .buttonStyle(.plain)
                    }

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Apagar todos os dados do Lume?", isPresented: $showingEraseConfirm, titleVisibility: .visible) {
            Button("Apagar tudo", role: .destructive, action: eraseAll)
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Isso remove água, banheiro, gastos, agenda, gratidão, livros e desejos deste iPhone. Não pode ser desfeito.")
        }
        .alert("Como podemos te chamar?", isPresented: $editingName) {
            TextField("Nome", text: $draftName)
            Button("Salvar") { profile?.name = draftName; try? modelContext.save() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var profileRow: some View {
        Button {
            draftName = profile?.name ?? ""
            editingName = true
        } label: {
            HStack(spacing: 16) {
                Text(profile?.initial ?? "L")
                    .font(LumeType.serif(24))
                    .foregroundStyle(LumeColor.brandDeep)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(LumeColor.brandChipBg))
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile?.name.isEmpty == false ? profile!.name : "Sem nome")
                        .font(LumeType.sans(16.5, weight: .heavy))
                        .foregroundStyle(LumeColor.ink)
                    Text(profile?.authMethod == .apple ? "Conectada com Apple" : "Usando só neste iPhone")
                        .font(LumeType.sans(13))
                        .foregroundStyle(LumeColor.textFaint)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(LumeColor.textFainter)
            }
            .padding(18)
        }
        .buttonStyle(.plain)
        .lumeSoftGlass(cornerRadius: 26, shadow: false)
    }

    private func sectionLabel(_ text: String) -> some View {
        LumeEyebrow(text: text).padding(.top, 4)
    }

    private func settingsGroup(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) { content() }
            .lumeSoftGlass(cornerRadius: 24, shadow: false)
    }

    private var divider: some View {
        Divider().overlay(LumeColor.brandPlumStart.opacity(0.08))
    }

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title).font(LumeType.sans(15.5)).foregroundStyle(LumeColor.ink)
            Spacer()
            if !value.isEmpty {
                Text(value).font(LumeType.sans(15, weight: .bold)).foregroundStyle(LumeColor.textFaint)
            }
            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(LumeColor.textFainter)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).font(LumeType.sans(15.5)).foregroundStyle(LumeColor.ink)
        }
        .tint(LumeColor.brand)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var waterReminderBinding: Binding<Bool> {
        Binding(
            get: { profile?.waterRemindersEnabled ?? true },
            set: { newValue in
                profile?.waterRemindersEnabled = newValue
                try? modelContext.save()
                if let profile { NotificationScheduler.shared.scheduleDefaultReminders(for: profile) }
            }
        )
    }

    private var gratitudeReminderBinding: Binding<Bool> {
        Binding(
            get: { profile?.gratitudeReminderEnabled ?? true },
            set: { newValue in
                profile?.gratitudeReminderEnabled = newValue
                try? modelContext.save()
                if let profile { NotificationScheduler.shared.scheduleDefaultReminders(for: profile) }
            }
        )
    }

    private var faceIDBinding: Binding<Bool> {
        Binding(
            get: { profile?.faceIDEnabled ?? false },
            set: { newValue in
                profile?.faceIDEnabled = newValue
                try? modelContext.save()
            }
        )
    }

    private func eraseAll() {
        for entry in waterEntries { modelContext.delete(entry) }
        for entry in bathroomEntries { modelContext.delete(entry) }
        for entry in expenses { modelContext.delete(entry) }
        for entry in moneyAdditions { modelContext.delete(entry) }
        for entry in events { modelContext.delete(entry) }
        for entry in todos { modelContext.delete(entry) }
        for entry in gratitudeEntries { modelContext.delete(entry) }
        for entry in books { modelContext.delete(entry) }
        for entry in movies { modelContext.delete(entry) }
        for entry in wishlistItems { modelContext.delete(entry) }
        for entry in shoppingLists { modelContext.delete(entry) }
        for entry in exerciseEntries { modelContext.delete(entry) }
        try? modelContext.save()
    }
}
