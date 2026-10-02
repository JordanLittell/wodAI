//
//  AssistantFormattingTests.swift
//  wodAITests
//

import Testing
import Foundation
@testable import wodAI

struct AssistantFormattingTests {

    @Test func blockLettersRunLikeSpreadsheetColumns() {
        #expect(AssistantFormatting.blockLetter(0) == "A")
        #expect(AssistantFormatting.blockLetter(1) == "B")
        #expect(AssistantFormatting.blockLetter(25) == "Z")
        #expect(AssistantFormatting.blockLetter(26) == "AA")
        #expect(AssistantFormatting.blockLetter(27) == "AB")
        #expect(AssistantFormatting.blockLetter(51) == "AZ")
        #expect(AssistantFormatting.blockLetter(52) == "BA")
    }

    @Test func identicalConsecutiveSetsCollapse() {
        let squat = WhiteboardSet(exercise: "Back Squat", reps: 5, weight: 185, rpe: 7)
        #expect(AssistantFormatting.whiteboardLines([squat, squat, squat]) == [
            "Back Squat",
            "  3 × 5 @ 185 lb, RPE 7",
        ])
    }

    @Test func changedLoadStartsANewLine() {
        let lines = AssistantFormatting.whiteboardLines([
            WhiteboardSet(exercise: "Back Squat", reps: 5, weight: 185, rpe: 7),
            WhiteboardSet(exercise: "Back Squat", reps: 5, weight: 185, rpe: 7),
            WhiteboardSet(exercise: "Back Squat", reps: 3, weight: 205.5, rpe: 8),
        ])
        #expect(lines == [
            "Back Squat",
            "  2 × 5 @ 185 lb, RPE 7",
            "  1 × 3 @ \(205.5.formatted()) lb, RPE 8",
        ])
    }

    @Test func missingWeightAndRPEAreOmitted() {
        let lines = AssistantFormatting.whiteboardLines([
            WhiteboardSet(exercise: "Pull-up", reps: 8, weight: nil, rpe: nil),
            WhiteboardSet(exercise: "Pull-up", reps: 8, weight: nil, rpe: 9),
        ])
        #expect(lines == ["Pull-up", "  1 × 8", "  1 × 8, RPE 9"])
    }

    @Test func exercisesGroupInOrderAndRepeatWhenInterleaved() {
        let press = WhiteboardSet(exercise: "Bench Press", reps: 8, weight: 135, rpe: nil)
        let row = WhiteboardSet(exercise: "Barbell Row", reps: 10, weight: 95, rpe: nil)
        #expect(AssistantFormatting.whiteboardLines([press, press, row, press]) == [
            "Bench Press", "  2 × 8 @ 135 lb",
            "Barbell Row", "  1 × 10 @ 95 lb",
            "Bench Press", "  1 × 8 @ 135 lb",
        ])
    }

    @Test func noSetsNoLines() {
        #expect(AssistantFormatting.whiteboardLines([]).isEmpty)
    }
}
