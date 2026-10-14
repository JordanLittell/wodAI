//
//  MuscleReadinessTests.swift
//  wodAITests
//

import Foundation
import Testing
@testable import wodAI

struct MuscleReadinessTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        return calendar
    }

    /// Monday 9am in Denver.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 9))!
    }

    private func region(_ fatigue: Int, readyIn hours: Double?) -> MuscleReadiness.Region {
        .init(slug: "quadriceps", name: "Quadriceps", fatigue: fatigue, readyAt: hours.map { now.addingTimeInterval($0 * 3_600) })
    }

    @Test func showsOnlyRegionsNotYetReady() {
        let readiness = MuscleReadiness(regions: [
            .init(slug: "quadriceps", name: "Quadriceps", fatigue: 72, readyAt: nil),
            .init(slug: "glutes", name: "Glutes", fatigue: 30, readyAt: nil),
            .init(slug: "core", name: "Core", fatigue: 29, readyAt: nil),
        ])
        #expect(readiness.recovering.map(\.slug) == ["quadriceps", "glutes"])
    }

    @Test func restsOnlyAboveSixty() {
        #expect(region(61, readyIn: 30).isResting)
        #expect(!region(60, readyIn: 30).isResting)
    }

    @Test func saysWhenARegionIsReady() {
        #expect(region(40, readyIn: nil).readyText(now: now, calendar: calendar) == "Ready")
        #expect(region(40, readyIn: -1).readyText(now: now, calendar: calendar) == "Ready")
        #expect(region(40, readyIn: 6).readyText(now: now, calendar: calendar).hasPrefix("Ready by "))
        #expect(region(40, readyIn: 24).readyText(now: now, calendar: calendar) == "Ready tomorrow")
        let wednesday = region(70, readyIn: 50).readyText(now: now, calendar: calendar)
        #expect(wednesday == "Ready \(now.addingTimeInterval(50 * 3_600).formatted(.dateTime.weekday(.wide)))")
    }
}
