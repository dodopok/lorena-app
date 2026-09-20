import SwiftUI
import SwiftData

enum TodaySheet: String, Identifiable {
    case bathroom, newExpense, exercise
    var id: String { rawValue }
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \WaterEntry.date, order: .reverse) private var waterEntries: [WaterEntry]
    @Query(sort: \BathroomEntry.date, order: .reverse) private var bathroomEntries: [BathroomEntry]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]
    @Query(sort: \ExerciseEntry.date, order: .reverse) private var exerciseEntries: [ExerciseEntry]

    @State private var activeSheet: TodaySheet?

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.roseOrb, size: 300, opacity: 0.5, blur: 58, alignment: .topTrailing, offset: CGSize(width: 70, height: -60), duration: 15),
        OrbSpec(color: LumeColor.greenOrb, size: 280, opacity: 0.42, blur: 58, alignment: .topLeading, offset: CGSize(width: -90, height: 300), duration: 19, reversed: true),
        OrbSpec(color: LumeColor.amberOrb, size: 260, opacity: 0.42, blur: 58, alignment: .bottomTrailing, offset: CGSize(width: -80, height: 60), duration: 23),
    ]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                LumeColor.canvas.ignoresSafeArea()
                LumeOrbBackground(orbs: orbs)

                ScrollView {
                    VStack(spacing: 12) {
                        header
                            .padding(.top, 4)
                            .lumeRiseIn()

                        if let next = nextEvent {
                            NextEventCard(event: next)
                                .lumeRiseIn(delay: 0.06)
                        }

                        WaterQuickCard(currentML: todayWaterTotal, goalML: profile?.waterGoalML ?? 2000) { amount in
                            logWater(amount)
                        }
                        .lumeRiseIn(delay: 0.12)

                        VStack(spacing: 10) {
                            HStack {
                                Text("Um toque")
                                    .font(LumeType.sans(17, weight: .heavy))
                                    .foregroundStyle(LumeColor.ink)
                                Spacer()
                                NavigationLink("Editar") { SettingsView() }
                                    .font(LumeType.sans(14, weight: .bold))
                                    .tint(LumeColor.brand)
                            }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                QuickTapTile(
                                    symbol: "toilet.fill",
                                    tint: LumeColor.greenDeep,
                                    iconBackground: LumeColor.greenChipBg,
                                    title: "Banheiro",
                                    subtitle: "\(todayBathroomCount) hoje",
                                    titleColor: LumeColor.greenTextDeep,
                                    subtitleColor: LumeColor.greenText
                                ) { activeSheet = .bathroom }

                                QuickTapTile(
                                    symbol: "figure.walk",
                                    tint: LumeColor.lavenderText,
                                    iconBackground: LumeColor.lavenderChipBgFaint,
                                    title: "Exercício",
                                    subtitle: todayExerciseLabel,
                                    titleColor: LumeColor.lavenderTextDeep,
                                    subtitleColor: LumeColor.lavenderText
                                ) { activeSheet = .exercise }

                                QuickTapTile(
                                    symbol: "cart.fill",
                                    tint: LumeColor.amberDeep,
                                    iconBackground: LumeColor.amberChipBg,
                                    title: "Gasto",
                                    subtitle: "R$ \(LumeCurrency.integer(Int(todayExpenseTotal))) hoje",
                                    titleColor: LumeColor.amberText,
                                    subtitleColor: LumeColor.amberLabel
                                ) { activeSheet = .newExpense }
                            }
                        }
                        .lumeRiseIn(delay: 0.18)

                        AvailableBalanceCard(
                            available: availableBalance,
                            subtitle: "até \(shortDate(profile?.nextAllowanceDate() ?? .now))"
                        )
                        .lumeRiseIn(delay: 0.24)

                        Color.clear.frame(height: 110) // room for the floating tab bar
                    }
                    .padding(.horizontal, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .bathroom: BathroomSheetView()
                case .newExpense: NewExpenseView()
                case .exercise: ExerciseComposerView()
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                LumeEyebrow(text: LumeDateFormat.fullWeekdayDayMonth(.now))
                Text("\(greeting), \(profile?.name.isEmpty == false ? profile!.name : "você")")
                    .font(LumeType.serif(36))
                    .foregroundStyle(LumeColor.ink)
            }
            Spacer()
            NavigationLink { SettingsView() } label: {
                Text(profile?.initial ?? "L")
                    .font(LumeType.serif(19))
                    .foregroundStyle(LumeColor.brandDeep)
                    .frame(width: 46, height: 46)
            }
            .lumeGlassCircle()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Bom dia"
        case 12..<18: return "Boa tarde"
        default: return "Boa noite"
        }
    }

    private var todayWaterTotal: Int {
        waterEntries.filter(\.date.isToday).reduce(0) { $0 + $1.amountML }
    }

    private var todayBathroomCount: Int {
        bathroomEntries.filter(\.date.isToday).count
    }

    private var todayExerciseLabel: String {
        exerciseEntries.first(where: \.date.isToday)?.type ?? "Nenhum hoje"
    }

    private var todayExpenseTotal: Double {
        expenses.filter(\.date.isToday).reduce(0) { $0 + $1.amount }
    }

    private var nextEvent: CalendarEvent? {
        events.first { $0.startDate >= .now }
    }

    private var availableBalance: Double {
        guard let profile else { return 0 }
        let cycleStart = profile.currentCycleStart()
        let spent = expenses.filter { $0.date >= cycleStart }.reduce(0) { $0 + $1.amount }
        return profile.allowanceAmount - spent
    }

    private func shortDate(_ date: Date) -> String {
        LumeDateFormat.dayMonthAbbrev(date).replacingOccurrences(of: " ", with: "/")
    }

    private func logWater(_ amount: Int) {
        let entry = WaterEntry(amountML: amount)
        modelContext.insert(entry)
        try? modelContext.save()
        LiveActivityController.shared.logWater(totalML: todayWaterTotal, goalML: profile?.waterGoalML ?? 2000)
    }
}
