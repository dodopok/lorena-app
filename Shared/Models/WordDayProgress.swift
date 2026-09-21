import Foundation
import SwiftData

/// O progresso de um dia do Palavra do dia. Uma linha por dia jogado — a
/// sequência sai da contagem dessas linhas, então não há estado global para
/// sair de sincronia.
///
/// As dicas não acabam: o que limita é uma espera entre uma e outra, guardada
/// em `lastHintAt` para que sair da tela não zere o relógio.
@Model
final class WordDayProgress {
    var dayIndex: Int = 0
    var foundWords: [String] = []
    var bonusWords: [String] = []
    var hintsUsed: Int = 0
    var lastHintAt: Date?
    var revealedByHint: [String] = []
    var completedAt: Date?

    init(dayIndex: Int) {
        self.dayIndex = dayIndex
    }

    /// Espera entre duas dicas.
    static let hintCooldown: TimeInterval = 60

    var isComplete: Bool { completedAt != nil }
}
