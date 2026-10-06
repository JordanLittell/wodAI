//
//  BlockPagerTests.swift
//  wodAITests
//
//  The block pager's dot states, swipe neighbours, and HIIT completion.
//

import Testing
import Foundation
import Apollo
import WodAiAPI
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
        #expect(viewModel.openableBlocks(in: sessionId).map(\.id) == [0, 2])
    }

    @Test func savingAHiitResultCompletesOnlyThatBlock() {
        let viewModel = viewModelWithBlocks()
        let blocks = { viewModel.session(id: sessionId)?.blocks ?? [] }
        #expect(!blocks()[2].isCompleted)

        viewModel.markHiitCompleted(sessionId: sessionId, blockId: 2)
        #expect(blocks()[2].isCompleted)
        #expect(!blocks()[0].isCompleted)

        // Not a HIIT block: ignored.
        viewModel.markHiitCompleted(sessionId: sessionId, blockId: 0)
        #expect(!blocks()[0].isCompleted)
    }

    // MARK: - Server completion

    @Test func hiitPieceCompletionFromTheServerSurvivesAReload() throws {
        let session = AssistantViewModel.session(from: try sessionDetails(pieces: [
            (id: 41, order: 0, completion: ["__typename": "CompletedHIITWorkout", "id": 7, "completedAt": "2026-10-05T15:00:00.000Z"]),
            (id: 42, order: 1, completion: nil),
        ]))

        #expect(session.blocks.map(\.hiitPieceId) == [41, 42])
        #expect(session.blocks.map(\.isCompleted) == [true, false])
    }

    /// A SessionDetails as the server sends it, with one HIIT piece per entry.
    private func sessionDetails(pieces: [(id: Int, order: Int, completion: [String: Any]?)]) throws -> SessionDetails {
        let blocks: [[String: Any]] = pieces.map { piece in
            [
                "__typename": "WorkoutHiitPiece",
                "order": piece.order,
                "id": piece.id,
                "completion": piece.completion ?? NSNull(),
                "hiitWorkout": [
                    "__typename": "HIITWorkout", "id": 1, "name": "Fran", "format": "For Time",
                    "stimulus": "", "displayText": "21-15-9", "constraintType": "time",
                    "constraintMagnitude": 1, "timeCap": NSNull(), "timingScheme": NSNull(),
                ] as [String: Any],
            ]
        }
        return try SessionDetails(data: [
            "__typename": "Workout", "id": "w1", "name": "Day", "description": "",
            "stimulus": NSNull(), "coaching": NSNull(), "scheduledDate": "2026-10-05",
            "source": "GENERATED", "blocks": blocks,
        ])
    }

    private let sessionId = "w1"

    private func viewModelWithBlocks() -> AssistantViewModel {
        AssistantViewModel(session: AssistantSession(
            id: sessionId, name: "Day", description: "", stimulus: nil, coaching: nil, scheduledDate: nil,
            blocks: blocks
        ))
    }
}
