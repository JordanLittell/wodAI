//
//  ActivityWeek.swift
//  wodAI
//
//  Pure, Apollo-free week math for the Activity screen's week selector.
//

import Foundation

struct ActivityWeek: Equatable {
    /// Half-open interval: `start` is the first instant of the week, `end` the first instant of the next.
    let interval: DateInterval
    let calendar: Calendar

    init(containing date: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        self.interval = calendar.dateInterval(of: .weekOfYear, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 7 * 24 * 60 * 60)
    }

    var start: Date { interval.start }
    var end: Date { interval.end }

    /// Last calendar day of the week (for display; `end` itself belongs to the next week).
    var lastDay: Date { end.addingTimeInterval(-1) }

    func shifted(by weeks: Int) -> ActivityWeek {
        let anchor = calendar.date(byAdding: .weekOfYear, value: weeks, to: start) ?? start
        return ActivityWeek(containing: anchor, calendar: calendar)
    }

    func contains(_ date: Date) -> Bool {
        start <= date && date < end
    }

    /// True when this week is the one containing `now`, or later — used to stop forward navigation.
    func isCurrentOrFuture(relativeTo now: Date) -> Bool {
        end > now
    }

    /// e.g. "Sep 28 – Oct 4", or "Dec 29, 2025 – Jan 4, 2026" when the week isn't entirely in `now`'s year.
    func label(relativeTo now: Date = Date()) -> String {
        let currentYear = calendar.component(.year, from: now)
        let inCurrentYear = calendar.component(.year, from: start) == currentYear
            && calendar.component(.year, from: lastDay) == currentYear

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(inCurrentYear ? "MMMd" : "MMMdyyyy")

        return "\(formatter.string(from: start)) – \(formatter.string(from: lastDay))"
    }
}
