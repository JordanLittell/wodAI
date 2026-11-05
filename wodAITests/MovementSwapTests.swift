//
//  MovementSwapTests.swift
//  wodAITests
//
//  How a swap suggestion reads in the card's menu: the line as it will be
//  saved, converted for the new movement.
//

import Testing
@testable import wodAI

struct MovementSwapTests {
    private func line(_ name: String, amount: Double?, unit: String, max: Bool = false, load: Double? = nil, loadUnit: String? = nil) -> HIITLine {
        HIITLine(line: 0, partId: nil, exerciseId: 1, name: name, patterns: "", amount: amount,
                 amountUnit: unit, max: max, load: load, loadUnit: loadUnit)
    }

    @Test func labelsShowTheConvertedLine() {
        #expect(SwapOption(preview: line("Row", amount: 21, unit: "cal")).label(repScheme: false) == "Row · 21 Cal")
        #expect(SwapOption(preview: line("Run", amount: 300, unit: "m")).label(repScheme: false) == "Run · 300m")
        #expect(SwapOption(preview: line("Run", amount: nil, unit: "m", max: true)).label(repScheme: false) == "Run · Max m")
    }

    @Test func labelsShowAKeptLoad() {
        let frontSquat = line("Front Squat", amount: 9, unit: "reps", load: 95, loadUnit: "lb")
        #expect(SwapOption(preview: frontSquat).label(repScheme: false) == "Front Squat · 9 reps · 95 lb")
        // Under a 21-15-9 header the reps live in the header.
        #expect(SwapOption(preview: frontSquat).label(repScheme: true) == "Front Squat · 95 lb")
    }
}
