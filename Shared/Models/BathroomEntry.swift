import Foundation
import SwiftData

/// Just a timestamp. Per the design brief: "Só a contagem do dia. Nada além
/// disso é guardado." — no Bristol scale, no notes, ever.
@Model
final class BathroomEntry {
    var date: Date

    init(date: Date = .now) {
        self.date = date
    }
}
