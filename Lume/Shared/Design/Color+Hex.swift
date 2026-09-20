import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Creates a color from a 6-digit hex string, e.g. "A44266".
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// A slightly darker variant, used to derive two-stop cover gradients
    /// from a single stored seed color (see `Book.coverColorHex`).
    func darkened(by amount: Double = 0.16) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            red: Double(max(0, r - amount)),
            green: Double(max(0, g - amount)),
            blue: Double(max(0, b - amount)),
            opacity: Double(a)
        )
        #else
        return self
        #endif
    }
}
