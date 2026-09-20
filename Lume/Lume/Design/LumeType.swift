import SwiftUI

/// Type ramp for Lume.
///
/// The Claude Design mockup specifies Newsreader (serif), Nunito Sans (UI) and
/// IBM Plex Mono (tracked-out labels). Rather than bundling third-party font
/// files — which we can't proof on this machine without Xcode — we lean on
/// Apple's own equivalents, which are built for exactly this "warm editorial"
/// pairing and are guaranteed to render correctly:
///   - Newsreader  -> New York (`.serif` design), Apple's own editorial serif.
///   - Nunito Sans -> SF Pro (`.default` design).
///   - IBM Plex Mono -> SF Mono (`.monospaced` design).
/// If you'd rather use the exact original fonts, drop the .ttf files into
/// Lume/Resources/Fonts, register them in Info.plist under UIAppFonts, and
/// swap the `.system(design:)` calls below for `.custom(_:size:)`.
enum LumeType {
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // Common presets used throughout the app.
    static let displayHero = serif(64)
    static let heroSerif = serif(44, weight: .regular)
    static let titleSerif = serif(32)
    static let sectionSerif = serif(23)
    static let bodySerif = serif(17)

    static let eyebrow = mono(11, weight: .medium)
    static let eyebrowTiny = mono(10.5, weight: .medium)

    static let bodyBold = sans(15.5, weight: .bold)
    static let body = sans(15.5, weight: .regular)
    static let caption = sans(13, weight: .medium)
    static let button = sans(16.5, weight: .bold)
}

/// A small caps, letter-spaced "eyebrow" label like "DISPONÍVEL" or "HOJE".
struct LumeEyebrow: View {
    let text: String
    var color: Color = LumeColor.textFaint
    var size: CGFloat = 11

    var body: some View {
        Text(text.uppercased())
            .font(LumeType.mono(size, weight: .medium))
            .tracking(size * 0.16)
            .foregroundStyle(color)
    }
}
