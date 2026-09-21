import SwiftUI
import SwiftData

/// O jogo em tela cheia: cabeçalho, grade, trilho de bônus/dica, bolha da
/// palavra e a roda de letras — tudo em uma tela só, sem rolagem.
@MainActor
struct WordGameView: View {
    let dayIndex: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var allProgress: [WordDayProgress]

    @State private var model: WordGameModel?
    @State private var flights: [LetterFlight] = []
    @State private var bumpCells: Set<WordPuzzle.Cell> = []
    @State private var showDone = false
    @State private var celebrate = false
    @State private var confettiStart: Date?
    @State private var wheelShake = false
    @State private var feedbackTick = 0
    @State private var errorTick = 0

    private var isToday: Bool { dayIndex == WordDay.todayIndex }

    private var streak: Int {
        let completed = Set(allProgress.filter { $0.completedAt != nil }.map(\.dayIndex))
        return WordDay.streak(completedDays: completed)
    }

    var body: some View {
        GeometryReader { geo in
            let wheelDiameter = min(268, geo.size.width * 0.72, geo.size.height * 0.31)

            ZStack {
                LumeColor.canvas.ignoresSafeArea()
                LumeOrbBackground(orbs: orbs)

                VStack(spacing: 10) {
                    topBar
                    progressRow

                    if let model {
                        WordGridView(
                            puzzle: model.puzzle,
                            openCells: model.openCells,
                            hintCells: model.hintCells,
                            bumpCells: bumpCells,
                            celebrate: celebrate
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        railRow(model)
                        bubble(model)

                        LetterWheelView(
                            wheel: model.wheel,
                            selection: model.selection,
                            diameter: wheelDiameter,
                            onBegin: { model.beginSelection() },
                            onTouch: { model.extendSelection(to: $0) },
                            onCommit: commit
                        )
                        .offset(x: wheelShake ? -7 : 0)

                        shuffleButton(model)
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 10)
                .overlayPreferenceValue(WordAnchorKey.self) { anchors in
                    GeometryReader { proxy in
                        ForEach(flights) { flight in
                            if let from = anchors["tile-\(flight.tileID)"],
                               let to = anchors["cell-\(flight.cell.row)-\(flight.cell.column)"] {
                                FlyingLetterView(
                                    letter: flight.letter,
                                    from: proxy[from],
                                    to: proxy[to],
                                    delay: flight.delay,
                                    size: 40
                                )
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }

                if let confettiStart {
                    ConfettiView(start: confettiStart).ignoresSafeArea()
                }

                if showDone, let model {
                    donePanel(model)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sensoryFeedback(.success, trigger: feedbackTick)
        .sensoryFeedback(.warning, trigger: errorTick)
        .task { prepare() }
    }

    private let orbs: [OrbSpec] = [
        OrbSpec(color: LumeColor.roseOrb, size: 300, opacity: 0.5, blur: 58, alignment: .topLeading, offset: CGSize(width: -80, height: -60), duration: 17),
        OrbSpec(color: LumeColor.lavenderOrb, size: 260, opacity: 0.42, blur: 56, alignment: .bottomTrailing, offset: CGSize(width: -60, height: -40), duration: 22, reversed: true),
    ]

    // MARK: - Pedaços da tela

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                LumeEyebrow(text: isToday ? "Palavra de hoje" : "Palavra do dia")
                Text(LumeDateFormat.weekdayDay(WordDay.date(for: dayIndex)))
                    .font(LumeType.serif(26))
                    .foregroundStyle(LumeColor.ink)
            }

            Spacer()

            if streak > 0 {
                HStack(spacing: 6) {
                    Circle().fill(LumeColor.amberAccent).frame(width: 7, height: 7)
                    Text("\(streak) dia\(streak == 1 ? "" : "s")")
                        .font(LumeType.sans(12.5, weight: .heavy))
                        .foregroundStyle(LumeColor.amberText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(LumeColor.amberChipBgMid))
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LumeColor.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Fechar")
        }
    }

    private var progressRow: some View {
        HStack(spacing: 8) {
            GeometryReader { geo in
                Capsule().fill(LumeColor.brandPlumStart.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(LumeColor.brand)
                            .frame(width: geo.size.width * progressFraction)
                    }
            }
            .frame(height: 6)

            if let model {
                Text("\(model.foundCount) / \(model.totalWords) · \(model.puzzle.letters.count) letras")
                    .font(LumeType.mono(10.5))
                    .foregroundStyle(LumeColor.textFaint)
            }
        }
    }

    private var progressFraction: Double {
        guard let model, model.totalWords > 0 else { return 0 }
        return Double(model.foundCount) / Double(model.totalWords)
    }

    private func railRow(_ model: WordGameModel) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 9) {
                Circle().fill(LumeColor.greenDeep).frame(width: 9, height: 9)
                Text("bônus")
                    .font(LumeType.sans(12.5, weight: .semibold))
                    .foregroundStyle(LumeColor.textSecondary)
                Text("\(model.bonusFound.count)")
                    .font(LumeType.serif(17))
                    .foregroundStyle(LumeColor.ink)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .lumeSoftGlass(cornerRadius: 16, opacity: 0.62, shadow: false)

            Button {
                useHint(model)
            } label: {
                HStack(spacing: 9) {
                    Circle().fill(LumeColor.amberAccent).frame(width: 9, height: 9)
                    Text("dica")
                        .font(LumeType.sans(12.5, weight: .semibold))
                        .foregroundStyle(LumeColor.textSecondary)
                    Text("\(model.hintsAvailable)")
                        .font(LumeType.serif(17))
                        .foregroundStyle(LumeColor.ink)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .lumeSoftGlass(cornerRadius: 16, opacity: 0.62, shadow: false)
            .opacity(model.canUseHint ? 1 : 0.45)
            .disabled(!model.canUseHint)
        }
    }

    private func bubble(_ model: WordGameModel) -> some View {
        let word = bubbleWord(model)
        return Text(word)
            .font(LumeType.serif(25))
            .tracking(4)
            .foregroundStyle(bubbleForeground(model))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(bubbleBackground(model))
            )
            .opacity(word.isEmpty ? 0 : 1)
            .frame(height: 44)
            .animation(.easeOut(duration: 0.18), value: word)
            .animation(.easeOut(duration: 0.18), value: model.outcome)
    }

    private func bubbleWord(_ model: WordGameModel) -> String {
        switch model.outcome {
        case .found(let word), .bonus(let word), .repeated(let word), .unknown(let word):
            return word
        case .idle, .tooShort:
            return model.selectedWord
        }
    }

    private func bubbleBackground(_ model: WordGameModel) -> Color {
        switch model.outcome {
        case .found: LumeColor.brand
        case .bonus: LumeColor.greenDeep
        case .repeated: LumeColor.amberChipBgMid
        case .unknown: Color(hex: "F3DAD9")
        case .idle, .tooShort: Color.white.opacity(0.8)
        }
    }

    private func bubbleForeground(_ model: WordGameModel) -> Color {
        switch model.outcome {
        case .found, .bonus: .white
        case .repeated: LumeColor.amberText
        case .unknown: Color(hex: "9E3C3A")
        case .idle, .tooShort: LumeColor.ink
        }
    }

    private func shuffleButton(_ model: WordGameModel) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.78)) {
                model.shuffleWheel()
            }
        } label: {
            Image(systemName: "shuffle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LumeColor.brand)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .accessibilityLabel("Embaralhar letras")
    }

    private func donePanel(_ model: WordGameModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LumeEyebrow(text: isToday ? "Puzzle de hoje" : "Dia completo", color: LumeColor.brandOnPlumLabel)

            Text(isToday ? "Todas as palavras!" : "Dia completo!")
                .font(LumeType.serif(27))
                .foregroundStyle(.white)
                .padding(.top, 8)

            Text(doneMessage(model))
                .font(LumeType.sans(13.5))
                .foregroundStyle(LumeColor.brandOnPlumSecondary)
                .padding(.top, 7)

            HStack(spacing: 9) {
                Button("Ver a grade") {
                    withAnimation(.easeOut(duration: 0.3)) { showDone = false }
                }
                .font(LumeType.sans(14.5, weight: .heavy))
                .foregroundStyle(LumeColor.brandPlumStart)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color(hex: "FDF4F6")))
                .buttonStyle(.plain)

                Button("Fechar") { dismiss() }
                    .font(LumeType.sans(14.5, weight: .heavy))
                    .foregroundStyle(Color(hex: "FDF4F6"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(Color.white.opacity(0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .buttonStyle(.plain)
            }
            .padding(.top, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumePlumCard(cornerRadius: 28)
    }

    private func doneMessage(_ model: WordGameModel) -> String {
        guard isToday else { return "Esse dia ficou completo. Pode voltar para o de hoje." }
        let days = max(streak, 1)
        let bonus = model.bonusFound.count
        let bonusPart = bonus > 0 ? " E \(bonus) palavra\(bonus == 1 ? "" : "s") bônus." : ""
        return "Volte amanhã para a próxima. Sua sequência é de \(days) dia\(days == 1 ? "" : "s").\(bonusPart)"
    }

    // MARK: - Jogo

    private func prepare() {
        guard model == nil else { return }
        let progress: WordDayProgress
        if let existing = allProgress.first(where: { $0.dayIndex == dayIndex }) {
            progress = existing
        } else {
            let fresh = WordDayProgress(dayIndex: dayIndex)
            modelContext.insert(fresh)
            try? modelContext.save()
            progress = fresh
        }
        let game = WordGameModel(dayIndex: dayIndex, progress: progress, context: modelContext)
        model = game
        if game.isComplete {
            celebrate = true
        }
    }

    private func commit() {
        guard let model else { return }
        switch model.submit() {
        case .found(let word):
            feedbackTick += 1
            reveal(word, in: model)
            scheduleOutcomeClear(model)
        case .bonus:
            feedbackTick += 1
            scheduleOutcomeClear(model)
        case .repeated(let word):
            bump(model.puzzle.cells(for: word))
            scheduleOutcomeClear(model)
        case .unknown:
            errorTick += 1
            shakeWheel()
            scheduleOutcomeClear(model)
        case .tooShort, .idle:
            model.clearOutcome()
        }
    }

    private func reveal(_ word: String, in model: WordGameModel) {
        let fresh = Set(model.unopenedCells(for: word))
        let entry = model.puzzle.entry(for: word)
        let cells = entry?.cells ?? []
        let letters = entry?.letters ?? []

        bump(cells.filter { !fresh.contains($0) })

        guard !reduceMotion else {
            for cell in fresh { model.open(cell) }
            finishIfComplete(model)
            return
        }

        var used: Set<Int> = []
        var newFlights: [LetterFlight] = []
        for (index, cell) in cells.enumerated() where fresh.contains(cell) {
            let letter = letters.indices.contains(index) ? letters[index] : ""
            guard let tileID = model.tileID(for: letter, excluding: used) else { continue }
            used.insert(tileID)
            newFlights.append(
                LetterFlight(letter: letter, tileID: tileID, cell: cell, delay: Double(newFlights.count) * 0.06)
            )
        }

        flights = newFlights

        for flight in newFlights {
            Task {
                try? await Task.sleep(for: .seconds(flight.delay + 0.42))
                withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                    model.open(flight.cell)
                }
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(Double(newFlights.count) * 0.06 + 0.75))
            flights = []
            finishIfComplete(model)
        }
    }

    private func finishIfComplete(_ model: WordGameModel) {
        guard model.isComplete, !showDone else { return }
        withAnimation(.easeInOut(duration: 0.5)) { celebrate = true }
        if !reduceMotion { confettiStart = .now }
        Task {
            try? await Task.sleep(for: .seconds(0.55))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { showDone = true }
        }
    }

    private func useHint(_ model: WordGameModel) {
        guard let cell = model.useHint() else { return }
        feedbackTick += 1
        withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) { model.open(cell) }
        bump([cell])
        finishIfComplete(model)
    }

    private func bump(_ cells: [WordPuzzle.Cell]) {
        guard !cells.isEmpty, !reduceMotion else { return }
        bumpCells = Set(cells)
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            bumpCells = []
        }
    }

    private func shakeWheel() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.12, dampingFraction: 0.3)) { wheelShake = true }
        Task {
            try? await Task.sleep(for: .seconds(0.16))
            withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { wheelShake = false }
        }
    }

    private func scheduleOutcomeClear(_ model: WordGameModel) {
        Task {
            try? await Task.sleep(for: .seconds(0.65))
            model.clearOutcome()
        }
    }
}

// MARK: - Grade

private struct WordGridView: View {
    let puzzle: WordPuzzle
    let openCells: Set<WordPuzzle.Cell>
    let hintCells: Set<WordPuzzle.Cell>
    let bumpCells: Set<WordPuzzle.Cell>
    let celebrate: Bool

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let fitWidth = (geo.size.width - spacing * CGFloat(puzzle.width - 1)) / CGFloat(puzzle.width)
            let fitHeight = (geo.size.height - spacing * CGFloat(puzzle.height - 1)) / CGFloat(puzzle.height)
            // O menor dos dois encaixes garante que a grade caiba sem rolagem,
            // em qualquer proporção de puzzle e em telas pequenas.
            let side = max(10, min(46, min(fitWidth, fitHeight)))
            let letters = puzzle.letterByCell

            VStack(spacing: spacing) {
                ForEach(0..<puzzle.height, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<puzzle.width, id: \.self) { column in
                            let cell = WordPuzzle.Cell(row: row, column: column)
                            if let letter = letters[cell] {
                                WordGridCell(
                                    letter: letter,
                                    side: side,
                                    isOpen: openCells.contains(cell),
                                    isHint: hintCells.contains(cell),
                                    isBumping: bumpCells.contains(cell),
                                    celebrate: celebrate
                                )
                                .wordAnchor("cell-\(row)-\(column)")
                            } else {
                                Color.clear.frame(width: side, height: side)
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct WordGridCell: View {
    let letter: String
    let side: CGFloat
    let isOpen: Bool
    let isHint: Bool
    let isBumping: Bool
    let celebrate: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)

        ZStack {
            shape
                .fill(LumeColor.brandPlumStart.opacity(0.07))
                .overlay(shape.strokeBorder(LumeColor.brandPlumStart.opacity(0.13), lineWidth: 1))

            shape
                .fill(isHint ? LumeColor.amberChipBgMid : Color.white)
                .overlay(shape.strokeBorder(LumeColor.brand.opacity(0.3), lineWidth: 1))
                .overlay(
                    Text(letter)
                        .font(LumeType.serif(side * 0.5))
                        .foregroundStyle(LumeColor.ink)
                )
                .shadow(color: LumeColor.brandPlumStart.opacity(0.12), radius: 4, x: 0, y: 2)
                .opacity(isOpen ? 1 : 0)
                .rotation3DEffect(.degrees(isOpen ? 0 : 90), axis: (x: 1, y: 0, z: 0))
        }
        .frame(width: side, height: side)
        .scaleEffect(isBumping ? 1.14 : (celebrate && isOpen ? 1.03 : 1))
        .animation(.spring(response: 0.32, dampingFraction: 0.5), value: isBumping)
        .animation(.easeInOut(duration: 0.55), value: celebrate)
    }
}

// MARK: - Letras voando

struct LetterFlight: Identifiable {
    let id = UUID()
    let letter: String
    let tileID: Int
    let cell: WordPuzzle.Cell
    let delay: Double
}

private struct FlyingLetterView: View {
    let letter: String
    let from: CGPoint
    let to: CGPoint
    let delay: Double
    let size: CGFloat

    @State private var arrived = false

    var body: some View {
        Text(letter)
            .font(LumeType.serif(size * 0.5))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(LumeColor.brand))
            .shadow(color: LumeColor.brand.opacity(0.4), radius: 10, x: 0, y: 4)
            .scaleEffect(arrived ? 0.52 : 1)
            .opacity(arrived ? 0 : 1)
            .position(arrived ? to : from)
            .onAppear {
                withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.42).delay(delay)) {
                    arrived = true
                }
            }
    }
}

// MARK: - Confete

private struct ConfettiView: View {
    let start: Date

    private struct Particle {
        let x: Double
        let vx: Double
        let vy: Double
        let size: Double
        let rotation: Double
        let spin: Double
        let color: Color
    }

    private let particles: [Particle]

    init(start: Date) {
        self.start = start
        let palette: [Color] = [
            LumeColor.brand, LumeColor.amberAccent, LumeColor.greenDeep,
            LumeColor.lavenderAccent, LumeColor.roseOrb,
        ]
        particles = (0..<70).map { _ in
            Particle(
                x: Double.random(in: 0.18...0.82),
                vx: Double.random(in: -2.6...2.6),
                vy: Double.random(in: -7.5...(-2.5)),
                size: Double.random(in: 3...7),
                rotation: Double.random(in: 0...(.pi * 2)),
                spin: Double.random(in: -4...4),
                color: palette.randomElement() ?? LumeColor.brand
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { graphics, size in
                let elapsed = context.date.timeIntervalSince(start)
                guard elapsed < 2.1 else { return }
                graphics.opacity = max(0, 1 - elapsed / 2.1)

                for particle in particles {
                    let x = size.width * particle.x + particle.vx * elapsed * 60
                    let y = size.height * 0.42 + particle.vy * elapsed * 60 + 210 * elapsed * elapsed
                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * 1.7
                    )
                    let transform = CGAffineTransform(translationX: x, y: y)
                        .rotated(by: particle.rotation + particle.spin * elapsed)
                    graphics.fill(Path(rect).applying(transform), with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
