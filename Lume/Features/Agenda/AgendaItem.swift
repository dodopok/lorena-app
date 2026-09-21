import EventKit
import Foundation

/// A display-layer item merging Lume's own events with read-only ones synced
/// in from the system Calendar (see `CalendarSyncService`).
struct AgendaItem: Identifiable, Hashable {
    let id: String
    var title: String
    var location: String?
    var start: Date
    var end: Date?
    var category: AgendaCategory
    var isExternal: Bool
    var remindToLogExpense: Bool
    var loggedExpense: Bool
    var sourceEvent: CalendarEvent?

    static func == (lhs: AgendaItem, rhs: AgendaItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var timeRangeLabel: String {
        guard let end else { return LumeDateFormat.time(start) }
        return "\(LumeDateFormat.time(start)) – \(LumeDateFormat.time(end))"
    }

    init(event: CalendarEvent) {
        id = "lume-\(event.persistentModelID)"
        title = event.title
        location = event.location
        start = event.startDate
        end = event.endDate
        category = event.category
        isExternal = false
        remindToLogExpense = event.remindToLogExpense
        loggedExpense = event.loggedExpense
        sourceEvent = event
    }

    init(external ekEvent: EKEvent) {
        id = "ek-\(ekEvent.eventIdentifier ?? UUID().uuidString)"
        title = ekEvent.title ?? "Compromisso"
        location = ekEvent.location
        start = ekEvent.startDate
        end = ekEvent.endDate
        category = .rotina
        isExternal = true
        remindToLogExpense = false
        loggedExpense = false
        sourceEvent = nil
    }

    static func merged(lumeEvents: [CalendarEvent], external: [EKEvent]) -> [AgendaItem] {
        let items = lumeEvents.map(AgendaItem.init(event:)) + external.map(AgendaItem.init(external:))
        return items.sorted { $0.start < $1.start }
    }
}
