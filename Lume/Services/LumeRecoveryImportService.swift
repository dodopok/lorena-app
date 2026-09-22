import Foundation
import SwiftData

/// Replaces the active SwiftData store with a validated iCloud backup.
@MainActor
enum LumeBackupImportService {
    struct ImportResult {
        var imported: [String: Int] = [:]
        var skipped: [String: Int] = [:]
        var errors: [String] = []
        var didRestoreBackup = false

        var importedTotal: Int { imported.values.reduce(0, +) }
        var skippedTotal: Int { skipped.values.reduce(0, +) }

        var message: String {
            if !errors.isEmpty {
                return "Restauração cancelada; os dados atuais foram mantidos. Problemas de leitura: \(errors.count)."
            }
            if didRestoreBackup && importedTotal == 0 {
                return "Backup aplicado; o snapshot estava vazio."
            }

            var parts = [String]()
            if didRestoreBackup {
                parts.append("Backup aplicado.")
            }
            if importedTotal > 0 {
                let details = imported
                    .filter { $0.value > 0 }
                    .sorted { $0.key < $1.key }
                    .map { "\($0.value) \($0.key)" }
                    .joined(separator: ", ")
                parts.append("Restaurados: \(details).")
            }
            if skippedTotal > 0 {
                parts.append("Ignorados por já existirem: \(skippedTotal).")
            }
            if !errors.isEmpty {
                parts.append("Alguns itens não puderam ser lidos: \(errors.count).")
            }
            return parts.joined(separator: " ")
        }
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func restoreBackupJSON(from url: URL, into context: ModelContext) -> ImportResult {
        do {
            let data = try Data(contentsOf: url)
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return ImportResult(errors: ["O arquivo não contém um objeto JSON válido."])
            }
            guard let records = validatedBackupRecords(from: object) else {
                return ImportResult(errors: ["O backup está incompleto ou em um formato não reconhecido."])
            }
            try context.save()
            return importObject(records, into: context, replacingExisting: true)
        } catch {
            return ImportResult(errors: [error.localizedDescription])
        }
    }

    private static let backupRecordKeys = [
        "profiles", "water", "bathroom", "expenses", "moneyAdditions", "events",
        "todos", "gratitude", "books", "movies", "wishlist", "shoppingLists",
        "exercise", "wordProgress"
    ]

    private static func validatedBackupRecords(from root: [String: Any]) -> [String: Any]? {
        let format = root["format"] as? String
        var section: [String: Any]

        if format == "lume-backup-v1" {
            guard let records = root["records"] as? [String: Any],
                  let counts = root["counts"] as? [String: Any] else {
                return nil
            }
            section = ["records": records, "counts": counts]
            if let errors = root["errors"] { section["errors"] = errors }
        } else if format == "lume-recovery-v2" {
            let sources = (root["sources"] as? [[String: Any]]) ?? []
            guard let activeStore = sources.first(where: { $0["source"] as? String == "app-group" }) else {
                return nil
            }
            section = activeStore
        } else {
            return nil
        }

        let errors = section["errors"] as? [String: Any] ?? [:]
        guard errors.isEmpty,
              let records = section["records"] as? [String: Any],
              let counts = section["counts"] as? [String: Any] else {
            return nil
        }

        var total = 0
        for key in backupRecordKeys {
            guard let rows = records[key] as? [Any],
                  let count = counts[key] as? NSNumber,
                  count.intValue == rows.count else {
                return nil
            }
            total += rows.count
        }
        guard let reportedTotal = counts["total"] as? NSNumber,
              reportedTotal.intValue == total else {
            return nil
        }
        return records
    }

    private static func importObject(
        _ root: [String: Any],
        into context: ModelContext,
        replacingExisting: Bool
    ) -> ImportResult {
        var result = ImportResult()
        let sections = recordSections(from: root)
        if replacingExisting {
            deleteAllRecords(from: context)
        }

        var profiles: [UserProfile] = replacingExisting ? [] : fetch(UserProfile.self, from: context)
        var water: [WaterEntry] = replacingExisting ? [] : fetch(WaterEntry.self, from: context)
        var bathroom: [BathroomEntry] = replacingExisting ? [] : fetch(BathroomEntry.self, from: context)
        var expenses: [Expense] = replacingExisting ? [] : fetch(Expense.self, from: context)
        var additions: [MoneyAddition] = replacingExisting ? [] : fetch(MoneyAddition.self, from: context)
        var events: [CalendarEvent] = replacingExisting ? [] : fetch(CalendarEvent.self, from: context)
        var todos: [DailyTodo] = replacingExisting ? [] : fetch(DailyTodo.self, from: context)
        var gratitude: [GratitudeEntry] = replacingExisting ? [] : fetch(GratitudeEntry.self, from: context)
        var books: [Book] = replacingExisting ? [] : fetch(Book.self, from: context)
        var movies: [MovieShow] = replacingExisting ? [] : fetch(MovieShow.self, from: context)
        var wishlist: [WishlistItem] = replacingExisting ? [] : fetch(WishlistItem.self, from: context)
        var shoppingLists: [ShoppingList] = replacingExisting ? [] : fetch(ShoppingList.self, from: context)
        var exercise: [ExerciseEntry] = replacingExisting ? [] : fetch(ExerciseEntry.self, from: context)
        var wordProgress: [WordDayProgress] = replacingExisting ? [] : fetch(WordDayProgress.self, from: context)

        if profiles.isEmpty && !sections.isEmpty {
            for section in sections {
                for profile in profileRows(in: section) {
                    guard let imported = makeProfile(from: profile) else {
                        result.errors.append("perfil")
                        continue
                    }
                    let signature = profileSignature(imported)
                    if profiles.contains(where: { profileSignature($0) == signature }) {
                        result.skipped["perfil"] = (result.skipped["perfil"] ?? 0) + 1
                        continue
                    }
                    let destination = profiles.first
                    if let destination {
                        if merge(imported: imported, into: destination) {
                            result.imported["perfil"] = (result.imported["perfil"] ?? 0) + 1
                        } else {
                            result.skipped["perfil"] = (result.skipped["perfil"] ?? 0) + 1
                        }
                    } else {
                        let created = UserProfile(
                            name: imported.name,
                            waterGoalML: imported.waterGoalML,
                            allowanceAmount: imported.allowanceAmount,
                            allowanceDay: imported.allowanceDay,
                            authMethodRaw: imported.authMethodRaw,
                            faceIDEnabled: imported.faceIDEnabled,
                            waterRemindersEnabled: imported.waterRemindersEnabled,
                            gratitudeReminderEnabled: imported.gratitudeReminderEnabled,
                            postEventExpenseReminderEnabled: imported.postEventExpenseReminderEnabled,
                            hasCompletedOnboarding: imported.hasCompletedOnboarding,
                            createdAt: imported.createdAt
                        )
                        context.insert(created)
                        profiles.append(created)
                        result.imported["perfil"] = (result.imported["perfil"] ?? 0) + 1
                    }
                }
            }
        } else if let destination = profiles.first {
            for section in sections {
                for profile in profileRows(in: section) {
                    guard let imported = makeProfile(from: profile) else {
                        result.errors.append("perfil")
                        continue
                    }
                    if merge(imported: imported, into: destination) {
                        result.imported["perfil"] = (result.imported["perfil"] ?? 0) + 1
                    } else {
                        result.skipped["perfil"] = (result.skipped["perfil"] ?? 0) + 1
                    }
                }
            }
        }

        var waterKeys = Set(water.map(waterSignature))
        var bathroomKeys = Set(bathroom.map(bathroomSignature))
        var expenseKeys = Set(expenses.map(expenseSignature))
        var additionKeys = Set(additions.map(additionSignature))
        var eventKeys = Set(events.flatMap { [$0.id.uuidString, eventContentSignature($0)] })
        var todoKeys = Set(todos.map(todoSignature))
        var gratitudeKeys = Set(gratitude.map(gratitudeSignature))
        var bookKeys = Set(books.map(bookSignature))
        var movieKeys = Set(movies.map(movieSignature))
        var wishlistKeys = Set(wishlist.map(wishlistSignature))
        var shoppingListKeys = Set(shoppingLists.map(shoppingListSignature))
        var exerciseKeys = Set(exercise.map(exerciseSignature))
        var wordProgressByDay = Dictionary(uniqueKeysWithValues: wordProgress.map { ($0.dayIndex, $0) })

        for section in sections {
            for row in rows("water", in: section) {
                guard let date = date(row["date"]), let amount = int(row["amountML"]) else {
                    result.errors.append("água")
                    continue
                }
                let key = fingerprint([iso(date), String(amount)])
                guard !shouldSkipDuplicate(key, in: &waterKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["água"] = (result.skipped["água"] ?? 0) + 1
                    continue
                }
                let created = WaterEntry(amountML: amount, date: date)
                context.insert(created)
                water.append(created)
                result.imported["água"] = (result.imported["água"] ?? 0) + 1
            }

            for row in rows("bathroom", in: section) {
                guard let date = date(row["date"]) else {
                    result.errors.append("banheiro")
                    continue
                }
                let key = fingerprint([iso(date)])
                guard !shouldSkipDuplicate(key, in: &bathroomKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["banheiro"] = (result.skipped["banheiro"] ?? 0) + 1
                    continue
                }
                let created = BathroomEntry(date: date)
                context.insert(created)
                bathroom.append(created)
                result.imported["banheiro"] = (result.imported["banheiro"] ?? 0) + 1
            }

            for row in rows("expenses", in: section) {
                guard let title = string(row["title"]),
                      let amount = double(row["amount"]),
                      let date = date(row["date"]) else {
                    result.errors.append("gasto")
                    continue
                }
                let categoryRaw = string(row["categoryRaw"] ?? row["category"]) ?? FinanceCategory.mercado.rawValue
                let key = fingerprint([title, String(amount), categoryRaw, iso(date)])
                guard !shouldSkipDuplicate(key, in: &expenseKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["gastos"] = (result.skipped["gastos"] ?? 0) + 1
                    continue
                }
                let created = Expense(
                    title: title,
                    amount: amount,
                    category: FinanceCategory(rawValue: categoryRaw) ?? .mercado,
                    date: date
                )
                context.insert(created)
                expenses.append(created)
                result.imported["gastos"] = (result.imported["gastos"] ?? 0) + 1
            }

            for row in rows("moneyAdditions", in: section) {
                guard let title = string(row["title"]),
                      let amount = double(row["amount"]),
                      let date = date(row["date"]) else {
                    result.errors.append("entrada financeira")
                    continue
                }
                let key = fingerprint([title, String(amount), iso(date)])
                guard !shouldSkipDuplicate(key, in: &additionKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["entradas"] = (result.skipped["entradas"] ?? 0) + 1
                    continue
                }
                let created = MoneyAddition(title: title, amount: amount, date: date)
                context.insert(created)
                additions.append(created)
                result.imported["entradas"] = (result.imported["entradas"] ?? 0) + 1
            }

            for row in rows("events", in: section) {
                guard let title = string(row["title"]),
                      let startDate = date(row["startDate"] ?? row["start"]) else {
                    result.errors.append("evento")
                    continue
                }
                let location = string(row["location"])
                let endDate = date(row["endDate"] ?? row["end"])
                let categoryRaw = string(row["categoryRaw"] ?? row["category"]) ?? AgendaCategory.pessoal.rawValue
                let remind = bool(row["remindToLogExpense"]) ?? false
                let logged = bool(row["loggedExpense"]) ?? false
                let importedID = uuid(row["id"])
                let contentKey = fingerprint([
                    title, location ?? "", iso(startDate), iso(endDate), categoryRaw,
                    String(remind), String(logged)
                ])
                let idKey = importedID?.uuidString
                let isDuplicateEvent = eventKeys.contains(contentKey) ||
                    (idKey.map { eventKeys.contains($0) } ?? false)
                if !replacingExisting && isDuplicateEvent {
                    result.skipped["eventos"] = (result.skipped["eventos"] ?? 0) + 1
                    continue
                }
                let created = CalendarEvent(
                    id: importedID ?? UUID(),
                    title: title,
                    location: location,
                    startDate: startDate,
                    endDate: endDate,
                    category: AgendaCategory(rawValue: categoryRaw) ?? .pessoal,
                    remindToLogExpense: remind,
                    loggedExpense: logged
                )
                context.insert(created)
                events.append(created)
                eventKeys.insert(contentKey)
                eventKeys.insert(created.id.uuidString)
                result.imported["eventos"] = (result.imported["eventos"] ?? 0) + 1
            }

            for row in rows("todos", in: section) {
                guard let title = string(row["title"]), let todoDate = date(row["date"]) else {
                    result.errors.append("tarefa")
                    continue
                }
                let completed = bool(row["isCompleted"] ?? row["completed"]) ?? false
                let createdAt = date(row["createdAt"]) ?? todoDate
                let key = fingerprint([title, iso(todoDate), String(completed), iso(createdAt)])
                guard !shouldSkipDuplicate(key, in: &todoKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["tarefas"] = (result.skipped["tarefas"] ?? 0) + 1
                    continue
                }
                let created = DailyTodo(title: title, date: todoDate, isCompleted: completed, createdAt: createdAt)
                context.insert(created)
                todos.append(created)
                result.imported["tarefas"] = (result.imported["tarefas"] ?? 0) + 1
            }

            for row in rows("gratitude", in: section) {
                guard let text = string(row["text"]), let date = date(row["date"]) else {
                    result.errors.append("gratidão")
                    continue
                }
                let photoData = data(row["photoDataBase64"])
                let key = fingerprint([text, iso(date)])
                if !replacingExisting,
                   let existing = gratitude.first(where: { gratitudeSignature($0) == key }) {
                    if existing.photoData == nil, let photoData {
                        existing.photoData = photoData
                        result.imported["gratidão"] = (result.imported["gratidão"] ?? 0) + 1
                    } else {
                        result.skipped["gratidão"] = (result.skipped["gratidão"] ?? 0) + 1
                    }
                    continue
                }
                guard !shouldSkipDuplicate(key, in: &gratitudeKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["gratidão"] = (result.skipped["gratidão"] ?? 0) + 1
                    continue
                }
                let created = GratitudeEntry(text: text, date: date, photoData: photoData)
                context.insert(created)
                gratitude.append(created)
                result.imported["gratidão"] = (result.imported["gratidão"] ?? 0) + 1
            }

            for row in rows("books", in: section) {
                guard let title = string(row["title"]), let author = string(row["author"]) else {
                    result.errors.append("livro")
                    continue
                }
                let statusRaw = string(row["statusRaw"] ?? row["status"]) ?? BookStatus.wantToRead.rawValue
                let currentPage = int(row["currentPage"]) ?? 0
                let totalPages = int(row["totalPages"]) ?? 0
                let rating = int(row["rating"]) ?? 0
                let review = string(row["review"])
                let coverColor = string(row["coverColorHex"]) ?? "E4D6E6"
                let coverURL = string(row["coverURLString"])
                let coverImage = data(row["coverImageDataBase64"])
                let dateAdded = date(row["dateAdded"]) ?? .now
                let key = fingerprint([
                    title, author, statusRaw, String(currentPage), String(totalPages), String(rating),
                    review ?? "", coverColor, coverURL ?? "", iso(dateAdded)
                ])
                guard !shouldSkipDuplicate(key, in: &bookKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["livros"] = (result.skipped["livros"] ?? 0) + 1
                    continue
                }
                let created = Book(
                    title: title,
                    author: author,
                    status: BookStatus(rawValue: statusRaw) ?? .wantToRead,
                    currentPage: currentPage,
                    totalPages: totalPages,
                    rating: rating,
                    review: review,
                    coverColorHex: coverColor,
                    coverURLString: coverURL,
                    coverImageData: coverImage,
                    dateAdded: dateAdded
                )
                context.insert(created)
                books.append(created)
                result.imported["livros"] = (result.imported["livros"] ?? 0) + 1
            }

            for row in rows("movies", in: section) {
                guard let title = string(row["title"]), let kind = string(row["kind"]) else {
                    result.errors.append("filme/série")
                    continue
                }
                let year = int(row["year"])
                let imageURL = string(row["imageURLString"])
                let sourceURL = string(row["sourceURLString"])
                let statusRaw = string(row["statusRaw"] ?? row["status"]) ?? WatchStatus.wantToWatch.rawValue
                let rating = int(row["rating"])
                let review = string(row["review"])
                let dateAdded = date(row["dateAdded"]) ?? .now
                let key = fingerprint([
                    title, kind, String(year ?? 0), imageURL ?? "", sourceURL ?? "", statusRaw,
                    String(rating ?? 0), review ?? "", iso(dateAdded)
                ])
                guard !shouldSkipDuplicate(key, in: &movieKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["filmes/séries"] = (result.skipped["filmes/séries"] ?? 0) + 1
                    continue
                }
                let created = MovieShow(
                    title: title,
                    kind: kind,
                    year: year,
                    imageURLString: imageURL,
                    sourceURLString: sourceURL,
                    status: WatchStatus(rawValue: statusRaw) ?? .wantToWatch,
                    rating: rating,
                    review: review,
                    dateAdded: dateAdded
                )
                context.insert(created)
                movies.append(created)
                result.imported["filmes/séries"] = (result.imported["filmes/séries"] ?? 0) + 1
            }

            for row in rows("wishlist", in: section) {
                guard let name = string(row["name"]), let price = double(row["price"]) else {
                    result.errors.append("desejo")
                    continue
                }
                let originalPrice = double(row["originalPrice"])
                let sourceURL = string(row["sourceURLString"])
                let image = data(row["imageDataBase64"])
                let listName = string(row["listName"]) ?? "Geral"
                let notify = bool(row["notifyOnPriceDrop"]) ?? true
                let dateAdded = date(row["dateAdded"]) ?? .now
                let purchased = bool(row["purchased"]) ?? false
                let key = fingerprint([
                    name, String(price), String(originalPrice ?? 0), sourceURL ?? "", listName,
                    String(notify), iso(dateAdded), String(purchased)
                ])
                guard !shouldSkipDuplicate(key, in: &wishlistKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["desejos"] = (result.skipped["desejos"] ?? 0) + 1
                    continue
                }
                let created = WishlistItem(
                    name: name,
                    price: price,
                    originalPrice: originalPrice,
                    sourceURLString: sourceURL,
                    imageData: image,
                    listName: listName,
                    notifyOnPriceDrop: notify,
                    dateAdded: dateAdded,
                    purchased: purchased
                )
                context.insert(created)
                wishlist.append(created)
                result.imported["desejos"] = (result.imported["desejos"] ?? 0) + 1
            }

            for row in rows("shoppingLists", in: section) {
                guard let name = string(row["name"]) else {
                    result.errors.append("lista de compras")
                    continue
                }
                let dateCreated = date(row["dateCreated"]) ?? .now
                let key = fingerprint([name, iso(dateCreated)])
                guard !shouldSkipDuplicate(key, in: &shoppingListKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["listas"] = (result.skipped["listas"] ?? 0) + 1
                    continue
                }
                let created = ShoppingList(name: name, dateCreated: dateCreated)
                context.insert(created)
                shoppingLists.append(created)
                result.imported["listas"] = (result.imported["listas"] ?? 0) + 1
            }

            for row in rows("exercise", in: section) {
                guard let type = string(row["type"]),
                      let duration = int(row["durationMinutes"]),
                      let date = date(row["date"]) else {
                    result.errors.append("exercício")
                    continue
                }
                let intensityRaw = string(row["intensityRaw"] ?? row["intensity"]) ?? ExerciseIntensity.leve.rawValue
                let key = fingerprint([type, String(duration), intensityRaw, iso(date)])
                guard !shouldSkipDuplicate(key, in: &exerciseKeys, preservingAllRecords: replacingExisting) else {
                    result.skipped["exercícios"] = (result.skipped["exercícios"] ?? 0) + 1
                    continue
                }
                let created = ExerciseEntry(
                    type: type,
                    durationMinutes: duration,
                    intensity: ExerciseIntensity(rawValue: intensityRaw) ?? .leve,
                    date: date
                )
                context.insert(created)
                exercise.append(created)
                result.imported["exercícios"] = (result.imported["exercícios"] ?? 0) + 1
            }

            for row in rows("wordProgress", in: section) {
                guard let dayIndex = int(row["dayIndex"]) else {
                    result.errors.append("Palavra do Dia")
                    continue
                }
                let foundWords = stringArray(row["foundWords"])
                let bonusWords = stringArray(row["bonusWords"])
                let hintsUsed = int(row["hintsUsed"]) ?? 0
                let lastHintAt = date(row["lastHintAt"])
                let revealedByHint = stringArray(row["revealedByHint"])
                let completedAt = date(row["completedAt"])

                if !replacingExisting, let existing = wordProgressByDay[dayIndex] {
                    let oldCount = existing.foundWords.count + existing.bonusWords.count + existing.revealedByHint.count
                    existing.foundWords = unique(existing.foundWords + foundWords)
                    existing.bonusWords = unique(existing.bonusWords + bonusWords)
                    existing.hintsUsed = max(existing.hintsUsed, hintsUsed)
                    existing.lastHintAt = maxDate(existing.lastHintAt, lastHintAt)
                    existing.revealedByHint = unique(existing.revealedByHint + revealedByHint)
                    existing.completedAt = maxDate(existing.completedAt, completedAt)
                    let newCount = existing.foundWords.count + existing.bonusWords.count + existing.revealedByHint.count
                    if newCount > oldCount {
                        result.imported["Palavra do Dia"] = (result.imported["Palavra do Dia"] ?? 0) + 1
                    } else {
                        result.skipped["Palavra do Dia"] = (result.skipped["Palavra do Dia"] ?? 0) + 1
                    }
                } else {
                    let created = WordDayProgress(dayIndex: dayIndex)
                    created.foundWords = foundWords
                    created.bonusWords = bonusWords
                    created.hintsUsed = hintsUsed
                    created.lastHintAt = lastHintAt
                    created.revealedByHint = revealedByHint
                    created.completedAt = completedAt
                    context.insert(created)
                    wordProgressByDay[dayIndex] = created
                    result.imported["Palavra do Dia"] = (result.imported["Palavra do Dia"] ?? 0) + 1
                }
            }
        }

        guard result.errors.isEmpty else {
            if replacingExisting { context.rollback() }
            return result
        }

        do {
            try context.save()
            result.didRestoreBackup = replacingExisting
        } catch {
            if replacingExisting { context.rollback() }
            result.errors.append(error.localizedDescription)
        }
        return result
    }

    private static func recordSections(from root: [String: Any]) -> [[String: Any]] {
        [root]
    }

    private static func deleteAllRecords(from context: ModelContext) {
        deleteAll(UserProfile.self, from: context)
        deleteAll(WaterEntry.self, from: context)
        deleteAll(BathroomEntry.self, from: context)
        deleteAll(Expense.self, from: context)
        deleteAll(MoneyAddition.self, from: context)
        deleteAll(CalendarEvent.self, from: context)
        deleteAll(DailyTodo.self, from: context)
        deleteAll(GratitudeEntry.self, from: context)
        deleteAll(Book.self, from: context)
        deleteAll(MovieShow.self, from: context)
        deleteAll(WishlistItem.self, from: context)
        deleteAll(ShoppingList.self, from: context)
        deleteAll(ExerciseEntry.self, from: context)
        deleteAll(WordDayProgress.self, from: context)
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, from context: ModelContext) {
        for model in fetch(type, from: context) {
            context.delete(model)
        }
    }

    private static func shouldSkipDuplicate(
        _ signature: String,
        in existing: inout Set<String>,
        preservingAllRecords: Bool
    ) -> Bool {
        let inserted = existing.insert(signature).inserted
        return !preservingAllRecords && !inserted
    }

    private static func profileRows(in section: [String: Any]) -> [[String: Any]] {
        var rows = [[String: Any]]()
        if let profile = section["profile"] as? [String: Any] {
            rows.append(profile)
        }
        if let profiles = section["profiles"] as? [Any] {
            rows.append(contentsOf: profiles.compactMap { $0 as? [String: Any] })
        }
        return rows
    }

    private static func rows(_ key: String, in section: [String: Any]) -> [[String: Any]] {
        guard let values = section[key] as? [Any] else { return [] }
        return values.compactMap { $0 as? [String: Any] }
    }

    private struct ImportedProfile {
        var name: String
        var waterGoalML: Int
        var allowanceAmount: Double
        var allowanceDay: Int
        var authMethodRaw: String
        var faceIDEnabled: Bool
        var waterRemindersEnabled: Bool
        var gratitudeReminderEnabled: Bool
        var postEventExpenseReminderEnabled: Bool
        var hasCompletedOnboarding: Bool
        var createdAt: Date
    }

    private static func makeProfile(from row: [String: Any]) -> ImportedProfile? {
        let name = string(row["name"]) ?? ""
        return ImportedProfile(
            name: name,
            waterGoalML: int(row["waterGoalML"]) ?? 2000,
            allowanceAmount: double(row["allowanceAmount"]) ?? 0,
            allowanceDay: int(row["allowanceDay"]) ?? 5,
            authMethodRaw: string(row["authMethodRaw"]) ?? AuthMethod.local.rawValue,
            faceIDEnabled: bool(row["faceIDEnabled"]) ?? false,
            waterRemindersEnabled: bool(row["waterRemindersEnabled"]) ?? true,
            gratitudeReminderEnabled: bool(row["gratitudeReminderEnabled"]) ?? true,
            postEventExpenseReminderEnabled: bool(row["postEventExpenseReminderEnabled"]) ?? true,
            hasCompletedOnboarding: bool(row["hasCompletedOnboarding"]) ?? !name.isEmpty,
            createdAt: date(row["createdAt"]) ?? .now
        )
    }

    private static func merge(imported: ImportedProfile, into destination: UserProfile) -> Bool {
        let wasPlaceholder = !destination.hasCompletedOnboarding || destination.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        var changed = false

        func assign<T: Equatable>(_ newValue: T, to oldValue: inout T, when condition: Bool = true) {
            guard condition, oldValue != newValue else { return }
            oldValue = newValue
            changed = true
        }

        assign(imported.name, to: &destination.name, when: wasPlaceholder && !imported.name.isEmpty)
        assign(imported.waterGoalML, to: &destination.waterGoalML, when: wasPlaceholder || destination.waterGoalML == 2000)
        assign(imported.allowanceAmount, to: &destination.allowanceAmount, when: wasPlaceholder || destination.allowanceAmount == 0)
        assign(imported.allowanceDay, to: &destination.allowanceDay, when: wasPlaceholder || destination.allowanceDay == 5)
        assign(imported.authMethodRaw, to: &destination.authMethodRaw, when: wasPlaceholder)
        assign(imported.faceIDEnabled, to: &destination.faceIDEnabled, when: wasPlaceholder)
        assign(imported.waterRemindersEnabled, to: &destination.waterRemindersEnabled, when: wasPlaceholder)
        assign(imported.gratitudeReminderEnabled, to: &destination.gratitudeReminderEnabled, when: wasPlaceholder)
        assign(imported.postEventExpenseReminderEnabled, to: &destination.postEventExpenseReminderEnabled, when: wasPlaceholder)
        assign(imported.hasCompletedOnboarding, to: &destination.hasCompletedOnboarding, when: imported.hasCompletedOnboarding)
        assign(imported.createdAt, to: &destination.createdAt, when: wasPlaceholder)
        return changed
    }

    private static func fetch<T: PersistentModel>(_ type: T.Type, from context: ModelContext) -> [T] {
        (try? context.fetch(FetchDescriptor<T>())) ?? []
    }

    private static func string(_ value: Any?) -> String? {
        guard let value, !(value is NSNull) else { return nil }
        if let value = value as? String { return value }
        if let value = value as? NSNumber { return value.stringValue }
        return nil
    }

    private static func double(_ value: Any?) -> Double? {
        guard let value, !(value is NSNull) else { return nil }
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private static func int(_ value: Any?) -> Int? {
        guard let value, !(value is NSNull) else { return nil }
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? String { return Int(value) }
        return nil
    }

    private static func bool(_ value: Any?) -> Bool? {
        guard let value, !(value is NSNull) else { return nil }
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        if let value = value as? String { return Bool(value) }
        return nil
    }

    private static func date(_ value: Any?) -> Date? {
        guard let value, !(value is NSNull) else { return nil }
        if let value = value as? Date { return value }
        if let value = value as? NSNumber { return Date(timeIntervalSince1970: value.doubleValue) }
        guard let value = value as? String else { return nil }
        return isoFormatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    private static func uuid(_ value: Any?) -> UUID? {
        guard let value = string(value) else { return nil }
        return UUID(uuidString: value)
    }

    private static func data(_ value: Any?) -> Data? {
        guard let value = string(value) else { return nil }
        return Data(base64Encoded: value)
    }

    private static func stringArray(_ value: Any?) -> [String] {
        guard let values = value as? [Any] else { return [] }
        return unique(values.compactMap { string($0) })
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private static func iso(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoFormatter.string(from: date)
    }

    private static func fingerprint(_ values: [String]) -> String {
        values.joined(separator: "\u{1F}")
    }

    private static func profileSignature(_ profile: ImportedProfile) -> String {
        fingerprint([
            profile.name,
            String(profile.waterGoalML),
            String(profile.allowanceAmount),
            String(profile.allowanceDay),
            String(profile.hasCompletedOnboarding)
        ])
    }

    private static func profileSignature(_ profile: UserProfile) -> String {
        fingerprint([
            profile.name,
            String(profile.waterGoalML),
            String(profile.allowanceAmount),
            String(profile.allowanceDay),
            String(profile.hasCompletedOnboarding)
        ])
    }

    private static func waterSignature(_ value: WaterEntry) -> String {
        fingerprint([iso(value.date), String(value.amountML)])
    }

    private static func bathroomSignature(_ value: BathroomEntry) -> String {
        fingerprint([iso(value.date)])
    }

    private static func expenseSignature(_ value: Expense) -> String {
        fingerprint([value.title, String(value.amount), value.categoryRaw, iso(value.date)])
    }

    private static func additionSignature(_ value: MoneyAddition) -> String {
        fingerprint([value.title, String(value.amount), iso(value.date)])
    }

    private static func eventSignature(_ value: CalendarEvent) -> String {
        value.id.uuidString
    }

    private static func eventContentSignature(_ value: CalendarEvent) -> String {
        fingerprint([
            value.title,
            value.location ?? "",
            iso(value.startDate),
            iso(value.endDate),
            value.categoryRaw,
            String(value.remindToLogExpense),
            String(value.loggedExpense)
        ])
    }

    private static func todoSignature(_ value: DailyTodo) -> String {
        fingerprint([value.title, iso(value.date), String(value.isCompleted), iso(value.createdAt)])
    }

    private static func gratitudeSignature(_ value: GratitudeEntry) -> String {
        fingerprint([value.text, iso(value.date)])
    }

    private static func bookSignature(_ value: Book) -> String {
        fingerprint([
            value.title, value.author, value.statusRaw, String(value.currentPage), String(value.totalPages),
            String(value.rating), value.review ?? "", value.coverColorHex, value.coverURLString ?? "", iso(value.dateAdded)
        ])
    }

    private static func movieSignature(_ value: MovieShow) -> String {
        fingerprint([
            value.title, value.kind, String(value.year ?? 0), value.imageURLString ?? "", value.sourceURLString ?? "",
            value.statusRaw, String(value.rating ?? 0), value.review ?? "", iso(value.dateAdded)
        ])
    }

    private static func wishlistSignature(_ value: WishlistItem) -> String {
        fingerprint([
            value.name, String(value.price), String(value.originalPrice ?? 0), value.sourceURLString ?? "", value.listName,
            String(value.notifyOnPriceDrop), iso(value.dateAdded), String(value.purchased)
        ])
    }

    private static func shoppingListSignature(_ value: ShoppingList) -> String {
        fingerprint([value.name, iso(value.dateCreated)])
    }

    private static func exerciseSignature(_ value: ExerciseEntry) -> String {
        fingerprint([value.type, String(value.durationMinutes), value.intensityRaw, iso(value.date)])
    }

    private static func maxDate(_ left: Date?, _ right: Date?) -> Date? {
        switch (left, right) {
        case let (left?, right?): max(left, right)
        case (nil, let right?): right
        case (let left?, nil): left
        case (nil, nil): nil
        }
    }
}
