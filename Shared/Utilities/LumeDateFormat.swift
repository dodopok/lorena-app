import Foundation

enum LumeDateFormat {
    static let ptBR = Locale(identifier: "pt_BR")

    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = ptBR
        cal.firstWeekday = 2 // segunda-feira
        return cal
    }()

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = ptBR
        f.calendar = calendar
        f.dateFormat = format
        return f
    }

    /// "Sexta, 20 de setembro"
    static func fullWeekdayDayMonth(_ date: Date) -> String {
        formatter("EEEE, d 'de' MMMM").string(from: date).capitalizedFirstLetter
    }

    /// "SEXTA, 20"
    static func shortWeekdayDayUppercased(_ date: Date) -> String {
        formatter("EEE, d").string(from: date).uppercased()
    }

    /// "14:30"
    static func time(_ date: Date) -> String {
        formatter("HH:mm").string(from: date)
    }

    /// "19 set"
    static func dayMonthAbbrev(_ date: Date) -> String {
        formatter("d MMM").string(from: date).replacingOccurrences(of: ".", with: "")
    }

    /// "Setembro"
    static func monthFull(_ date: Date) -> String {
        formatter("MMMM").string(from: date).capitalizedFirstLetter
    }

    /// "Setembro 2026"
    static func monthYear(_ date: Date) -> String {
        formatter("MMMM yyyy").string(from: date).capitalizedFirstLetter
    }

    /// "15 – 21 set"
    static func weekRange(containing date: Date) -> String {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return "" }
        let start = interval.start
        let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        let startDay = formatter("d").string(from: start)
        let endDay = formatter("d").string(from: end)
        let month = dayMonthAbbrev(end).split(separator: " ").last.map(String.init) ?? ""
        return "\(startDay) – \(endDay) \(month)"
    }

    /// Single-letter weekday initial, Monday-first: S T Q Q S S D
    static func weekdayInitial(_ date: Date) -> String {
        let symbol = formatter("EEEEE").string(from: date)
        return symbol.uppercased()
    }

    /// "EM 5H" / "EM 40MIN" / "AGORA" relative label for the next-event card.
    static func relativeCountdown(to date: Date, from now: Date = .now) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds <= 0 { return "AGORA" }
        let hours = Int(seconds / 3600)
        if hours >= 1 { return "EM \(hours)H" }
        let minutes = max(1, Int(seconds / 60))
        return "EM \(minutes)MIN"
    }
}

extension String {
    var capitalizedFirstLetter: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

extension Date {
    var isToday: Bool { LumeDateFormat.calendar.isDateInToday(self) }
    var isYesterday: Bool { LumeDateFormat.calendar.isDateInYesterday(self) }
    var startOfDay: Date { LumeDateFormat.calendar.startOfDay(for: self) }

    func adding(days: Int) -> Date {
        LumeDateFormat.calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        LumeDateFormat.calendar.isDate(self, inSameDayAs: other)
    }
}
