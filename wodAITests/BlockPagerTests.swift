//
//  BlockPagerTests.swift
//  wodAITests
//
//  The block pager's dot states, swipe neighbours, and HIIT completion.
//

import Testing
import Foundation
@testable import wodAI

@MainActor
struct BlockPagerTests {
    private let hiit = HIITWorkoutItem(
        id: 1, format: "AMRAP 12", displayText: "12 Cal Row", stimulus: "",
        constraintType: "time", constraintMagnitude: 720, timeCap: 720,
        timingScheme: nil, tags: []
    )

    private func strength(_ id: Int) -> AssistantBlock {
        AssistantBlock(id: id, label: "S", letter: "A", kind: .strength(
            StrengthWorkout(id: id, name: "Squat", instructions: "", components: [
                StrengthComponent(order: 0, reps: 5, weight: nil, rpe: nil, exercise: ExerciseName(name: "Back Squat"))
            ])
        ))
    }

    private var blocks: [AssistantBlock] {
        [
            strength(0),
            AssistantBlock(id: 1, label: "Other", letter: "B", kind: .other),
            AssistantBlock(id: 2, label: "Metcon", letter: "C", kind: .hiit(hiit)),
        ]
    }

    // MARK: - Dots

    @Test func currentWinsOverCompleted() {
        #expect(BlockDotState(isCurrent: true, isCompleted: true) == .current)
        #expect(BlockDotState(isCurrent: true, isCompleted: false) == .current)
        #expect(BlockDotState(isCurrent: false, isCompleted: true) == .completed)
        #expect(BlockDotState(isCurrent: false, isCompleted: false) == .upcoming)
    }

    // MARK: - Navigation

    @Test func neighboursStopAtEitherEnd() {
        let openable = blocks.filter(\.isOpenable)
        #expect(BlockNavigation.neighbor(of: 0, in: openable, forward: true) == 2)
        #expect(BlockNavigation.neighbor(of: 2, in: openable, forward: false) == 0)
        #expect(BlockNavigation.neighbor(of: 2, in: openable, forward: true) == nil)
        #expect(BlockNavigation.neighbor(of: 0, in: openable, forward: false) == nil)
        #expect(BlockNavigation.neighbor(of: 99, in: openable, forward: true) == nil)
    }

    // MARK: - Metcon title

    @Test func namedMetconUsesItsName() {
        var fran = hiit
        fran.name = "Fran"
        #expect(fran.title == "Fran")
    }

    @Test func unnamedOrBlankMetconFallsBackToMetcon() {
        #expect(hiit.title == "Metcon")
        var blank = hiit
        blank.name = "   "
        #expect(blank.title == "Metcon")
    }

    // MARK: - View model

    @Test func pagerSkipsBlocksThatCantOpen() {
        let viewModel = viewModelWithBlocks()
        #expect(viewModel.openableBlocks.map(\.id) == [0, 2])
    }

    @Test func savingAHiitResultCompletesOnlyThatBlock() {
        let viewModel = viewModelWithBlocks()
        #expect(!(viewModel.session?.blocks[2].isCompleted ?? true))

        viewModel.markHiitCompleted(blockId: 2)
        #expect(viewModel.session?.blocks[2].isCompleted == true)
        #expect(viewModel.session?.blocks[0].isCompleted == false)

        // Not a HIIT block: ignored.
        viewModel.markHiitCompleted(blockId: 0)
        #expect(viewModel.session?.blocks[0].isCompleted == false)
    }

    private func viewModelWithBlocks() -> AssistantViewModel {
        AssistantViewModel(session: AssistantSession(
            name: "Day", description: "", stimulus: nil, coaching: nil, scheduledDate: nil,
            blocks: blocks
        ))
    }
}
