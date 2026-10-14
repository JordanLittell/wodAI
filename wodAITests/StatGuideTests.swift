//
//  StatGuideTests.swift
//  wodAITests
//

import Testing
@testable import wodAI

struct StatGuideTests {
    private let stats = ActivityStats(
        volume: StatChart(unit: "lb", total: 1, points: .series([])),
        intensity: StatChart(unit: "min", total: 2, points: .series([])),
        trainingLoad: StatChart(unit: "load", total: 3, points: .series([]))
    )

    @Test func eachKindShowsItsOwnChart() {
        #expect(StatKind.volume.chart(in: stats) == stats.volume)
        #expect(StatKind.intensity.chart(in: stats) == stats.intensity)
        #expect(StatKind.trainingLoad.chart(in: stats) == stats.trainingLoad)
        #expect(StatKind.recovery.chart(in: stats) == nil)
        #expect(StatKind.volume.chart(in: nil) == nil)
    }

    @Test(arguments: StatKind.allCases)
    func everyKindIsDescribed(kind: StatKind) {
        #expect(!kind.definition.isEmpty)
        #expect(!kind.emptyMessage.isEmpty)
    }

    @Test func toggleLabelsAreUnique() {
        let labels = StatKind.allCases.map(\.toggleLabel)
        #expect(Set(labels).count == labels.count)
    }
}
