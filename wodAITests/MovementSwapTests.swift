//
//  MovementSwapTests.swift
//  wodAITests
//
//  How a swap suggestion reads in the card's menu (the line as it will be
//  saved, converted for the new movement), and how an adjusted line reads
//  before the server answers.
//

import Testing
@testable import wodAI

struct MovementSwapTests {
    private func line(_ name: String, amount: Double?, unit: String, max: Bool = false, load: Double? = nil, loadUnit: String? = nil, loads: [String] = []) -> HIITLine {
        HIITLine(line: 0, partId: nil, exerciseId: 1, name: name, patterns: "", amount: amount,
                 amountUnit: unit, max: max, load: load, loadUnit: loadUnit, loads: loads)
    }

    @Test func labelsShowTheConvertedLine() {
        #expect(SwapOption(preview: line("Row", amount: 21, unit: "cal")).label == "Row · 21 Cal")
        #expect(SwapOption(preview: line("Run", amount: 300, unit: "m")).label == "Run · 300m")
        #expect(SwapOption(preview: line("Run", amount: nil, unit: "m", max: true)).label == "Run · Max m")
    }

    @Test func labelsShowAKeptLoad() {
        let frontSquat = line("Front Squat", amount: 9, unit: "reps", load: 95, loadUnit: "lb")
        #expect(SwapOption(preview: frontSquat).label == "Front Squat · 9 reps · 95 lb")
    }

    @Test func everyRoundShowsItsOwnCount() {
        // A 21-15-9 is stored round by round, so a reps line always shows its count.
        #expect(line("Thruster", amount: 15, unit: "reps").amountText == "15")
    }

    @Test func adjustingKeepsTheUnitsWritten() {
        let thrusters = line("Thruster", amount: 21, unit: "reps", load: 43, loadUnit: "kg", loads: ["weight"])
        let adjusted = thrusters.adjusted(amount: 15, load: 32.5)
        #expect(adjusted.amount == 15 && adjusted.amountUnit == "reps")
        #expect(adjusted.loadText == "32.5 kg")
    }

    @Test func aLoadAddedTakesLbOrInches() {
        #expect(line("Thruster", amount: 9, unit: "reps", loads: ["weight"]).adjusted(load: 65).loadText == "65 lb")
        #expect(line("Box Jump", amount: 10, unit: "reps", loads: ["height"]).adjusted(load: 24).loadText == "24 in")
    }

    @Test func clearingALoadRemovesItsUnit() {
        let cleared = line("Thruster", amount: 9, unit: "reps", load: 95, loadUnit: "lb", loads: ["weight"]).adjusted(clearLoad: true)
        #expect(cleared.load == nil && cleared.loadUnit == nil && cleared.loadText == nil)
    }

    @Test func onlyMovementsThatTakeALoadOfferOne() {
        #expect(line("Thruster", amount: 9, unit: "reps", loads: ["weight"]).takesLoad)
        #expect(!line("Burpee", amount: 9, unit: "reps").takesLoad)
        // A load already written stays adjustable, whatever the movement says.
        #expect(line("Burpee", amount: 9, unit: "reps", load: 20, loadUnit: "lb").takesLoad)
    }
}
