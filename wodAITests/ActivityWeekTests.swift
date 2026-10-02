//
//  ActivityWeekTests.swift
//  wodAITests
//
//  Unit coverage for the Activity screen's week selector math.
//

import Testing
import Foundation
@testable import wodAI

struct ActivityWeekTests {

    /// Monday-first Gregorian calendar in UTC with a fixed locale, so results don't depend on the machine.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // MARK: - Snapping

    @Test func midWeekDateSnapsToMonday() {
        // Thu Oct 1 2026 → week of Mon Sep 28.
        let week = ActivityWeek(containing: date(2026, 10, 1, hour: 15), calendar: calendar)
        #expect(week.start == date(2026, 9, 28))
        #expect(week.end == date(2026, 10, 5))
    }

    @Test func exactWeekStartStaysInItsOwnWeek() {
        let week = ActivityWeek(containing: date(2026, 9, 28), calendar: calendar)
        #expect(week.start == date(2026, 9, 28))
    }

    // MARK: - Containment

    @Test func containsIsHalfOpen() {
        let week = ActivityWeek(containing: date(2026, 10, 1), calendar: calendar)
        #expect(week.contains(date(2026, 9, 28)))
        #expect(week.contains(week.end.addingTimeInterval(-1)))
        #expect(!week.contains(week.end))
        #expect(!week.contains(week.start.addingTimeInterval(-1)))
    }

    // MARK: - Navigation

    @Test func shiftingProducesAdjacentWeeks() {
        let week = ActivityWeek(containing: date(2026, 10, 1), calendar: calendar)
        let previous = week.shifted(by: -1)
        let next = week.shifted(by: 1)
        #expect(previous.end == week.start)
        #expect(next.start == week.end)
        #expect(previous.shifted(by: 1) == week)
    }

    @Test func shiftingAcrossYearBoundary() {
        // Mon Jan 5 2026 → previous week is Mon Dec 29 2025 – Sun Jan 4 2026.
        let week = ActivityWeek(containing: date(2026, 1, 5), calendar: calendar)
        let previous = week.shifted(by: -1)
        #expect(previous.start == date(2025, 12, 29))
        #expect(previous.end == date(2026, 1, 5))
    }

    @Test func currentOrFutureDetection() {
        let now = date(2026, 10, 1, hour: 12)
        let current = ActivityWeek(containing: now, calendar: calendar)
        #expect(current.isCurrentOrFuture(relativeTo: now))
        #expect(current.shifted(by: 1).isCurrentOrFuture(relativeTo: now))
        #expect(!current.shifted(by: -1).isCurrentOrFuture(relativeTo: now))
    }

    // MARK: - Label

    @Test func labelOmitsYearWithinCurrentYear() {
        let now = date(2026, 10, 1)
        let week = ActivityWeek(containing: now, calendar: calendar)
        #expect(week.label(relativeTo: now) == "Sep 28 – Oct 4")
    }

    @Test func labelIncludesYearAcrossYearBoundary() {
        let now = date(2026, 10, 1)
        let week = ActivityWeek(containing: date(2026, 1, 1), calendar: calendar)
        #expect(week.label(relativeTo: now) == "Dec 29, 2025 – Jan 4, 2026")
    }
}
