import Foundation
import SwiftData

/// Serializes the active SwiftData store into a complete CloudKit backup.
@MainActor
enum LumeBackupArchiveService {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    enum ArchiveError: LocalizedError {
        case incompleteSnapshot([String])
        case profileNotReady
        case invalidJSON

        var errorDescription: String? {
            switch self {
            case .incompleteSnapshot(let sections):
                return "Não foi possível ler todos os dados do backup: " + sections.joined(separator: ", ")
            case .profileNotReady:
                return "Conclua o cadastro inicial antes de fazer o primeiro backup."
            case .invalidJSON:
                return "Não foi possível montar o arquivo de backup."
            }
        }
    }

    static func writeBackupExport() throws -> URL {
        let container = try LumeModelContainer.makeForCurrentStore()
        let result = exportRecords(from: ModelContext(container))
        guard result.errors.isEmpty else {
            throw ArchiveError.incompleteSnapshot(result.errors.keys.sorted())
        }
        guard let profiles = result.records["profiles"] as? [[String: Any]],
              profiles.contains(where: { ($0["hasCompletedOnboarding"] as? Bool) == true }) else {
            throw ArchiveError.profileNotReady
        }

        let document: [String: Any] = [
            "format": "lume-backup-v1",
            "exportedAt": isoFormatter.string(from: .now),
            "counts": result.counts,
            "records": result.records
        ]
        guard JSONSerialization.isValidJSONObject(document),
              let data = try? JSONSerialization.data(
                withJSONObject: document,
                options: [.sortedKeys]
              ) else {
            throw ArchiveError.invalidJSON
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lume-backup-\(UUID().uuidString).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private struct ExportResult {
        var counts: [String: Int] = [:]
        var records: [String: Any] = [:]
        var errors: [String: String] = [:]
    }

    private static func exportRecords(from context: ModelContext) -> ExportResult {
        var result = ExportResult()

        func capture(_ key: String, _ body: () throws -> [[String: Any]]) {
            do {
                let rows = try body()
                result.records[key] = rows
                result.counts[key] = rows.count
            } catch {
                result.records[key] = []
                result.counts[key] = 0
                result.errors[key] = String(describing: error)
            }
        }

        capture("profiles") {
            try context.fetch(FetchDescriptor<UserProfile>()).map { profile in
                [
                    "name": profile.name,
                    "waterGoalML": profile.waterGoalML,
                    "allowanceAmount": profile.allowanceAmount,
                    "allowanceDay": profile.allowanceDay,
                    "authMethodRaw": profile.authMethodRaw,
                    "faceIDEnabled": profile.faceIDEnabled,
                    "waterRemindersEnabled": profile.waterRemindersEnabled,
                    "gratitudeReminderEnabled": profile.gratitudeReminderEnabled,
                    "postEventExpenseReminderEnabled": profile.postEventExpenseReminderEnabled,
                    "hasCompletedOnboarding": profile.hasCompletedOnboarding,
                    "createdAt": dateString(profile.createdAt)
                ]
            }
        }

        capture("water") {
            try context.fetch(FetchDescriptor<WaterEntry>()).map { entry in
                ["date": dateString(entry.date), "amountML": entry.amountML]
            }
        }

        capture("bathroom") {
            try context.fetch(FetchDescriptor<BathroomEntry>()).map { entry in
                ["date": dateString(entry.date)]
            }
        }

        capture("expenses") {
            try context.fetch(FetchDescriptor<Expense>()).map { expense in
                [
                    "title": expense.title,
                    "amount": expense.amount,
                    "categoryRaw": expense.categoryRaw,
                    "date": dateString(expense.date)
                ]
            }
        }

        capture("moneyAdditions") {
            try context.fetch(FetchDescriptor<MoneyAddition>()).map { addition in
                [
                    "title": addition.title,
                    "amount": addition.amount,
                    "date": dateString(addition.date)
                ]
            }
        }

        capture("events") {
            try context.fetch(FetchDescriptor<CalendarEvent>()).map { event in
                [
                    "id": event.id.uuidString,
                    "title": event.title,
                    "location": optional(event.location),
                    "startDate": dateString(event.startDate),
                    "endDate": optional(event.endDate.map(dateString)),
                    "categoryRaw": event.categoryRaw,
                    "remindToLogExpense": event.remindToLogExpense,
                    "loggedExpense": event.loggedExpense
                ]
            }
        }

        capture("todos") {
            try context.fetch(FetchDescriptor<DailyTodo>()).map { todo in
                [
                    "title": todo.title,
                    "date": dateString(todo.date),
                    "isCompleted": todo.isCompleted,
                    "createdAt": dateString(todo.createdAt)
                ]
            }
        }

        capture("gratitude") {
            try context.fetch(FetchDescriptor<GratitudeEntry>()).map { entry in
                [
                    "text": entry.text,
                    "date": dateString(entry.date),
                    "photoDataBase64": optional(entry.photoData?.base64EncodedString())
                ]
            }
        }

        capture("books") {
            try context.fetch(FetchDescriptor<Book>()).map { book in
                [
                    "title": book.title,
                    "author": book.author,
                    "statusRaw": book.statusRaw,
                    "currentPage": book.currentPage,
                    "totalPages": book.totalPages,
                    "rating": book.rating,
                    "review": optional(book.review),
                    "coverColorHex": book.coverColorHex,
                    "coverURLString": optional(book.coverURLString),
                    "coverImageDataBase64": optional(book.coverImageData?.base64EncodedString()),
                    "dateAdded": dateString(book.dateAdded)
                ]
            }
        }

        capture("movies") {
            try context.fetch(FetchDescriptor<MovieShow>()).map { movie in
                [
                    "title": movie.title,
                    "kind": movie.kind,
                    "year": optional(movie.year),
                    "imageURLString": optional(movie.imageURLString),
                    "sourceURLString": optional(movie.sourceURLString),
                    "statusRaw": movie.statusRaw,
                    "rating": optional(movie.rating),
                    "review": optional(movie.review),
                    "dateAdded": dateString(movie.dateAdded)
                ]
            }
        }

        capture("wishlist") {
            try context.fetch(FetchDescriptor<WishlistItem>()).map { item in
                [
                    "name": item.name,
                    "price": item.price,
                    "originalPrice": optional(item.originalPrice),
                    "sourceURLString": optional(item.sourceURLString),
                    "imageDataBase64": optional(item.imageData?.base64EncodedString()),
                    "listName": item.listName,
                    "notifyOnPriceDrop": item.notifyOnPriceDrop,
                    "dateAdded": dateString(item.dateAdded),
                    "purchased": item.purchased
                ]
            }
        }

        capture("shoppingLists") {
            try context.fetch(FetchDescriptor<ShoppingList>()).map { list in
                ["name": list.name, "dateCreated": dateString(list.dateCreated)]
            }
        }

        capture("exercise") {
            try context.fetch(FetchDescriptor<ExerciseEntry>()).map { entry in
                [
                    "type": entry.type,
                    "durationMinutes": entry.durationMinutes,
                    "intensityRaw": entry.intensityRaw,
                    "date": dateString(entry.date)
                ]
            }
        }

        capture("wordProgress") {
            try context.fetch(FetchDescriptor<WordDayProgress>()).map { progress in
                [
                    "dayIndex": progress.dayIndex,
                    "foundWords": progress.foundWords,
                    "bonusWords": progress.bonusWords,
                    "hintsUsed": progress.hintsUsed,
                    "lastHintAt": optional(progress.lastHintAt.map(dateString)),
                    "revealedByHint": progress.revealedByHint,
                    "completedAt": optional(progress.completedAt.map(dateString))
                ]
            }
        }

        result.counts["total"] = result.counts.values.reduce(0, +)
        return result
    }

    private static func dateString(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static func optional(_ value: Any?) -> Any {
        value ?? NSNull()
    }
}
