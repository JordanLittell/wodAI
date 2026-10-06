//
//  StatModelsTests.swift
//  wodAITests
//
//  Coverage for mapping the backend's `stat` results into chart data.
//

import Testing
import Foundation
import Apollo
import WodAiAPI
@testable import wodAI

struct StatModelsTests {

    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    // MARK: - Days

    @Test func parsesTheServerDayAsLocalMidnight() throws {
        let day = try #require(StatFormatting.day(from: "2026-09-28", timeZone: losAngeles))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = losAngeles
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: day)
        #expect(parts == DateComponents(year: 2026, month: 9, day: 28, hour: 0, minute: 0))
    }

    @Test func rejectsAMalformedDay() {
        #expect(StatFormatting.day(from: "Sept 28", timeZone: losAngeles) == nil)
    }

    // MARK: - Shapes

    @Test func sortsCategoriesLargestFirst() {
        let chart = StatChart(unit: "%", total: nil, points: .categorical([
            CategoryValue(label: "Back", value: 24),
            CategoryValue(label: "Legs", value: 38),
            CategoryValue(label: "Core", value: 12),
        ]))
        guard case let .categorical(values) = chart.points else {
            Issue.record("expected categories")
            return
        }
        #expect(values.map(\.label) == ["Legs", "Back", "Core"])
    }

    @Test func aSeriesOfZerosIsEmpty() {
        let day = Date()
        #expect(StatChart(unit: "lb", total: 0, points: .series([DayValue(day: day, value: 0)])).isEmpty)
        #expect(!StatChart(unit: "lb", total: 5, points: .series([DayValue(day: day, value: 5)])).isEmpty)
        #expect(StatChart(unit: "%", total: nil, points: .categorical([])).isEmpty)
    }

    @Test func mapsASeriesResult() throws {
        let fragment = try StatFields(data: [
            "__typename": "SeriesStat",
            "type": "STRENGTH_VOLUME",
            "shape": "SERIES",
            "unit": "lb",
            "total": 1650.0,
            "series": [
                ["__typename": "SeriesPoint", "x": "2026-09-28", "y": 1050.0],
                ["__typename": "SeriesPoint", "x": "2026-09-29", "y": 600.0],
            ],
        ])
        let chart = try #require(StatChart(fragment: fragment, timeZone: losAngeles))
        #expect(chart.unit == "lb")
        #expect(chart.total == 1650)
        guard case let .series(days) = chart.points else {
            Issue.record("expected a series")
            return
        }
        #expect(days.map(\.value) == [1050, 600])
        #expect(days.first?.day == StatFormatting.day(from: "2026-09-28", timeZone: losAngeles))
    }

    @Test func ignoresAShapeThisBuildDoesNotKnow() throws {
        let fragment = try StatFields(data: [
            "__typename": "HeatmapStat",
            "type": "MUSCLE_LOAD",
            "shape": "HEATMAP",
            "unit": "%",
            "total": NSNull(),
        ])
        #expect(StatChart(fragment: fragment, timeZone: losAngeles) == nil)
    }

    // MARK: - Headlines

    private let english = Locale(identifier: "en_US")

    @Test func formatsTotalsByUnit() {
        #expect(StatFormatting.format(42_300, unit: "lb", locale: english) == "42,300 lb")
        #expect(StatFormatting.format(85.6, unit: "min", locale: english) == "86 min")
        #expect(StatFormatting.format(37.6, unit: "%", locale: english) == "38%")
    }

    @Test func headlinesWithTheTotalOrTheTopCategory() {
        let volume = StatChart(unit: "lb", total: 27_350, points: .series([]))
        #expect(volume.headline(locale: english) == "27,350 lb")

        let muscleLoad = StatChart(unit: "%", total: nil, points: .categorical([
            CategoryValue(label: "Back", value: 24),
            CategoryValue(label: "Legs", value: 38),
        ]))
        #expect(muscleLoad.headline(locale: english) == "Mostly Legs")
    }
}
