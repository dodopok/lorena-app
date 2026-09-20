import SwiftUI
import SwiftData

enum AgendaMode: String, Hashable {
    case day, week, month
}

struct AgendaContainerView: View {
    @Query(sort: \CalendarEvent.startDate) private var lumeEvents: [CalendarEvent]
    @State private var mode: AgendaMode = .day
    @State private var selectedDate = Date.now
    @State private var showingNewEvent = false
    @State private var calendarSync = CalendarSyncService.shared

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.lavenderOrb, size: 300, opacity: 0.5, blur: 58, alignment: .topTrailing, offset: CGSize(width: 80, height: -50), duration: 18),
        OrbSpec(color: LumeColor.roseOrb, size: 260, opacity: 0.42, blur: 54, alignment: .bottomLeading, offset: CGSize(width: -70, height: 120), duration: 22, reversed: true),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LumeColor.canvas.ignoresSafeArea()
                LumeOrbBackground(orbs: orbs)

                VStack(spacing: 14) {
                    HStack {
                        Text(title)
                            .font(LumeType.serif(mode == .day ? 32 : 30))
                            .foregroundStyle(LumeColor.ink)
                        Spacer()
                        LumeGlassIconButton(systemImage: "plus", size: 40, iconSize: 18) {
                            showingNewEvent = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .lumeRiseIn()

                    LumeSegmentedControl(
                        options: [(AgendaMode.day, "Dia"), (.week, "Semana"), (.month, "Mês")],
                        selection: $mode
                    )
                    .padding(.horizontal, 20)

                    Group {
                        switch mode {
                        case .day:
                            AgendaDayView(selectedDate: $selectedDate, allItems: allItems(for: selectedDate.startOfDay, to: selectedDate.adding(days: 1)))
                        case .week:
                            AgendaWeekView(selectedDate: $selectedDate, itemsProvider: { start, end in allItems(for: start, to: end) })
                        case .month:
                            AgendaMonthView(selectedDate: $selectedDate, itemsProvider: { start, end in allItems(for: start, to: end) })
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNewEvent) {
                NewEventSheet(initialDate: selectedDate)
            }
            .task {
                if CalendarSyncService.currentStatus == .fullAccess || CalendarSyncService.currentStatus == .authorized {
                    await calendarSync.requestAccess()
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .day: LumeDateFormat.monthFull(selectedDate)
        case .week: LumeDateFormat.weekRange(containing: selectedDate)
        case .month: LumeDateFormat.monthYear(selectedDate)
        }
    }

    private func allItems(for start: Date, to end: Date) -> [AgendaItem] {
        let lume = lumeEvents.filter { $0.startDate >= start && $0.startDate < end }
        let external = calendarSync.events(from: start, to: end)
        return AgendaItem.merged(lumeEvents: lume, external: external)
    }
}
