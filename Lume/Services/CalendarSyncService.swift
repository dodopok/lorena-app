import EventKit
import Foundation

/// Reads and edits events in the iPhone's system Calendar store. Accounts
/// added in iOS Settings (including Google accounts) are available through
/// EventKit without a separate sign-in flow.
@Observable
@MainActor
final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let store = EKEventStore()
    var isAuthorized: Bool = false
    private(set) var revision = 0
    private var storeChangeObserver: NSObjectProtocol?

    private init() {
        isAuthorized = Self.currentStatus.isAuthorized
        storeChangeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.revision &+= 1
            }
        }
    }

    static var currentStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            isAuthorized = granted
            revision &+= 1
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    func refreshAuthorizationStatus() {
        isAuthorized = Self.currentStatus.isAuthorized
        revision &+= 1
    }

    func events(from start: Date, to end: Date) -> [EKEvent] {
        guard isAuthorized else { return [] }
        _ = revision
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }

    func nextEvent(after date: Date = .now) -> EKEvent? {
        let end = Calendar.current.date(byAdding: .year, value: 1, to: date)
            ?? date.addingTimeInterval(365 * 24 * 60 * 60)
        return events(from: date, to: end).first { !$0.isAllDay }
    }

    func update(
        event: EKEvent,
        title: String,
        location: String?,
        startDate: Date,
        endDate: Date
    ) throws {
        guard isAuthorized else { throw CalendarSyncError.accessDenied }
        guard event.calendar.allowsContentModifications else { throw CalendarSyncError.readOnlyCalendar }

        let originalTitle = event.title
        let originalLocation = event.location
        let originalStart = event.startDate
        let originalEnd = event.endDate

        event.title = title
        event.location = location
        event.startDate = startDate
        event.endDate = max(endDate, startDate)

        do {
            try store.save(event, span: .thisEvent, commit: true)
            revision &+= 1
        } catch {
            event.title = originalTitle
            event.location = originalLocation
            event.startDate = originalStart
            event.endDate = originalEnd
            throw error
        }
    }
}

enum CalendarSyncError: LocalizedError {
    case accessDenied
    case readOnlyCalendar

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            "Permita o acesso completo ao Calendário para editar este compromisso."
        case .readOnlyCalendar:
            "Este calendário permite visualização, mas não permite alterações."
        }
    }
}

private extension EKAuthorizationStatus {
    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return self == .fullAccess
        }
        return self == .authorized
    }
}
