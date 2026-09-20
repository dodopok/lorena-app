import SwiftUI

/// A gently rippling wave, drawn from a continuous wall-clock phase so it never
/// fights with SwiftUI's animation system (see `WaterFillRing`).
private struct WaterWaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: amplitude))
        let step: CGFloat = max(2, rect.width / 60)
        var x: CGFloat = 0
        while x <= rect.width {
            let relativeX = x / max(rect.width, 1)
            let y = amplitude + amplitude * CGFloat(sin(Double(relativeX) * .pi * 2 + phase))
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// The circular glass "how much water today" indicator — a rippling green fill
/// rising to `progress`, with a value/unit label centered on top.
///
/// Used at several sizes: the big onboarding goal picker, the Hoje quick card,
/// the Bem-estar summary, and the lock-screen Live Activity.
struct WaterFillRing: View {
    var progress: Double
    var diameter: CGFloat
    var valueText: String
    var unitText: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().fill(Color.white.opacity(0.45))

            GeometryReader { geo in
                let fillHeight = geo.size.height * clamped
                Group {
                    if reduceMotion {
                        waveFill(phase: 0)
                    } else {
                        TimelineView(.animation) { context in
                            let t = context.date.timeIntervalSinceReferenceDate
                            let phase = t.truncatingRemainder(dividingBy: 2.6) / 2.6 * (.pi * 2)
                            waveFill(phase: phase)
                        }
                    }
                }
                .frame(width: geo.size.width, height: max(fillHeight, 0), alignment: .top)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                .animation(.easeInOut(duration: 0.7), value: clamped)
            }
            .clipShape(Circle())

            Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 1)

            VStack(spacing: max(2, diameter * 0.016)) {
                Text(valueText)
                    .font(LumeType.serif(diameter * 0.22))
                    .foregroundStyle(LumeColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unitText {
                    LumeEyebrow(text: unitText, color: LumeColor.textSecondary, size: max(9, diameter * 0.048))
                }
            }
            .padding(6)
        }
        .frame(width: diameter, height: diameter)
    }

    private func waveFill(phase: Double) -> some View {
        WaterWaveShape(phase: phase, amplitude: max(3, diameter * 0.02))
            .fill(
                LinearGradient(
                    colors: [LumeColor.greenLight, LumeColor.greenDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
