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

    private func region(_ fatigue: Int, readyIn: Double?, recoveredIn: Double = 72, slug: String = "quadriceps") -> MuscleReadiness.Region {
        .init(
            slug: slug,
            name: slug.capitalized,
            fatigue: fatigue,
            readyAt: readyIn.map { now.addingTimeInterval($0 * 3_600) },
            recoveredAt: now.addingTimeInterval(recoveredIn * 3_600)
        )
    }

    @Test func listsEveryFatiguedRegionMostFatiguedFirst() {
        let readiness = MuscleReadiness(regions: [
            region(12, readyIn: nil, slug: "core"),
            region(72, readyIn: 40, slug: "quadriceps"),
            region(41, readyIn: 10, slug: "glutes"),
        ])
        #expect(readiness.regions.map(\.slug) == ["quadriceps", "glutes", "core"])
    }

    @Test func colorsByWhatThePlanWillDo() {
        #expect(region(12, readyIn: nil).isReady)
        #expect(!region(30, readyIn: 5).isReady)
        #expect(region(61, readyIn: 30).isResting)
        #expect(!region(60, readyIn: 30).isResting)
    }

    @Test func saysWhenARegionIsReadyToTrain() {
        #expect(region(20, readyIn: nil).readyText(now: now, calendar: calendar) == "Ready to train")
        #expect(region(40, readyIn: -1).readyText(now: now, calendar: calendar) == "Ready to train")
        #expect(region(40, readyIn: 6).readyText(now: now, calendar: calendar).hasPrefix("Ready to train by "))
        #expect(region(40, readyIn: 24).readyText(now: now, calendar: calendar) == "Ready to train tomorrow")
        let wednesday = region(70, readyIn: 50).readyText(now: now, calendar: calendar)
        #expect(wednesday == "Ready to train \(now.addingTimeInterval(50 * 3_600).formatted(.dateTime.weekday(.wide)))")
    }

    @Test func saysWhenARegionIsFullyRecovered() {
        #expect(region(5, readyIn: nil, recoveredIn: 4).recoveredText(now: now, calendar: calendar).hasPrefix("Fully recovered by "))
        #expect(region(40, readyIn: 6, recoveredIn: 26).recoveredText(now: now, calendar: calendar) == "Fully recovered tomorrow")
        let thursday = region(70, readyIn: 50, recoveredIn: 75).recoveredText(now: now, calendar: calendar)
        #expect(thursday == "Fully recovered \(now.addingTimeInterval(75 * 3_600).formatted(.dateTime.weekday(.wide)))")
        #expect(region(1, readyIn: nil, recoveredIn: -1).recoveredText(now: now, calendar: calendar) == "Fully recovered")
    }
}
