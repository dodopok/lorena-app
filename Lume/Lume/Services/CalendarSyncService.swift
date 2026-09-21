import EventKit
import Foundation

/// The mockup's "Conecte o Google Agenda" is, natively, EventKit: once she's
/// added her Google account under iPhone Settings › Calendar, its events
/// already live in the system Calendar store — no OAuth, no backend, nothing
/// for Lume to build except asking permission and reading them (read-only).
@Observable
@MainActor
final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let store = EKEventStore()
    var isAuthorized: Bool = false

    private init() {
        isAuthorized = Self.currentStatus.isAuthorized
    }

    static var currentStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            await MainActor.run { isAuthorized = false }
            return false
        }
    }

    func events(from start: Date, to end: Date) -> [EKEvent] {
        guard isAuthorized else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).filter { !$0.isAllDay }
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
