import Foundation

/// Um puzzle do Palavra do dia: a roda de letras e as palavras já posicionadas
/// na grade. As coordenadas vêm prontas de `tools/wordpuzzles.py`, que valida
/// cada cruzamento — nada é calculado (nem chutado) em tempo de execução.
struct WordPuzzle: Identifiable, Hashable {
    struct Cell: Hashable {
        let row: Int
        let column: Int
    }

    struct Entry: Hashable {
        let word: String
        let row: Int
        let column: Int
        let isVertical: Bool

        var letters: [String] { word.map(String.init) }

        var cells: [Cell] {
            (0..<word.count).map { index in
                Cell(
                    row: row + (isVertical ? index : 0),
                    column: column + (isVertical ? 0 : index)
                )
            }
        }
    }

    let id: String
    let letters: [String]
    let width: Int
    let height: Int
    let entries: [Entry]
    let bonus: [String]

    var words: [String] { entries.map(\.word) }

    /// A letra de cada célula ocupada. Calculado uma vez por tela, não por frame.
    var letterByCell: [Cell: String] {
        var map: [Cell: String] = [:]
        for entry in entries {
            for (index, cell) in entry.cells.enumerated() {
                map[cell] = entry.letters[index]
            }
        }
        return map
    }

    func entry(for word: String) -> Entry? { entries.first { $0.word == word } }
    func cells(for word: String) -> [Cell] { entry(for: word)?.cells ?? [] }
    func containsWord(_ word: String) -> Bool { entries.contains { $0.word == word } }
    func isBonus(_ word: String) -> Bool { bonus.contains(word) }
}

/// Mapeia datas para puzzles: um por dia, sempre o mesmo para a mesma data.
enum WordDay {
    private static let epoch: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        return LumeDateFormat.calendar.date(from: components) ?? Date(timeIntervalSince1970: 1_767_225_600)
    }()

    static func index(for date: Date = .now) -> Int {
        LumeDateFormat.calendar.dateComponents([.day], from: epoch, to: date.startOfDay).day ?? 0
    }

    static func date(for index: Int) -> Date {
        LumeDateFormat.calendar.date(byAdding: .day, value: index, to: epoch) ?? epoch
    }

    static var todayIndex: Int { index() }

    static func puzzle(for index: Int) -> WordPuzzle {
        let all = WordPuzzleCatalog.puzzles
        let wrapped = ((index % all.count) + all.count) % all.count
        return all[wrapped]
    }

    /// Dias seguidos até hoje (ou até ontem, se hoje ainda não foi jogado).
    static func streak(completedDays: Set<Int>, today: Int = WordDay.todayIndex) -> Int {
        var count = 0
        var day = completedDays.contains(today) ? today : today - 1
        while completedDays.contains(day) {
            count += 1
            day -= 1
        }
        return count
    }
}
