//
//  AssistantWeek.swift
//  wodAI
//
//  Pure, Apollo-free day math for the Assistant page's week navigator.
//

import Foundation
import WodAiAPI

/// The current week as seven local calendar days, plus conversions to and
/// from the server's date-only `scheduledDate`.
///
/// The server stores a scheduled day as UTC midnight ("2026-10-01T00:00:00Z").
/// Read as an instant, that's still Sep 30 in the Americas, so days are
/// always compared as calendar dates, never as instants.
struct AssistantWeek: Equatable {
    let calendar: Calendar
    /// Local start-of-day for each day of the week, in order.
    let days: [Date]
    /// Local start-of-day for `now`.
    let today: Date

    init(containing now: Date = Date(), calendar: Calendar = .current) {
        self.calendar = calendar
        let week = ActivityWeek(containing: now, calendar: calendar)
        let start = calendar.startOfDay(for: week.start)
        self.days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        self.today = calendar.startOfDay(for: now)
    }

    var first: Date { days[0] }
    var last: Date { days[days.count - 1] }

    func contains(_ day: Date) -> Bool {
        days.contains(calendar.startOfDay(for: day))
    }

    /// The next day, or nil past the end of the week.
    func day(after day: Date) -> Date? {
        guard let index = days.firstIndex(of: calendar.startOfDay(for: day)), index + 1 < days.count else { return nil }
        return days[index + 1]
    }

    /// The previous day, or nil before the start of the week.
    func day(before day: Date) -> Date? {
        guard let index = days.firstIndex(of: calendar.startOfDay(for: day)), index > 0 else { return nil }
        return days[index - 1]
    }

    /// The local day a server `scheduledDate` refers to: its UTC calendar
    /// date, rebuilt in the local calendar.
    func localDay(fromServer value: WodAiAPI.DateTime?) -> Date? {
        guard let instant = DateParser().parseDate(value) else { return nil }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = utc.dateComponents([.year, .month, .day], from: instant)
        return calendar.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day))
    }

    /// A local day as a query argument: its calendar date at noon UTC. The
    /// server reduces dates to a day in its own time zone, and noon keeps that
    /// on the same date for any server zone within ±11h.
    func serverArgument(for day: Date) -> WodAiAPI.DateTime {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02dT12:00:00.000Z", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
