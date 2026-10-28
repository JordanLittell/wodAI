//
//  TrainingMemory.swift
//  wodAI
//
//  What the coach keeps to (the backend's `trainingMemory`), Apollo-free so
//  the screen's rules are testable: a focus block with its week, habits kept
//  every session, and things left out of every session. Items are only added
//  in the trainer chat, after the athlete says yes; this screen corrects and
//  removes them.
//

import Foundation

struct TrainingMemoryItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case focus, habit, avoid
    }

    /// The longest focus block the server accepts (its MAX_FOCUS_WEEKS).
    static let maxWeeks = 12
    /// The server's limit on an item's text.
    static let maxTextLength = 120

    let id: String
    let kind: Kind
    var text: String
    /// A focus block's first day and the day after its last, "YYYY-MM-DD";
    /// nil for a habit or avoid.
    var startsOn: String?
    var endsOn: String?

    /// Where a focus block stands on `today`.
    enum BlockStage: Equatable {
        case week(Int, of: Int)
        /// The last week of a block longer than one: de-load, then test.
        case testWeek(of: Int)
        /// Past its end; the coach asks whether to extend it, switch, or stop.
        case finished
    }

    /// The block's length in whole weeks (at least 1); nil without dates.
    var totalWeeks: Int? {
        guard let start = Self.day(startsOn), let end = Self.day(endsOn) else { return nil }
        let days = Self.days(from: start, to: end)
        return max(1, Int((Double(days) / 7).rounded()))
    }

    func stage(on today: Date, calendar: Calendar = .current) -> BlockStage? {
        guard let start = Self.day(startsOn), let end = Self.day(endsOn), let total = totalWeeks else { return nil }
        let todayDay = Self.utcDay(of: today, in: calendar)
        if Self.days(from: end, to: todayDay) >= 0 { return .finished }
        let week = min(total, max(1, Self.days(from: start, to: todayDay) / 7 + 1))
        return total > 1 && week == total ? .testWeek(of: total) : .week(week, of: total)
    }

    /// The card's line under a focus: "Week 2 of 4", "Week 4 of 4 · de-load
    /// and test", or what to do once it's over.
    func stageLine(on today: Date, calendar: Calendar = .current) -> String? {
        switch stage(on: today, calendar: calendar) {
        case let .week(week, total): return "Week \(week) of \(total)"
        case let .testWeek(total): return "Week \(total) of \(total) · de-load and test"
        case .finished: return "Block finished. Tell the coach whether to extend it, switch focus, or stop."
        case nil: return nil
        }
    }

    // MARK: Calendar days

    /// Calendar days are compared at UTC midnight, so a day is always 24 hours.
    private static let utc = TimeZone(identifier: "UTC")!

    private static func day(_ value: String?) -> Date? {
        guard let value else { return nil }
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// The athlete's calendar day for `date`, as a UTC midnight.
    private static func utcDay(of date: Date, in calendar: Calendar) -> Date {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utc
        return utcCalendar.date(from: parts) ?? date
    }

    private static func days(from start: Date, to end: Date) -> Int {
        Int((end.timeIntervalSince(start) / 86_400).rounded(.down))
    }
}

struct TrainingMemory: Equatable {
    var focus: TrainingMemoryItem?
    var habits: [TrainingMemoryItem] = []
    var avoid: [TrainingMemoryItem] = []

    static let empty = TrainingMemory()

    var isEmpty: Bool { focus == nil && habits.isEmpty && avoid.isEmpty }

    func item(id: String) -> TrainingMemoryItem? {
        ([focus].compactMap { $0 } + habits + avoid).first { $0.id == id }
    }

    /// With `item` in place of the one with its id.
    func replacing(_ item: TrainingMemoryItem) -> TrainingMemory {
        var copy = self
        if copy.focus?.id == item.id { copy.focus = item }
        copy.habits = habits.map { $0.id == item.id ? item : $0 }
        copy.avoid = avoid.map { $0.id == item.id ? item : $0 }
        return copy
    }

    func removing(id: String) -> TrainingMemory {
        var copy = self
        if copy.focus?.id == id { copy.focus = nil }
        copy.habits.removeAll { $0.id == id }
        copy.avoid.removeAll { $0.id == id }
        return copy
    }
}
