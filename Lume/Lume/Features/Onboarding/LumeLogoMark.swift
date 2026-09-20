import SwiftUI

/// The animated glass-disc logo mark: a pulsing halo, a floating glass disc,
/// the app icon glowing softly inside it, and a sheen sweeping across the
/// glass — the "animated logo" requested for the onboarding open.
struct LumeLogoMark: View {
    var diameter: CGFloat = 184
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LumeHalo(color: Color(hex: "EE6289"), size: diameter * 0.82)

            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(.white.opacity(0.5)))
                .overlay(Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1))
                .frame(width: diameter, height: diameter)
                .lumeSheen(Circle(), duration: 5.5)
                .shadow(color: LumeColor.brandPlumStart.opacity(0.16), radius: 22, x: 0, y: 12)
                .overlay {
                    Image("LumeMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: diameter * 0.64, height: diameter * 0.64)
                        .clipShape(RoundedRectangle(cornerRadius: diameter * 0.16, style: .continuous))
                        .shadow(color: LumeColor.brandPlumStart.opacity(0.26), radius: 14, x: 0, y: 8)
                        .lumeGlow(scale: 1.05, duration: 5)
                }
                .lumeFloat(amplitude: diameter * 0.05, duration: 6)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// The 3-segment progress bar shown atop the água and mesada onboarding steps.
struct OnboardingProgressBar: View {
    var filledCount: Int
    var total: Int = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < filledCount ? LumeColor.brand : LumeColor.brand.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }
}
