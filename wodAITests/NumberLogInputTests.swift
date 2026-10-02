//
//  NumberLogInputTests.swift
//  wodAITests
//

import Testing
import Foundation
@testable import wodAI

struct NumberLogInputTests {

    // MARK: - Typing

    @Test func firstKeyReplacesPrefillThenAppends() {
        var input = NumberLogInput(text: "185", allowsDecimal: true)
        input.press(2)
        #expect(input.text == "2")
        input.press(0)
        input.press(5)
        #expect(input.text == "205")
        #expect(input.value == 205)
    }

    @Test func deleteOnPrefillClearsIt() {
        var input = NumberLogInput(text: "185", allowsDecimal: true)
        input.delete()
        #expect(input.text == "")
        #expect(input.value == nil)
    }

    @Test func deleteAfterTypingRemovesLastCharacter() {
        var input = NumberLogInput(text: "", allowsDecimal: false)
        input.press(1)
        input.press(2)
        input.delete()
        #expect(input.text == "1")
    }

    @Test func decimalIsWeightOnlyAndOnlyOnce() {
        var reps = NumberLogInput(text: "5", allowsDecimal: false)
        reps.pressDecimal()
        #expect(reps.text == "5")   // ignored outright; the prefill is untouched
        reps.press(8)
        reps.pressDecimal()
        #expect(reps.text == "8")

        var weight = NumberLogInput(text: "", allowsDecimal: true)
        weight.press(2)
        weight.pressDecimal()
        weight.pressDecimal()
        weight.press(5)
        #expect(weight.text == "2.5")
    }

    @Test func leadingDecimalBecomesZeroPoint() {
        var input = NumberLogInput(text: "", allowsDecimal: true)
        input.pressDecimal()
        #expect(input.text == "0.")
        #expect(input.value == 0)
    }

    @Test func trailingDecimalStillReadsAsTheNumber() {
        var input = NumberLogInput(text: "", allowsDecimal: true)
        input.press(9)
        input.press(5)
        input.pressDecimal()
        #expect(input.value == 95)
    }

    @Test func noLeadingZeros() {
        var input = NumberLogInput(text: "", allowsDecimal: false)
        input.press(0)
        input.press(0)
        input.press(7)
        #expect(input.text == "7")
    }

    @Test func lengthCaps() {
        var reps = NumberLogInput(text: "", allowsDecimal: false)
        for digit in [1, 2, 3, 4] { reps.press(digit) }
        #expect(reps.text == "123")

        var weight = NumberLogInput(text: "", allowsDecimal: true)
        weight.press(2)
        weight.pressDecimal()
        for digit in [5, 5, 5] { weight.press(digit) }
        #expect(weight.text == "2.55")   // two decimal places at most
    }

    // MARK: - Units

    @Test func kilogramsRoundTripThroughPounds() {
        let pounds = WeightUnit.kg.toPounds(100)
        #expect(abs(pounds - 220.462) < 0.001)
        #expect(abs(WeightUnit.kg.fromPounds(pounds) - 100) < 0.01)
        #expect(WeightUnit.lb.toPounds(185) == 185)
    }

    @Test func formatting() {
        #expect(WeightUnit.lb.inputText(185) == "185")
        #expect(WeightUnit.kg.inputText(185) == "83.9")
        #expect(WeightUnit.lb.inputText(202.5) == "202.5")
    }

    // MARK: - View model

    @MainActor
    @Test func logChecksOffAndNextSkipsDoneSets() {
        let squat = ExerciseName(name: "Back Squat")
        let viewModel = StrengthWorkoutViewModel(workout: StrengthWorkout(
            id: 1, name: "Back Squat", instructions: "",
            components: (0..<3).map { StrengthComponent(order: $0, reps: 5, weight: 185, rpe: nil, exercise: squat) }
        ))

        viewModel.log(1, weight: 190, reps: 4)
        #expect(viewModel.completed[1] == CompletedSet(weightUsed: 190, reps: 4))
        #expect(viewModel.entry(for: 1) == SetEntry(weight: 190, reps: 4))

        viewModel.log(0, weight: 185, reps: 5)
        #expect(viewModel.nextIncomplete(after: 0) == 2)   // skips the done set 1

        viewModel.log(2, weight: 185, reps: 5)
        #expect(viewModel.nextIncomplete(after: 2) == nil)
        #expect(viewModel.isFinished)
    }

    @MainActor
    @Test func logIgnoresZeroReps() {
        let viewModel = StrengthWorkoutViewModel(workout: StrengthWorkout(
            id: 1, name: "Pull-up", instructions: "",
            components: [StrengthComponent(order: 0, reps: 8, weight: nil, rpe: nil, exercise: ExerciseName(name: "Pull-up"))]
        ))
        viewModel.log(0, weight: nil, reps: 0)
        #expect(viewModel.completed[0] == nil)
    }
}
