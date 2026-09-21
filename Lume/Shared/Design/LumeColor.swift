import SwiftUI

/// Every color used across Lume, lifted from the "vidro sobre luz rosada" design.
/// The app is light-mode only for now, so these are plain constants rather than
/// asset-catalog color sets with dark variants.
enum LumeColor {
    // MARK: Canvas
    static let paper = Color(hex: "EFE7E2")
    static let canvas = Color(hex: "FBF3F0")

    // MARK: Ink / text
    static let ink = Color(hex: "2B2124")
    static let inkSoft = Color(hex: "4A3F42")
    static let textPrimary = Color(hex: "2B2124")
    static let textSecondary = Color(hex: "5A4B4F")
    static let textTertiary = Color(hex: "6F6064")
    static let textMuted = Color(hex: "7C6B6F")
    static let textFaint = Color(hex: "8C7B7F")
    static let textFainter = Color(hex: "9A8A8E")

    // MARK: Brand
    static let brand = Color(hex: "A44266")
    static let brandDeep = Color(hex: "7A294B")
    static let brandPlumStart = Color(hex: "5E2438")
    static let brandPlumEnd = Color(hex: "7C304A")
    static let brandOnPlumLabel = Color(hex: "EFC6D5")
    static let brandOnPlumSecondary = Color(hex: "F0D2DC")
    static let brandPillLight = Color(hex: "F7E3E7")
    static let brandChipBg = Color(hex: "F5D6E0")

    // MARK: Rose (orbs / accents)
    static let roseOrb = Color(hex: "F3B7C8")
    static let roseSoft = Color(hex: "F2D3DE")
    static let roseBadge = Color(hex: "F0C3D2")

    // MARK: Green (água / positivo)
    static let greenDeep = Color(hex: "3F7D68")
    static let greenLight = Color(hex: "6FB39C")
    static let greenText = Color(hex: "2E5B4A")
    static let greenTextDeep = Color(hex: "2B4438")
    static let greenChipBg = Color(hex: "DCE9E0")
    static let greenChipBgMid = Color(hex: "BFD9C9")
    static let greenChipBgFaint = Color(hex: "E7EFE9")
    static let greenBar = Color(hex: "CFE2D6")
    static let greenOrb = Color(hex: "A8D4C4")

    // MARK: Water
    static let waterBlue = Color(hex: "4A9BC5")
    static let waterBlueLight = Color(hex: "8BCBE5")
    static let waterBlueText = Color(hex: "246486")

    // MARK: Terracotta / âmbar (mesada, trabalho)
    static let amberOrb = Color(hex: "E9C79A")
    static let amberAccent = Color(hex: "C1894A")
    static let amberLabel = Color(hex: "8A7358")
    static let amberText = Color(hex: "6B5540")
    static let amberChipBg = Color(hex: "F2E5D3")
    static let amberChipBgMid = Color(hex: "F7DFC4")
    static let amberChipBgFaint = Color(hex: "EFDCC4")
    static let amberDeep = Color(hex: "A06A3A")

    // MARK: Lavanda (rotina, desejos)
    static let lavenderOrb = Color(hex: "C9BEE4")
    static let lavenderAccent = Color(hex: "7C6BB0")
    static let lavenderChipBg = Color(hex: "D7D2EA")
    static let lavenderChipBgFaint = Color(hex: "E7E6F2")
    static let lavenderTextDeep = Color(hex: "39344F")
    static let lavenderText = Color(hex: "56507A")

    // MARK: Status
    static let errorText = Color(hex: "B53D3B")
    static let errorFaint = Color(hex: "D7A8A6")

    // MARK: Lock screen (dark)
    static let lockGradientTop = Color(hex: "6B2B41")
    static let lockGradientBottom = Color(hex: "2A1520")
    static let lockBlobA = Color(hex: "C4557A")
    static let lockBlobB = Color(hex: "8B5E7A")
    static let lockTextPrimary = Color(hex: "FDF4F6")
    static let lockTextSecondary = Color(hex: "E0B7C6")
    static let lockTextTertiary = Color(hex: "EBCFD9")

    // MARK: Glass strokes / fills (opacity applied at call site)
    static let glassStroke = Color.white
    static let glassFill = Color.white
}

/// The four Agenda categories, each with a brand color used for dots, bars and chips.
enum AgendaCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case rotina, saude, pessoal, trabalho

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rotina: "Rotina"
        case .saude: "Saúde"
        case .pessoal: "Pessoal"
        case .trabalho: "Trabalho"
        }
    }

    var accent: Color {
        switch self {
        case .rotina: LumeColor.lavenderAccent
        case .saude: LumeColor.brand
        case .pessoal: LumeColor.greenDeep
        case .trabalho: LumeColor.amberAccent
        }
    }

    var chipBackground: Color {
        switch self {
        case .rotina: LumeColor.lavenderChipBg
        case .saude: LumeColor.roseSoft
        case .pessoal: LumeColor.greenBar
        case .trabalho: LumeColor.amberChipBgMid
        }
    }
}

/// Finance categories used on expenses and the Finanças filter chips.
enum FinanceCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case mercado, casa, transporte, saude, lazer, outros

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mercado: "Mercado"
        case .casa: "Casa"
        case .transporte: "Transporte"
        case .saude: "Saúde"
        case .lazer: "Lazer"
        case .outros: "Outros"
        }
    }

    var iconBackground: Color {
        switch self {
        case .mercado: LumeColor.amberChipBg
        case .casa: LumeColor.lavenderChipBgFaint
        case .transporte: LumeColor.lavenderChipBgFaint
        case .saude: LumeColor.greenChipBg
        case .lazer: LumeColor.roseSoft
        case .outros: LumeColor.amberChipBg
        }
    }

    var symbolName: String {
        switch self {
        case .mercado: "basket.fill"
        case .casa: "house.fill"
        case .transporte: "car.fill"
        case .saude: "cross.case.fill"
        case .lazer: "sparkles"
        case .outros: "ellipsis.circle.fill"
        }
    }
}
