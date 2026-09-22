import SwiftUI
import SwiftData

struct MoreSettingsDetailView: View {
    @Environment(\.modelContext) private var modelContext
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

    @StateObject private var cloudBackup = LumeCloudBackupService.shared
    @State private var exportURL: URL?
    @State private var backupMessage = ""
    @State private var showingBackupAlert = false
    @State private var showingRestoreConfirmation = false
    @State private var backupAlertTitle = "Backup no iCloud"

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            LumeColor.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 0) {
                    Toggle(isOn: reminderBinding) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lembrete pós-compromisso").font(LumeType.sans(15.5)).foregroundStyle(LumeColor.ink)
                            Text("Avisa depois de eventos marcados para anotar o gasto.")
                                .font(LumeType.sans(12.5)).foregroundStyle(LumeColor.textFaint)
                        }
                    }
                    .tint(LumeColor.brand)
                    .padding(18)
                }
                .lumeSoftGlass(cornerRadius: 22, shadow: false)

                Group {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            exportRowLabel
                        }
                    } else {
                        Button(action: refreshExport) { exportRowLabel }
                    }
                }
                .buttonStyle(.plain)
                .lumeSoftGlass(cornerRadius: 22, shadow: false)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Backup diário no iCloud")
                        .font(LumeType.sans(13, weight: .bold))
                        .foregroundStyle(LumeColor.textFaint)

                    Text("O Lume salva uma cópia completa no iCloud quando você abre o app e tenta repetir o backup diariamente em segundo plano. O iOS escolhe o horário.")
                        .font(LumeType.sans(12.5))
                        .foregroundStyle(LumeColor.textFaint)

                    if cloudBackup.isWorking {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(LumeColor.brand)
                            Text("Falando com o iCloud…")
                                .font(LumeType.sans(13))
                                .foregroundStyle(LumeColor.textFaint)
                        }
                    } else if cloudBackup.isCheckingStatus {
                        Text("Verificando backup no iCloud…")
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                    } else if let date = cloudBackup.availableBackupDate {
                        Text("Último backup no iCloud: \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                    } else if !cloudBackup.statusMessage.isEmpty {
                        Text(cloudBackup.statusMessage)
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                    } else if let date = cloudBackup.lastBackupDate {
                        Text("Último snapshot salvo neste iPhone: \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                    } else {
                        Text("Ainda não foi encontrado um backup no iCloud.")
                            .font(LumeType.sans(12.5))
                            .foregroundStyle(LumeColor.textFaint)
                    }

                    Button(action: backupToICloud) {
                        backupRowLabel(
                            title: "Fazer backup agora",
                            systemImage: "icloud.and.arrow.up"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(cloudBackup.isWorking || cloudBackup.isCheckingStatus)

                    Button {
                        showingRestoreConfirmation = true
                    } label: {
                        backupRowLabel(
                            title: "Restaurar último backup",
                            systemImage: "icloud.and.arrow.down"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(cloudBackup.isWorking || cloudBackup.isCheckingStatus)
                }
                .padding(18)
                .lumeSoftGlass(cornerRadius: 22, shadow: false)

                Spacer()
            }
            .padding(24)
            .padding(.top, 24)
        }
        .navigationTitle("Mais ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshExport)
        .task {
            await cloudBackup.refreshBackupStatus()
        }
        .confirmationDialog(
            "Restaurar último backup?",
            isPresented: $showingRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restaurar e substituir dados", role: .destructive) {
                restoreFromICloud()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Os dados atuais deste iPhone serão substituídos pela cópia mais recente do iCloud.")
        }
        .alert(backupAlertTitle, isPresented: $showingBackupAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupMessage)
        }
    }

    private var exportRowLabel: some View {
        HStack {
            Text("Exportar dados").font(LumeType.sans(15.5)).foregroundStyle(LumeColor.ink)
            Spacer()
            Image(systemName: "square.and.arrow.up").foregroundStyle(LumeColor.brand)
        }
        .padding(18)
    }

    private func backupRowLabel(title: String, systemImage: String) -> some View {
        HStack {
            Text(title).font(LumeType.sans(15.5)).foregroundStyle(LumeColor.ink)
            Spacer()
            Image(systemName: systemImage).foregroundStyle(LumeColor.brand)
        }
        .contentShape(Rectangle())
    }

    private func refreshExport() {
        let snapshot = DataExportService.build(
            profile: profile, water: waterEntries, bathroom: bathroomEntries,
            expenses: expenses, moneyAdditions: moneyAdditions, events: events,
            todos: todos, gratitude: gratitudeEntries, books: books, movies: movies,
            wishlist: wishlistItems, shoppingLists: shoppingLists, exercise: exerciseEntries
        )
        exportURL = DataExportService.writeTempFile(snapshot)
    }

    private func backupToICloud() {
        Task {
            let result = await cloudBackup.backupNow()
            backupAlertTitle = "Backup no iCloud"
            backupMessage = result.message
            showingBackupAlert = true
        }
    }

    private func restoreFromICloud() {
        Task {
            let result = await cloudBackup.restoreLatestBackup(into: modelContext)
            backupAlertTitle = "Backup no iCloud"
            backupMessage = result.message
            showingBackupAlert = true
            await cloudBackup.refreshBackupStatus()
            refreshExport()
        }
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { profile?.postEventExpenseReminderEnabled ?? true },
            set: { newValue in
                profile?.postEventExpenseReminderEnabled = newValue
                try? modelContext.save()
            }
        )
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
