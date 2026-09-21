import Foundation
import SwiftData

@Model
final class WaterEntry {
    var amountML: Int
    var date: Date

    init(amountML: Int, date: Date = .now) {
        self.amountML = amountML
        self.date = date
    }
}
