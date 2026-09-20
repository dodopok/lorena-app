import SwiftUI

/// Two glass treatments, matching the two materials used throughout the mockup:
///
/// 1. **System Liquid Glass** (`lumeGlassCapsule` / `lumeGlassCircle` / `lumeGlass`)
///    — real iOS 26 `.glassEffect`, reserved for chrome: buttons, the floating
///    tab bar, small circular icon buttons, pills. This is what Apple's HIG
///    recommends Liquid Glass for — navigation and controls, not arbitrary
///    content containers.
/// 2. **Soft glass** (`lumeSoftGlass`) — a frosted-paper `Material` card with a
///    translucent white wash and a hairline border, matching the
///    `rgba(255,255,255,.5) + backdrop-filter: blur()` cards that hold content
///    (event cards, transaction rows, grid tiles) in the mockup.
extension View {
    /// Real Liquid Glass, in an arbitrary rounded-rect shape. Use for chrome.
    func lumeGlass(cornerRadius: CGFloat = 26, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return self.glassEffect(glass, in: shape)
    }

    /// Real Liquid Glass in a capsule. Use for pills and the tab bar.
    func lumeGlassCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return self.glassEffect(glass, in: Capsule())
    }

    /// Real Liquid Glass in a circle. Use for round icon buttons.
    func lumeGlassCircle(tint: Color? = nil, interactive: Bool = false) -> some View {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return self.glassEffect(glass, in: Circle())
    }

    /// Frosted-paper content card: translucent white wash over a thin material,
    /// with a hairline highlight border and soft shadow.
    func lumeSoftGlass(cornerRadius: CGFloat = 26, opacity: Double = 0.55, shadow: Bool = true) -> some View {
        modifier(LumeSoftGlassCard(cornerRadius: cornerRadius, opacity: opacity, shadow: shadow))
    }

    /// Same treatment, but on a fully custom shape (circles, capsules, etc).
    func lumeSoftGlass<S: Shape>(_ shape: S, opacity: Double = 0.55, shadow: Bool = true) -> some View {
        modifier(LumeSoftGlassShape(shape: shape, opacity: opacity, shadow: shadow))
    }
}

private struct LumeSoftGlassCard: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var shadow: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.fill(Color.white.opacity(opacity)))
            }
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
            }
            .clipShape(shape)
            .shadow(color: shadow ? LumeColor.ink.opacity(0.08) : .clear, radius: 20, x: 0, y: 10)
    }
}

private struct LumeSoftGlassShape<S: Shape>: ViewModifier {
    var shape: S
    var opacity: Double
    var shadow: Bool

    func body(content: Content) -> some View {
        content
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.fill(Color.white.opacity(opacity)))
            }
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
            }
            .clipShape(shape)
            .shadow(color: shadow ? LumeColor.ink.opacity(0.1) : .clear, radius: 18, x: 0, y: 9)
    }
}

/// The deep plum "available balance" hero treatment used on Hoje and Finanças.
struct LumePlumCard: ViewModifier {
    var cornerRadius: CGFloat = 30

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(
                LinearGradient(
                    colors: [LumeColor.brandPlumStart, LumeColor.brandPlumEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay { shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 1) }
            .clipShape(shape)
            .shadow(color: LumeColor.brandPlumStart.opacity(0.28), radius: 26, x: 0, y: 16)
    }
}

extension View {
    func lumePlumCard(cornerRadius: CGFloat = 30) -> some View {
        modifier(LumePlumCard(cornerRadius: cornerRadius))
    }
}
