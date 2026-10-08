//
//  StatGuideTests.swift
//  wodAITests
//

import Testing
@testable import wodAI

struct StatGuideTests {
    private let stats = ActivityStats(
        muscleLoad: StatChart(unit: "%", total: nil, points: .categorical([CategoryValue(label: "Legs", value: 100)])),
        volume: StatChart(unit: "lb", total: 1, points: .series([])),
        intensity: StatChart(unit: "min", total: 2, points: .series([])),
        trainingLoad: StatChart(unit: "load", total: 3, points: .series([]))
    )

    @Test func eachKindShowsItsOwnChart() {
        #expect(StatKind.volume.chart(in: stats) == stats.volume)
        #expect(StatKind.intensity.chart(in: stats) == stats.intensity)
        #expect(StatKind.trainingLoad.chart(in: stats) == stats.trainingLoad)
        #expect(StatKind.muscleLoad.chart(in: stats) == stats.muscleLoad)
        #expect(StatKind.volume.chart(in: nil) == nil)
    }

    @Test(arguments: StatKind.allCases)
    func everyKindExplainsEveryTopicOnce(kind: StatKind) {
        #expect(kind.pointers.map(\.topic) == StatPointer.Topic.allCases)
        #expect(kind.pointers.allSatisfy { !$0.text.isEmpty })
        #expect(!kind.definition.isEmpty)
        #expect(!kind.emptyMessage.isEmpty)
    }

    @Test func toggleLabelsAreUnique() {
        let labels = StatKind.allCases.map(\.toggleLabel)
        #expect(Set(labels).count == labels.count)
    }
}
