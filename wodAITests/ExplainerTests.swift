//
//  ExplainerTests.swift
//  wodAITests
//

import Testing
@testable import wodAI

struct ExplainerTests {
    @Test(arguments: [Explainer.recovery, Explainer.readiness])
    func explainsInPlainParagraphs(explainer: Explainer) {
        #expect(!explainer.title.isEmpty)
        #expect(explainer.paragraphs.count >= 2)
        #expect(explainer.paragraphs.allSatisfy { !$0.isEmpty })
    }

    @Test func recoveryTitlesCompareWithTheAthletesUsual() {
        let levels: [RecoveryStatus.Level] = [.fresh, .optimal, .elevated, .highStrain]
        for level in levels {
            let status = RecoveryStatus(level: level, ratio: 1, lastHardSessionAt: nil)
            #expect(status.title.hasSuffix("usual"))
            #expect(!status.message.localizedCaseInsensitiveContains("injur"))
        }
    }

    @Test func chartsCarryTheirProvenance() {
        let chart = StatChart(unit: "load", total: 30, points: .series([]), provenance: "From your effort rating for 1 workout.")
        #expect(chart.provenance == "From your effort rating for 1 workout.")
        #expect(StatChart(unit: "lb", total: 0, points: .series([])).provenance == nil)
    }
}
