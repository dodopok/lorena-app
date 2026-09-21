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

    @State private var exportURL: URL?

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

                Spacer()
            }
            .padding(24)
            .padding(.top, 24)
        }
        .navigationTitle("Mais ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshExport)
    }

    private var exportRowLabel: some View {
        HStack {
            Text("Exportar dados").font(LumeType.sans(15.5)).foregroundStyle(LumeColor.ink)
            Spacer()
            Image(systemName: "square.and.arrow.up").foregroundStyle(LumeColor.brand)
        }
        .padding(18)
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
