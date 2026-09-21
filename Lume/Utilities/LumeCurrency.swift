import Foundation

/// Lume is pt-BR only, so currency formatting is hardcoded to Brazilian
/// conventions (comma decimals, dot thousands) regardless of device locale.
enum LumeCurrency {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// "1.200,00" — no currency symbol.
    static func number(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "0,00"
    }

    /// "R$ 1.200,00"
    static func full(_ value: Double) -> String {
        "R$ \(number(value))"
    }

    /// Parses raw typed digits (cents-based, e.g. "4890") into a Double amount (48.90).
    static func amount(fromDigits digits: String) -> Double {
        let cents = Int(digits) ?? 0
        return Double(cents) / 100
    }

    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// "2.000" — grouped integer, no decimals.
    static func integer(_ value: Int) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
