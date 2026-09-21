import Foundation

/// Builds a plain-JSON snapshot of everything in Lume for "Exportar dados".
/// Photos are left out (flagged with a boolean) to keep the file small and
/// because they're not portable data anyone needs outside the app.
enum DataExportService {
    struct Snapshot: Codable {
        var exportedAt: Date
        var profile: ProfileDTO?
        var water: [WaterDTO]
        var bathroom: [BathroomDTO]
        var expenses: [ExpenseDTO]
        var moneyAdditions: [MoneyAdditionDTO]
        var events: [EventDTO]
        var todos: [TodoDTO]
        var gratitude: [GratitudeDTO]
        var books: [BookDTO]
        var movies: [MovieDTO]
        var wishlist: [WishlistDTO]
        var shoppingLists: [ShoppingListDTO]
        var exercise: [ExerciseDTO]
    }

    struct ProfileDTO: Codable {
        var name: String
        var waterGoalML: Int
        var allowanceAmount: Double
        var allowanceDay: Int
    }
    struct WaterDTO: Codable { var date: Date; var amountML: Int }
    struct BathroomDTO: Codable { var date: Date }
    struct ExpenseDTO: Codable { var date: Date; var title: String; var amount: Double; var category: String }
    struct MoneyAdditionDTO: Codable { var date: Date; var title: String; var amount: Double }
    struct EventDTO: Codable { var start: Date; var end: Date?; var title: String; var location: String?; var category: String }
    struct TodoDTO: Codable { var date: Date; var title: String; var completed: Bool }
    struct GratitudeDTO: Codable { var date: Date; var text: String; var hasPhoto: Bool }
    struct BookDTO: Codable { var title: String; var author: String; var status: String; var currentPage: Int; var totalPages: Int; var rating: Int; var review: String? }
    struct MovieDTO: Codable { var title: String; var kind: String; var year: Int?; var status: String; var rating: Int?; var review: String?; var dateAdded: Date }
    struct WishlistDTO: Codable { var name: String; var price: Double; var listName: String; var purchased: Bool; var dateAdded: Date }
    struct ShoppingListDTO: Codable { var name: String; var dateCreated: Date }
    struct ExerciseDTO: Codable { var date: Date; var type: String; var durationMinutes: Int; var intensity: String }

    static func build(
        profile: UserProfile?,
        water: [WaterEntry],
        bathroom: [BathroomEntry],
        expenses: [Expense],
        moneyAdditions: [MoneyAddition],
        events: [CalendarEvent],
        todos: [DailyTodo],
        gratitude: [GratitudeEntry],
        books: [Book],
        movies: [MovieShow],
        wishlist: [WishlistItem],
        shoppingLists: [ShoppingList],
        exercise: [ExerciseEntry]
    ) -> Snapshot {
        Snapshot(
            exportedAt: .now,
            profile: profile.map { ProfileDTO(name: $0.name, waterGoalML: $0.waterGoalML, allowanceAmount: $0.allowanceAmount, allowanceDay: $0.allowanceDay) },
            water: water.map { WaterDTO(date: $0.date, amountML: $0.amountML) },
            bathroom: bathroom.map { BathroomDTO(date: $0.date) },
            expenses: expenses.map { ExpenseDTO(date: $0.date, title: $0.title, amount: $0.amount, category: $0.category.rawValue) },
            moneyAdditions: moneyAdditions.map { MoneyAdditionDTO(date: $0.date, title: $0.title, amount: $0.amount) },
            events: events.map { EventDTO(start: $0.startDate, end: $0.endDate, title: $0.title, location: $0.location, category: $0.category.rawValue) },
            todos: todos.map { TodoDTO(date: $0.date, title: $0.title, completed: $0.isCompleted) },
            gratitude: gratitude.map { GratitudeDTO(date: $0.date, text: $0.text, hasPhoto: $0.photoData != nil) },
            books: books.map { BookDTO(title: $0.title, author: $0.author, status: $0.status.rawValue, currentPage: $0.currentPage, totalPages: $0.totalPages, rating: $0.rating, review: $0.review) },
            movies: movies.map { MovieDTO(title: $0.title, kind: $0.kind, year: $0.year, status: $0.status.rawValue, rating: $0.rating, review: $0.review, dateAdded: $0.dateAdded) },
            wishlist: wishlist.map { WishlistDTO(name: $0.name, price: $0.price, listName: $0.listName, purchased: $0.purchased, dateAdded: $0.dateAdded) },
            shoppingLists: shoppingLists.map { ShoppingListDTO(name: $0.name, dateCreated: $0.dateCreated) },
            exercise: exercise.map { ExerciseDTO(date: $0.date, type: $0.type, durationMinutes: $0.durationMinutes, intensity: $0.intensity.rawValue) }
        )
    }

    /// Writes the snapshot to a temp file and returns its URL, ready for `ShareLink`.
    static func writeTempFile(_ snapshot: Snapshot) -> URL? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "lume-dados-\(formatter.string(from: .now)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
