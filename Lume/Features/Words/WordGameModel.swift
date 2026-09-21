import Foundation
import SwiftData
import SwiftUI

/// Uma peça da roda. O `id` é fixo para que embaralhar anime cada peça até a
/// nova posição em vez de trocar o texto no lugar.
struct WheelLetter: Identifiable, Equatable, Hashable {
    let id: Int
    let letter: String
}

/// Regras do Palavra do dia. Guarda o estado em memória e escreve no
/// `WordDayProgress` do dia — a view só cuida de animar o resultado.
@Observable
@MainActor
final class WordGameModel {
    enum Outcome: Equatable {
        case idle
        case tooShort
        case found(String)
        case bonus(String)
        case repeated(String)
        case unknown(String)
    }

    let dayIndex: Int
    let puzzle: WordPuzzle

    private let progress: WordDayProgress
    private let context: ModelContext

    private(set) var found: Set<String>
    private(set) var bonusFound: Set<String>
    private(set) var openCells: Set<WordPuzzle.Cell>
    private(set) var hintCells: Set<WordPuzzle.Cell>
    private(set) var hintsUsed: Int
    private(set) var lastHintAt: Date?
    private(set) var outcome: Outcome = .idle

    /// Peças da roda na ordem em que aparecem no círculo.
    var wheel: [WheelLetter]
    /// Ids das peças selecionadas, na ordem do traço.
    var selection: [Int] = []

    init(dayIndex: Int, progress: WordDayProgress, context: ModelContext) {
        self.dayIndex = dayIndex
        self.puzzle = WordDay.puzzle(for: dayIndex)
        self.progress = progress
        self.context = context
        self.found = Set(progress.foundWords)
        self.bonusFound = Set(progress.bonusWords)
        self.hintsUsed = progress.hintsUsed
        self.lastHintAt = progress.lastHintAt
        self.wheel = puzzle.letters.enumerated()
            .map { WheelLetter(id: $0.offset, letter: $0.element) }
            .shuffled()

        let hinted = Set(progress.revealedByHint.compactMap(Self.cell(fromKey:)))
        self.hintCells = hinted
        var open = hinted
        for word in progress.foundWords {
            open.formUnion(puzzle.cells(for: word))
        }
        self.openCells = open
    }

    // MARK: - Estado derivado

    var selectedWord: String {
        selection.compactMap { id in wheel.first { $0.id == id }?.letter }.joined()
    }
    var totalWords: Int { puzzle.entries.count }
    var foundCount: Int { found.count }
    var isComplete: Bool { found.count == puzzle.entries.count }

    /// Quanto falta para a próxima dica liberar. As dicas não acabam — só
    /// esperam.
    func hintCooldownRemaining(at date: Date = .now) -> TimeInterval {
        guard let lastHintAt else { return 0 }
        return max(0, WordDayProgress.hintCooldown - date.timeIntervalSince(lastHintAt))
    }

    /// Ainda há letra escondida em alguma palavra que falta?
    var hasHiddenLetters: Bool {
        puzzle.entries.contains { entry in
            !found.contains(entry.word) && entry.cells.contains { !openCells.contains($0) }
        }
    }

    func canUseHint(at date: Date = .now) -> Bool {
        !isComplete && hasHiddenLetters && hintCooldownRemaining(at: date) <= 0
    }

    /// Células de uma palavra que ainda não estão abertas — o que vai voar
    /// da roda para a grade.
    func unopenedCells(for word: String) -> [WordPuzzle.Cell] {
        puzzle.cells(for: word).filter { !openCells.contains($0) }
    }

    /// Id de uma peça da roda que mostra essa letra, para a animação partir do
    /// lugar certo. Prefere uma peça ainda não usada nesta palavra, para que
    /// letras repetidas saiam de peças diferentes.
    func tileID(for letter: String, excluding used: Set<Int>) -> Int? {
        if let fresh = wheel.first(where: { $0.letter == letter && !used.contains($0.id) }) {
            return fresh.id
        }
        return wheel.first(where: { $0.letter == letter })?.id
    }

    // MARK: - Jogadas

    /// Avalia a seleção atual e limpa a roda. A view anima conforme o resultado.
    @discardableResult
    func submit() -> Outcome {
        let word = selectedWord
        selection = []

        guard word.count >= 3 else {
            outcome = .tooShort
            return outcome
        }

        if puzzle.containsWord(word) {
            if found.contains(word) {
                outcome = .repeated(word)
            } else {
                found.insert(word)
                if isComplete, progress.completedAt == nil {
                    progress.completedAt = .now
                }
                persist()
                outcome = .found(word)
            }
        } else if puzzle.isBonus(word) {
            if bonusFound.contains(word) {
                outcome = .repeated(word)
            } else {
                bonusFound.insert(word)
                persist()
                outcome = .bonus(word)
            }
        } else {
            outcome = .unknown(word)
        }
        return outcome
    }

    func clearOutcome() {
        outcome = .idle
    }

    func open(_ cell: WordPuzzle.Cell) {
        openCells.insert(cell)
    }

    /// Abre uma letra de alguma palavra que falta. Devolve a célula para a view
    /// destacá-la.
    @discardableResult
    func useHint() -> WordPuzzle.Cell? {
        guard canUseHint() else { return nil }
        for entry in puzzle.entries where !found.contains(entry.word) {
            guard let cell = entry.cells.first(where: { !openCells.contains($0) }) else { continue }
            hintsUsed += 1
            lastHintAt = .now
            hintCells.insert(cell)
            openCells.insert(cell)
            persist()
            return cell
        }
        return nil
    }

    func shuffleWheel() {
        selection = []
        var shuffled = wheel
        // Uma roda que sai na mesma ordem não parece ter embaralhado.
        if wheel.count > 1 {
            repeat { shuffled.shuffle() } while shuffled == wheel
        }
        wheel = shuffled
    }

    // MARK: - Seleção pela roda

    func beginSelection() {
        selection = []
        outcome = .idle
    }

    /// Chamado enquanto o dedo passa pelas letras. Voltar uma casa desfaz.
    func extendSelection(to id: Int) {
        guard wheel.contains(where: { $0.id == id }) else { return }
        if let position = selection.firstIndex(of: id) {
            if position == selection.count - 2 {
                selection.removeLast()
            }
            return
        }
        selection.append(id)
    }

    // MARK: - Persistência

    private func persist() {
        progress.foundWords = Array(found)
        progress.bonusWords = Array(bonusFound)
        progress.hintsUsed = hintsUsed
        progress.lastHintAt = lastHintAt
        progress.revealedByHint = hintCells.map(Self.key(for:))
        if isComplete, progress.completedAt == nil {
            progress.completedAt = .now
        }
        try? context.save()
    }

    private static func key(for cell: WordPuzzle.Cell) -> String { "\(cell.row):\(cell.column)" }

    private static func cell(fromKey key: String) -> WordPuzzle.Cell? {
        let parts = key.split(separator: ":")
        guard parts.count == 2, let row = Int(parts[0]), let column = Int(parts[1]) else { return nil }
        return WordPuzzle.Cell(row: row, column: column)
    }
}
