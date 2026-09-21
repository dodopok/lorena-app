import Foundation
import SwiftUI
import UIKit

struct WordOfDayPuzzle: Identifiable {
    let id: String
    let date: Date
    let letters: [String]
    let targetWords: [String]
    let bonusWords: Set<String>
    let hints: [String]

    @MainActor
    func accepts(_ word: String) -> Bool {
        let normalized = WordOfDayCatalog.normalize(word)
        guard normalized.count >= 3, usesAvailableLetters(normalized) else { return false }
        if targetWords.contains(normalized) || bonusWords.contains(normalized) { return true }

        // O dicionário do sistema deixa o jogo aceitar flexões e palavras comuns
        // sem depender de uma lista fechada para cada dia.
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: normalized.utf16.count)
        return checker.rangeOfMisspelledWord(
            in: normalized.lowercased(),
            range: range,
            startingAt: 0,
            wrap: false,
            language: "pt-BR"
        ).location == NSNotFound
    }

    private func usesAvailableLetters(_ word: String) -> Bool {
        let available = Dictionary(grouping: letters.map(WordOfDayCatalog.normalize)) { $0 }
            .mapValues(\.count)
        let requested = Dictionary(grouping: word.map(String.init)) { $0 }
            .mapValues(\.count)
        return requested.allSatisfy { letter, count in
            count <= (available[letter] ?? 0)
        }
    }
}

enum WordOfDayCatalog {
    private struct Template {
        let letters: [String]
        let targetWords: [String]
        let bonusWords: [String]
        let hints: [String]
    }

    private static let templates: [Template] = [
        Template(
            letters: ["C", "A", "M", "I", "N", "H", "O"],
            targetWords: ["CAMINHO", "MINHOCA", "MINHA", "MACHO", "CHINA"],
            bonusWords: ["CIMA", "MINA", "MANO", "HINO", "MICA", "CHAMO", "AMO", "MAO", "NAO", "CAO", "ACO", "CHAO", "COMA", "OCA"],
            hints: [
                "É algo que você percorre quando vai de um lugar a outro.",
                "A segunda palavra também é o nome de um animal.",
                "Uma delas fala de pertencimento e começa com M.",
                "Outra descreve alguém valente, sem medo.",
                "A última também pode ser um gentílico."
            ]
        ),
        Template(
            letters: ["C", "U", "I", "D", "A", "D", "O"],
            targetWords: ["CUIDADO", "CUIDA", "DICA", "DADO", "DOU"],
            bonusWords: ["DIA", "DUO", "AUDIO", "DADO"],
            hints: [
                "A palavra maior lembra atenção e carinho.",
                "Uma palavra curta ajuda quando você quer uma orientação.",
                "Outra pode ser algo lançado em um jogo.",
                "Procure também uma forma do verbo cuidar.",
                "A última é uma forma do verbo dar."
            ]
        ),
        Template(
            letters: ["C", "O", "R", "A", "G", "E", "M"],
            targetWords: ["CORAGEM", "CARGO", "MAGO", "GOMA", "MAR"],
            bonusWords: ["AMOR", "MORA", "ROCA", "GRAO"],
            hints: [
                "A palavra maior aparece quando alguém enfrenta um desafio.",
                "Uma delas pode ser uma função ou posição de trabalho.",
                "Outra lembra histórias de fantasia.",
                "Há também um doce mastigável entre as respostas.",
                "A última é pequena, mas aparece no litoral."
            ]
        )
    ]

    private static let anchorDate: Date = {
        LumeDateFormat.calendar.date(from: DateComponents(year: 2026, month: 9, day: 21)) ?? .now.startOfDay
    }()

    static func puzzle(for date: Date) -> WordOfDayPuzzle {
        let dayOffset = LumeDateFormat.calendar.dateComponents([.day], from: anchorDate, to: date.startOfDay).day ?? 0
        let index = ((dayOffset % templates.count) + templates.count) % templates.count
        let template = templates[index]

        return WordOfDayPuzzle(
            id: key(for: date),
            date: date.startOfDay,
            letters: template.letters,
            targetWords: template.targetWords.map(normalize),
            bonusWords: Set(template.bonusWords.map(normalize)),
            hints: template.hints
        )
    }

    static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: LumeDateFormat.ptBR)
            .filter { $0.isLetter }
            .uppercased()
    }

    static func key(for date: Date) -> String {
        let components = LumeDateFormat.calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

enum WordSubmissionResult {
    case empty
    case invalid
    case duplicate
    case found(String)
    case bonus(String)
}

private struct WordOfDayProgress: Codable {
    var foundWords: [String] = []
    var bonusWords: [String] = []
    var hintIndex: Int = 0
    var nextHintAt: Date?
}

@MainActor
final class WordOfDayStore: ObservableObject {
    @Published private(set) var puzzle: WordOfDayPuzzle
    @Published private(set) var foundWords: [String] = []
    @Published private(set) var bonusWordsFound: [String] = []
    @Published private(set) var hintIndex = 0
    @Published private(set) var nextHintAt: Date?

    private let defaults = UserDefaults.standard
    private let cooldown: TimeInterval = 12
    private var completedDates: Set<String> = []

    init(date: Date = .now) {
        puzzle = WordOfDayCatalog.puzzle(for: date)
        load()
    }

    var selectedDate: Date { puzzle.date }
    var bonusCount: Int { bonusWordsFound.count }
    var isComplete: Bool { foundWords.count == puzzle.targetWords.count }

    var streak: Int {
        var count = 0
        var date = selectedDate
        while completedDates.contains(WordOfDayCatalog.key(for: date)) {
            count += 1
            date = date.adding(days: -1)
        }
        return count
    }

    func select(date: Date) {
        puzzle = WordOfDayCatalog.puzzle(for: date)
        load()
    }

    func submit(_ rawWord: String) -> WordSubmissionResult {
        let word = WordOfDayCatalog.normalize(rawWord)
        guard !word.isEmpty else { return .empty }
        guard !foundWords.contains(word), !bonusWordsFound.contains(word) else { return .duplicate }
        guard puzzle.accepts(word) else { return .invalid }

        if puzzle.targetWords.contains(word) {
            foundWords.append(word)
            if isComplete {
                completedDates.insert(WordOfDayCatalog.key(for: selectedDate))
                saveCompletedDates()
            }
            save()
            return .found(word)
        }

        bonusWordsFound.append(word)
        save()
        return .bonus(word)
    }

    func useHint(at date: Date = .now) -> String? {
        guard cooldownRemaining(at: date) == 0 else { return nil }

        let message: String
        let remainingTargets = puzzle.targetWords.filter { !foundWords.contains($0) }
        if hintIndex < puzzle.hints.count, !remainingTargets.isEmpty {
            message = puzzle.hints[hintIndex]
        } else if let nextTarget = remainingTargets.first {
            message = "Ainda falta uma palavra de \(nextTarget.count) letras que começa com \(nextTarget.prefix(1))."
        } else {
            let available = puzzle.letters.joined(separator: " · ")
            message = "As palavras principais acabaram. Experimente uma combinação extra com: \(available)."
        }

        hintIndex += 1
        nextHintAt = date.addingTimeInterval(cooldown)
        save()
        return message
    }

    func cooldownRemaining(at date: Date = .now) -> Int {
        guard let nextHintAt else { return 0 }
        return max(0, Int(ceil(nextHintAt.timeIntervalSince(date))))
    }

    private var progressKey: String { "lume.word-of-day.progress.\(puzzle.id)" }
    private let completedDatesKey = "lume.word-of-day.completed-dates"

    private func load() {
        if let data = defaults.data(forKey: progressKey),
           let progress = try? JSONDecoder().decode(WordOfDayProgress.self, from: data) {
            foundWords = progress.foundWords
            bonusWordsFound = progress.bonusWords
            hintIndex = progress.hintIndex
            nextHintAt = progress.nextHintAt
        } else {
            foundWords = []
            bonusWordsFound = []
            hintIndex = 0
            nextHintAt = nil
        }

        if let data = defaults.data(forKey: completedDatesKey),
           let dates = try? JSONDecoder().decode([String].self, from: data) {
            completedDates = Set(dates)
        } else {
            completedDates = []
        }
    }

    private func save() {
        let progress = WordOfDayProgress(
            foundWords: foundWords,
            bonusWords: bonusWordsFound,
            hintIndex: hintIndex,
            nextHintAt: nextHintAt
        )
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }

    private func saveCompletedDates() {
        if let data = try? JSONEncoder().encode(Array(completedDates)) {
            defaults.set(data, forKey: completedDatesKey)
        }
    }
}

private struct BoardPlacement {
    let word: String
    let row: Int
    let column: Int
    let vertical: Bool
}

private struct BoardTile {
    let id: String
    let letter: String
    let words: Set<String>
}

struct WordOfDayTabView: View {
    @StateObject private var game = WordOfDayStore()
    @State private var selectedLetters: [String] = []
    @State private var shuffledLetters: [String] = []
    @State private var hintMessage: String?
    @State private var feedback: String?

    var body: some View {
        GeometryReader { proxy in
            let tileSize = min(24, max(19, (proxy.size.width - 70) / 7))
            let wheelSize = min(132, max(118, proxy.size.width * 0.37))

            VStack(spacing: 7) {
                gameHeader
                progress
                board(tileSize: tileSize)
                bonusAndHint

                if let message = hintMessage ?? feedback {
                    Text(message)
                        .font(LumeType.sans(11.5, weight: .semibold))
                        .foregroundStyle(LumeColor.textMuted)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                letterWheel(size: wheelSize)
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(LumeColor.canvas.ignoresSafeArea())
        .onAppear { reshuffle() }
        .onChange(of: game.puzzle.id) { _, _ in
            selectedLetters = []
            hintMessage = nil
            feedback = nil
            reshuffle()
        }
    }

    private var gameHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                LumeEyebrow(text: "Palavra de hoje")
                Text(LumeDateFormat.weekdayDay(game.selectedDate))
                    .font(LumeType.serif(24))
                    .foregroundStyle(LumeColor.ink)
            }

            Spacer(minLength: 4)

            HStack(spacing: 5) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(game.streak)")
                        .font(LumeType.sans(14, weight: .heavy))
                        .foregroundStyle(LumeColor.amberText)
                    Text(game.streak == 1 ? "dia" : "dias")
                        .font(LumeType.sans(9.5, weight: .semibold))
                        .foregroundStyle(LumeColor.amberLabel)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Capsule().fill(LumeColor.amberChipBgMid))

                Menu {
                    ForEach(0..<7, id: \.self) { offset in
                        let date = Date.now.adding(days: -offset)
                        Button {
                            game.select(date: date)
                        } label: {
                            Label(
                                "\(LumeDateFormat.shortWeekdayDayUppercased(date))",
                                systemImage: date.isSameDay(as: game.selectedDate) ? "checkmark" : "calendar"
                            )
                        }
                    }
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LumeColor.brand)
                        .frame(width: 31, height: 31)
                        .background(Circle().fill(.white.opacity(0.68)))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dias anteriores")
            }
        }
    }

    private var progress: some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(game.foundWords.count) / \(game.puzzle.targetWords.count)")
                Spacer()
                Text("\(game.puzzle.letters.count) letras")
            }
            .font(LumeType.mono(9.5))
            .foregroundStyle(LumeColor.textFaint)

            GeometryReader { geometry in
                Capsule()
                    .fill(LumeColor.brandPillLight)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LumeColor.brand)
                            .frame(width: geometry.size.width * completionProgress)
                    }
            }
            .frame(height: 5)
        }
    }

    private var completionProgress: CGFloat {
        guard !game.puzzle.targetWords.isEmpty else { return 0 }
        return min(1, CGFloat(game.foundWords.count) / CGFloat(game.puzzle.targetWords.count))
    }

    private func board(tileSize: CGFloat) -> some View {
        VStack(spacing: 3) {
            ForEach(Array(boardRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 3) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, tile in
                        if let tile {
                            let isSolved = tile.words.contains { game.foundWords.contains($0) }
                            Text(isSolved ? tile.letter : "")
                                .font(LumeType.serif(tileSize * 0.68))
                                .foregroundStyle(LumeColor.ink)
                                .frame(width: tileSize, height: tileSize)
                                .background(
                                    RoundedRectangle(cornerRadius: tileSize * 0.25, style: .continuous)
                                        .fill(isSolved ? LumeColor.roseSoft : LumeColor.paper.opacity(0.62))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: tileSize * 0.25, style: .continuous)
                                        .strokeBorder(LumeColor.brandPlumStart.opacity(0.16), lineWidth: 1)
                                )
                        } else {
                            Color.clear
                                .frame(width: tileSize, height: tileSize)
                        }
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.46))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.74), lineWidth: 1)
                )
        )
    }

    private var bonusAndHint: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = game.cooldownRemaining(at: context.date)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LumeColor.greenText)
                        .frame(width: 7, height: 7)
                    Text("bônus")
                        .font(LumeType.sans(11.5, weight: .semibold))
                        .foregroundStyle(LumeColor.textSecondary)
                    Text("\(game.bonusCount)")
                        .font(LumeType.sans(13, weight: .heavy))
                        .foregroundStyle(LumeColor.ink)
                }
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                .padding(.horizontal, 12)
                .background(Capsule().fill(.white.opacity(0.74)))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Bônus")
                .accessibilityValue("\(game.bonusCount)")

                Button {
                    hintMessage = game.useHint(at: context.date)
                    feedback = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(remaining > 0 ? "Dica · \(remaining)s" : "Dica")
                            .font(LumeType.sans(11.5, weight: .bold))
                        Spacer(minLength: 2)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(LumeColor.amberText)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(LumeColor.amberChipBgMid))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(remaining > 0)
                .opacity(remaining > 0 ? 0.62 : 1)
                .accessibilityLabel("Dica")
                .accessibilityValue(remaining > 0 ? "Disponível em \(remaining) segundos" : "Revelar uma pista")
            }
        }
    }

    private func letterWheel(size: CGFloat) -> some View {
        let radius = size * 0.32

        return ZStack {
            Circle()
                .fill(.white.opacity(0.52))
                .overlay(Circle().strokeBorder(.white.opacity(0.82), lineWidth: 1))

            ForEach(Array(shuffledLetters.enumerated()), id: \.offset) { index, letter in
                let angle = Double(index) / Double(max(shuffledLetters.count, 1)) * Double.pi * 2 - Double.pi / 2
                Button {
                    append(letter)
                } label: {
                    Text(letter)
                        .font(LumeType.serif(19))
                        .foregroundStyle(canAppend(letter) ? LumeColor.ink : LumeColor.textFainter)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(.white.opacity(canAppend(letter) ? 0.94 : 0.48)))
                        .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                        .shadow(color: LumeColor.ink.opacity(0.08), radius: 5, y: 3)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canAppend(letter))
                .offset(
                    x: CGFloat(cos(angle)) * radius,
                    y: CGFloat(sin(angle)) * radius
                )
                .accessibilityLabel(letter)
            }

            Button {
                if selectedLetters.isEmpty {
                    reshuffle()
                } else {
                    submit()
                }
            } label: {
                VStack(spacing: 1) {
                    Image(systemName: selectedLetters.isEmpty ? "shuffle" : "checkmark")
                        .font(.system(size: 13, weight: .bold))
                    if !selectedLetters.isEmpty {
                        Text(selectedLetters.joined())
                            .font(LumeType.sans(9.5, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: selectedLetters.isEmpty ? 42 : 64, height: 42)
                .background(Circle().fill(LumeColor.brand))
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selectedLetters.isEmpty ? "Embaralhar letras" : "Conferir palavra \(selectedLetters.joined())")
        }
        .frame(width: size, height: size)
    }

    private var boardRows: [[BoardTile?]] {
        let size = 7
        var grid = Array(repeating: Array<BoardTile?>(repeating: nil, count: size), count: size)

        for placement in placements {
            for (offset, character) in placement.word.enumerated() {
                let row = placement.row + (placement.vertical ? offset : 0)
                let column = placement.column + (placement.vertical ? 0 : offset)
                guard (0..<size).contains(row), (0..<size).contains(column) else { continue }

                let id = "\(row)-\(column)"
                let letter = String(character)
                if let existing = grid[row][column] {
                    grid[row][column] = BoardTile(id: id, letter: existing.letter, words: existing.words.union([placement.word]))
                } else {
                    grid[row][column] = BoardTile(id: id, letter: letter, words: [placement.word])
                }
            }
        }

        return grid
    }

    private var placements: [BoardPlacement] {
        if game.puzzle.targetWords == ["CAMINHO", "MINHOCA", "MINHA", "MACHO", "CHINA"] {
            return [
                BoardPlacement(word: "CAMINHO", row: 3, column: 0, vertical: false),
                BoardPlacement(word: "MINHOCA", row: 0, column: 5, vertical: true),
                BoardPlacement(word: "MINHA", row: 2, column: 3, vertical: true),
                BoardPlacement(word: "MACHO", row: 2, column: 1, vertical: true),
                BoardPlacement(word: "CHINA", row: 0, column: 4, vertical: true)
            ]
        }

        return game.puzzle.targetWords.enumerated().map { index, word in
            BoardPlacement(
                word: word,
                row: min(6, index + 1),
                column: max(0, (7 - word.count) / 2),
                vertical: false
            )
        }
    }

    private func canAppend(_ letter: String) -> Bool {
        let available = game.puzzle.letters.filter { $0 == letter }.count
        let selected = selectedLetters.filter { $0 == letter }.count
        return selected < available
    }

    private func append(_ letter: String) {
        guard canAppend(letter) else { return }
        selectedLetters.append(letter)
        feedback = nil
    }

    private func submit() {
        let result = game.submit(selectedLetters.joined())
        switch result {
        case .empty:
            feedback = "Monte uma palavra antes de conferir."
        case .invalid:
            feedback = "Essa combinação não parece uma palavra."
        case .duplicate:
            feedback = "Você já encontrou essa palavra."
        case .found(let word):
            feedback = "Boa! \(word.capitalized) entrou na grade."
        case .bonus(let word):
            feedback = "Bônus: \(word.capitalized)."
        }
        selectedLetters = []
    }

    private func reshuffle() {
        shuffledLetters = game.puzzle.letters.shuffled()
    }
}
