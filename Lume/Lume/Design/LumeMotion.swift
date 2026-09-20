import SwiftUI

// MARK: - Drifting background orbs (mirrors the mockup's `lumeDrift` keyframe)

struct OrbSpec: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
    var alignment: Alignment
    var offset: CGSize
    var duration: Double
    var reversed: Bool = false
}

/// A soft field of blurred, slowly drifting color blobs behind a screen's content.
struct LumeOrbBackground: View {
    var orbs: [OrbSpec]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(orbs) { orb in
                    let anchor = anchorPoint(for: orb.alignment, in: geo.size)
                    Circle()
                        .fill(orb.color)
                        .frame(width: orb.size, height: orb.size)
                        .opacity(orb.opacity)
                        .blur(radius: orb.blur)
                        .position(x: anchor.x + orb.offset.width, y: anchor.y + orb.offset.height)
                        .offset(driftOffset(orb))
                        .scaleEffect(driftScale)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: orb.duration).repeatForever(autoreverses: true),
                            value: drift
                        )
                }
            }
        }
        .onAppear { drift = true }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var driftScale: CGFloat { drift && !reduceMotion ? 1.12 : 1 }

    private func driftOffset(_ orb: OrbSpec) -> CGSize {
        guard drift, !reduceMotion else { return .zero }
        return CGSize(width: orb.reversed ? -18 : 18, height: -22)
    }

    private func anchorPoint(for alignment: Alignment, in size: CGSize) -> CGPoint {
        let x: CGFloat = switch alignment.horizontal {
        case .leading: 0
        case .trailing: size.width
        default: size.width / 2
        }
        let y: CGFloat = switch alignment.vertical {
        case .top: 0
        case .bottom: size.height
        default: size.height / 2
        }
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Sheen sweep (mirrors `lumeSheen`)

private struct SheenOverlay: View {
    var duration: Double = 6
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.75), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: geo.size.width * 0.5)
            .rotationEffect(.degrees(18))
            .offset(x: animate ? geo.size.width * 1.4 : -geo.size.width * 1.4)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: duration).repeatForever(autoreverses: false),
                value: animate
            )
        }
        .allowsHitTesting(false)
        .onAppear { if !reduceMotion { animate = true } }
    }
}

extension View {
    /// A soft diagonal highlight that periodically sweeps across the view.
    func lumeSheen<S: Shape>(_ shape: S, duration: Double = 6) -> some View {
        self.overlay(SheenOverlay(duration: duration).clipShape(shape))
    }
}

// MARK: - Pulse ring (mirrors `lumePulse`)

private struct PulseRing<S: Shape>: ViewModifier {
    var shape: S
    var color: Color
    var duration: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    func body(content: Content) -> some View {
        content.background {
            shape
                .stroke(color.opacity(animate ? 0 : 0.32), lineWidth: 14)
                .scaleEffect(animate ? 1.35 : 1)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: duration).repeatForever(autoreverses: false),
                    value: animate
                )
        }
        .onAppear { if !reduceMotion { animate = true } }
    }
}

extension View {
    func lumePulse<S: Shape>(_ shape: S, color: Color = LumeColor.brand, duration: Double = 3) -> some View {
        modifier(PulseRing(shape: shape, color: color, duration: duration))
    }
}

// MARK: - Staggered rise-in entrance (mirrors `lumeRise`)

private struct RiseIn: ViewModifier {
    var delay: Double
    var duration: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.easeOut(duration: duration).delay(delay)) { appeared = true }
                }
            }
    }
}

extension View {
    func lumeRiseIn(delay: Double = 0, duration: Double = 0.6) -> some View {
        modifier(RiseIn(delay: delay, duration: duration))
    }
}

// MARK: - Gentle float (mirrors `lumeFloat`)

private struct FloatModifier: ViewModifier {
    var amplitude: CGFloat
    var duration: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .offset(y: animate ? -amplitude : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: duration / 2).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear { if !reduceMotion { animate = true } }
    }
}

extension View {
    func lumeFloat(amplitude: CGFloat = 9, duration: Double = 6) -> some View {
        modifier(FloatModifier(amplitude: amplitude, duration: duration))
    }
}

// MARK: - Breathing glow / halo (mirrors `lumeGlow` / `lumeHalo`)

private struct GlowModifier: ViewModifier {
    var scale: CGFloat
    var duration: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? scale : 1)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: duration / 2).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear { if !reduceMotion { animate = true } }
    }
}

extension View {
    func lumeGlow(scale: CGFloat = 1.06, duration: Double = 5) -> some View {
        modifier(GlowModifier(scale: scale, duration: duration))
    }
}

/// A pulsing blurred halo, meant to sit *behind* a subject (e.g. the onboarding icon).
struct LumeHalo: View {
    var color: Color
    var size: CGFloat
    var duration: Double = 5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.17)
            .opacity(animate ? 0.6 : 0.35)
            .scaleEffect(animate ? 1.14 : 1)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: duration / 2).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear { if !reduceMotion { animate = true } }
            .allowsHitTesting(false)
    }
}

// MARK: - Blinking text-entry cursor (mirrors `lumeBlink`)

struct LumeBlinkingCursor: View {
    var color: Color = LumeColor.brand
    var width: CGFloat = 2
    var height: CGFloat = 44
    var cornerRadius: CGFloat = 2
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            RoundedRectangle(cornerRadius: cornerRadius).fill(color).frame(width: width, height: height)
        } else {
            TimelineView(.periodic(from: .now, by: 0.55)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate / 0.55)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .frame(width: width, height: height)
                    .opacity(tick.isMultiple(of: 2) ? 1 : 0)
            }
        }
    }
}
