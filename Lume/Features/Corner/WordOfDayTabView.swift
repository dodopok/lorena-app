import SwiftUI
import SwiftData

/// A sub-aba Palavras do Cantinho: o estado do puzzle de hoje e a tira dos
/// dias anteriores. O jogo em si abre em tela cheia, onde a roda tem espaço.
struct WordOfDayTabView: View {
    @Query private var allProgress: [WordDayProgress]
    @State private var playing: PlayRequest?

    private struct PlayRequest: Identifiable {
        let id: Int
    }

    private var today: Int { WordDay.todayIndex }
    private var completedDays: Set<Int> {
        Set(allProgress.filter { $0.completedAt != nil }.map(\.dayIndex))
    }
    private var streak: Int { WordDay.streak(completedDays: completedDays) }

    private func progress(for day: Int) -> WordDayProgress? {
        allProgress.first { $0.dayIndex == day }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                todayCard
                archive
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .fullScreenCover(item: $playing) { request in
            WordGameView(dayIndex: request.id)
        }
    }

    private var todayCard: some View {
        let puzzle = WordDay.puzzle(for: today)
        let state = progress(for: today)
        let found = state?.foundWords.count ?? 0
        let total = puzzle.entries.count
        let isComplete = state?.completedAt != nil

        return Button {
            playing = PlayRequest(id: today)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    LumeEyebrow(text: "Hoje")
                    Spacer()
                    if streak > 0 {
                        HStack(spacing: 6) {
                            Circle().fill(LumeColor.amberAccent).frame(width: 7, height: 7)
                            Text("\(streak) dia\(streak == 1 ? "" : "s") seguidos")
                                .font(LumeType.sans(12, weight: .heavy))
                                .foregroundStyle(LumeColor.amberText)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(LumeColor.amberChipBgMid))
                    }
                }

                Text(isComplete ? "Puzzle de hoje completo." : "Um puzzle novo esperando por você.")
                    .font(LumeType.serif(23))
                    .foregroundStyle(LumeColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                // Prévia da grade do dia, ainda fechada — dá para sentir o
                // tamanho do desafio sem entregar nada.
                MiniGrid(puzzle: puzzle, openCells: openCells(for: today))

                HStack(spacing: 10) {
                    Text(isComplete ? "Rever" : (found > 0 ? "Continuar" : "Jogar"))
                        .font(LumeType.sans(15, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LumeColor.brand))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(found) de \(total)")
                            .font(LumeType.serif(19))
                            .foregroundStyle(LumeColor.ink)
                        Text("palavras")
                            .font(LumeType.sans(11.5))
                            .foregroundStyle(LumeColor.textFaint)
                    }
                    .frame(width: 78)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .lumeSoftGlass(cornerRadius: 28)
        .lumeRiseIn()
    }

    private var archive: some View {
        VStack(alignment: .leading, spacing: 10) {
            LumeEyebrow(text: "Dias anteriores")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach((0...6).reversed(), id: \.self) { offset in
                        let day = today - offset
                        dayChip(day)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func dayChip(_ day: Int) -> some View {
        let date = WordDay.date(for: day)
        let isToday = day == today
        let isComplete = completedDays.contains(day)
        let started = (progress(for: day)?.foundWords.isEmpty == false)

        return Button {
            playing = PlayRequest(id: day)
        } label: {
            VStack(spacing: 3) {
                Text(LumeDateFormat.weekdayInitial(date))
                    .font(LumeType.mono(9.5))
                    .foregroundStyle(isToday ? Color(hex: "F3CBD9") : LumeColor.textFaint)
                Text("\(LumeDateFormat.calendar.component(.day, from: date))")
                    .font(LumeType.serif(19))
                    .foregroundStyle(isToday ? .white : LumeColor.ink)
                Circle()
                    .fill(statusColor(isToday: isToday, isComplete: isComplete, started: started))
                    .frame(width: 7, height: 7)
                    .padding(.top, 2)
            }
            .frame(width: 58)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isToday ? LumeColor.brand : .white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(isToday ? 0 : 0.95), lineWidth: 1)
                )
                .shadow(color: isToday ? LumeColor.brand.opacity(0.28) : .clear, radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel(LumeDateFormat.dayMonthAbbrev(date))
        .accessibilityValue(isComplete ? "completo" : (started ? "começado" : "não jogado"))
    }

    private func statusColor(isToday: Bool, isComplete: Bool, started: Bool) -> Color {
        if isComplete { return isToday ? .white : LumeColor.greenDeep }
        if started { return isToday ? Color(hex: "F3CBD9") : LumeColor.amberAccent }
        return isToday ? .white.opacity(0.45) : LumeColor.brandPlumStart.opacity(0.16)
    }

    private func openCells(for day: Int) -> Set<WordPuzzle.Cell> {
        guard let state = progress(for: day) else { return [] }
        let puzzle = WordDay.puzzle(for: day)
        var cells: Set<WordPuzzle.Cell> = []
        for word in state.foundWords {
            cells.formUnion(puzzle.cells(for: word))
        }
        return cells
    }
}

/// Miniatura da grade usada no card — só as formas, para dar a medida do dia.
private struct MiniGrid: View {
    let puzzle: WordPuzzle
    let openCells: Set<WordPuzzle.Cell>

    var body: some View {
        let letters = puzzle.letterByCell
        let side: CGFloat = 13
        let spacing: CGFloat = 3

        VStack(spacing: spacing) {
            ForEach(0..<puzzle.height, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<puzzle.width, id: \.self) { column in
                        let cell = WordPuzzle.Cell(row: row, column: column)
                        if letters[cell] != nil {
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .fill(openCells.contains(cell) ? LumeColor.brand.opacity(0.85) : LumeColor.brandPlumStart.opacity(0.13))
                                .frame(width: side, height: side)
                        } else {
                            Color.clear.frame(width: side, height: side)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }
}
