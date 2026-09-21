import SwiftUI

/// A roda de letras. Um dedo apoiado e arrastado pelas peças forma a palavra;
/// o traço acompanha o dedo e voltar uma casa desfaz a última letra.
struct LetterWheelView: View {
    let wheel: [WheelLetter]
    let selection: [Int]
    let diameter: CGFloat
    let onBegin: () -> Void
    let onTouch: (Int) -> Void
    let onCommit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragPoint: CGPoint?

    private var tileSize: CGFloat { max(40, min(58, diameter * 0.2)) }
    private var radius: CGFloat { diameter / 2 - tileSize / 2 - 10 }

    private func position(ofID id: Int) -> Int? {
        wheel.firstIndex { $0.id == id }
    }

    private func center(atPosition index: Int) -> CGPoint {
        let angle = -Double.pi / 2 + Double(index) / Double(max(wheel.count, 1)) * 2 * .pi
        return CGPoint(
            x: diameter / 2 + cos(angle) * radius,
            y: diameter / 2 + sin(angle) * radius
        )
    }

    private func center(ofID id: Int) -> CGPoint? {
        position(ofID: id).map(center(atPosition:))
    }

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().fill(.white.opacity(0.42))
            Circle().strokeBorder(.white.opacity(0.95), lineWidth: 1)

            trail

            ForEach(Array(wheel.enumerated()), id: \.element.id) { index, item in
                tile(item, isSelected: selection.contains(item.id))
                    .position(center(atPosition: index))
                    .wordAnchor("tile-\(item.id)")
            }
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: LumeColor.brandPlumStart.opacity(0.14), radius: 18, x: 0, y: 10)
        .contentShape(Circle())
        .gesture(drag)
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.78), value: wheel)
        .accessibilityLabel("Roda de letras")
        .accessibilityValue(wheel.map(\.letter).joined(separator: ", "))
    }

    private func tile(_ item: WheelLetter, isSelected: Bool) -> some View {
        Text(item.letter)
            .font(LumeType.serif(tileSize * 0.46))
            .foregroundStyle(isSelected ? .white : LumeColor.ink)
            .frame(width: tileSize, height: tileSize)
            .background(Circle().fill(isSelected ? LumeColor.brand : .white))
            .overlay(
                Circle().strokeBorder(
                    isSelected ? Color.clear : LumeColor.brandPlumStart.opacity(0.1),
                    lineWidth: 1
                )
            )
            .shadow(
                color: isSelected ? LumeColor.brand.opacity(0.4) : LumeColor.brandPlumStart.opacity(0.14),
                radius: isSelected ? 10 : 6,
                x: 0,
                y: 4
            )
            .scaleEffect(isSelected ? 1.12 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.7), value: isSelected)
    }

    private var trail: some View {
        Path { path in
            let points = selection.compactMap(center(ofID:))
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            if let dragPoint { path.addLine(to: dragPoint) }
        }
        .stroke(
            LumeColor.brand.opacity(0.42),
            style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
        )
        .allowsHitTesting(false)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragPoint == nil && selection.isEmpty { onBegin() }
                dragPoint = value.location
                if let id = id(at: value.location) { onTouch(id) }
            }
            .onEnded { _ in
                dragPoint = nil
                onCommit()
            }
    }

    private func id(at point: CGPoint) -> Int? {
        for (index, item) in wheel.enumerated() {
            let center = center(atPosition: index)
            if hypot(point.x - center.x, point.y - center.y) <= tileSize * 0.62 {
                return item.id
            }
        }
        return nil
    }
}

// MARK: - Âncoras para a animação das letras voando

/// Publica a posição de peças e células para que a camada de voo saiba de onde
/// e para onde animar, sem que ninguém precise medir a tela na mão.
struct WordAnchorKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGPoint>] = [:]

    static func reduce(value: inout [String: Anchor<CGPoint>], nextValue: () -> [String: Anchor<CGPoint>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func wordAnchor(_ id: String) -> some View {
        anchorPreference(key: WordAnchorKey.self, value: .center) { [id: $0] }
    }
}
