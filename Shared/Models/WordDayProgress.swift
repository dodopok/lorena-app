import Foundation
import SwiftData

/// O progresso de um dia do Palavra do dia. Uma linha por dia jogado — a
/// sequência sai da contagem dessas linhas, então não há estado global para
/// sair de sincronia.
///
/// As dicas são por dia: cada dia começa com duas e cada palavra bônus
/// encontrada naquele dia rende mais uma.
@Model
final class WordDayProgress {
    var dayIndex: Int = 0
    var foundWords: [String] = []
    var bonusWords: [String] = []
    var hintsUsed: Int = 0
    var revealedByHint: [String] = []
    var completedAt: Date?

    init(dayIndex: Int) {
        self.dayIndex = dayIndex
    }

    static let hintsPerDay = 2

    var hintsAvailable: Int {
        max(0, Self.hintsPerDay + bonusWords.count - hintsUsed)
    }

    var isComplete: Bool { completedAt != nil }
}
