import Foundation
import SwiftData

enum ExerciseIntensity: String, Codable, CaseIterable, Identifiable, Hashable {
    case leve, moderada, intensa

    var id: String { rawValue }

    var label: String {
        switch self {
        case .leve: "Leve"
        case .moderada: "Moderada"
        case .intensa: "Intensa"
        }
    }
}

enum ExerciseType: String, CaseIterable, Identifiable, Hashable {
    case caminhada = "Caminhada"
    case pilates = "Pilates"
    case corrida = "Corrida"
    case yoga = "Yoga"
    case outro = "Outro"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .caminhada: "figure.walk"
        case .pilates: "figure.pilates"
        case .corrida: "figure.run"
        case .yoga: "figure.yoga"
        case .outro: "figure.mixed.cardio"
        }
    }
}

@Model
final class ExerciseEntry {
    var type: String
    var durationMinutes: Int
    var intensityRaw: String
    var date: Date

    init(type: String, durationMinutes: Int, intensity: ExerciseIntensity = .leve, date: Date = .now) {
        self.type = type
        self.durationMinutes = durationMinutes
        self.intensityRaw = intensity.rawValue
        self.date = date
    }

    var intensity: ExerciseIntensity {
        get { ExerciseIntensity(rawValue: intensityRaw) ?? .leve }
        set { intensityRaw = newValue.rawValue }
    }
}
