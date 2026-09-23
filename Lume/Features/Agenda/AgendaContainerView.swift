import SwiftUI
import SwiftData

enum AgendaMode: String, Hashable {
    case day, week, month
}

struct AgendaContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startDate) private var lumeEvents: [CalendarEvent]
    @State private var mode: AgendaMode = .day
    @State private var selectedDate = Date.now
    @State private var showingNewEvent = false
    @State private var selectedItem: AgendaItem?
    @State private var eventToDelete: CalendarEvent?
    @State private var showingDeleteConfirmation = false
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
                        if mode == .month {
                            LumeGlassIconButton(systemImage: "chevron.left", size: 40, iconSize: 15) {
                                moveMonth(by: -1)
                            }
                            LumeGlassIconButton(systemImage: "chevron.right", size: 40, iconSize: 15) {
                                moveMonth(by: 1)
                            }
                        }
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
                            AgendaDayView(
                                selectedDate: $selectedDate,
                                allItems: allItems(for: selectedDate.startOfDay, to: selectedDate.adding(days: 1)),
                                onSelect: showDetails
                            )
                        case .week:
                            AgendaWeekView(
                                selectedDate: $selectedDate,
                                itemsProvider: { start, end in allItems(for: start, to: end) },
                                onSelect: showDetails
                            )
                        case .month:
                            AgendaMonthView(
                                selectedDate: $selectedDate,
                                itemsProvider: { start, end in allItems(for: start, to: end) },
                                onSelect: showDetails
                            )
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
            .sheet(item: $selectedItem) { item in
                AgendaEventDetailSheet(
                    item: item,
                    onDelete: {
                        guard let event = item.sourceEvent else { return }
                        selectedItem = nil
                        eventToDelete = event
                        showingDeleteConfirmation = true
                    }
                )
            }
            .confirmationDialog("Apagar este compromisso?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Apagar", role: .destructive) {
                    deletePendingEvent()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Essa ação não pode ser desfeita.")
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

    private func showDetails(_ item: AgendaItem) {
        selectedItem = item
    }

    private func moveMonth(by amount: Int) {
        let calendar = LumeDateFormat.calendar
        guard let month = calendar.dateInterval(of: .month, for: selectedDate),
              let destination = calendar.date(byAdding: .month, value: amount, to: month.start) else { return }
        let day = calendar.component(.day, from: selectedDate)
        let destinationRange = calendar.range(of: .day, in: .month, for: destination) ?? 1..<2
        let clampedDay = min(day, destinationRange.count)
        var components = calendar.dateComponents([.year, .month], from: destination)
        components.day = clampedDay
        withAnimation(.easeOut(duration: 0.2)) {
            selectedDate = calendar.date(from: components) ?? destination
        }
    }

    private func deletePendingEvent() {
        guard let eventToDelete else { return }
        NotificationScheduler.shared.cancelExpenseReminder(for: eventToDelete)
        // Deleting a Lume event intentionally does not delete any expense
        // already logged from it.
        modelContext.delete(eventToDelete)
        try? modelContext.save()
        self.eventToDelete = nil
    }
}
