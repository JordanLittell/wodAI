//
//  StrengthWorkoutSyncTests.swift
//  wodAITests
//

import Testing
import Foundation
@testable import wodAI

/// Records every write and fails the calls listed in `failing` (by call
/// number, starting at 0).
@MainActor
private final class FakeSync: StrengthCompletionSyncing {
    enum Call: Equatable {
        case complete(pieceId: Int, sets: [StrengthSetResult])
        case uncomplete(pieceId: Int, componentIds: [Int])
    }

    struct Failure: Error {}

    private(set) var calls: [Call] = []
    var failing: Set<Int> = []

    func complete(strengthWorkoutId: Int, sets: [StrengthSetResult]) async throws {
        try record(.complete(pieceId: strengthWorkoutId, sets: sets))
    }

    func uncomplete(strengthWorkoutId: Int, componentIds: [Int]) async throws {
        try record(.uncomplete(pieceId: strengthWorkoutId, componentIds: componentIds))
    }

    private func record(_ call: Call) throws {
        let number = calls.count
        calls.append(call)
        if failing.contains(number) { throw Failure() }
    }
}

@MainActor
struct StrengthWorkoutSyncTests {
    private let squat = ExerciseName(name: "Back Squat")

    private func makeStore() -> ExerciseStatsStore {
        let suite = "StrengthWorkoutSyncTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return ExerciseStatsStore(defaults: defaults)
    }

    /// A saved block: piece 42 with sets 100, 101, 102 at 3 × 5 @ 225.
    private func savedBlock(completed: [Int: CompletedSet] = [:]) -> StrengthWorkout {
        StrengthWorkout(
            id: 0,
            name: "Squat",
            instructions: "",
            components: (0..<3).map {
                StrengthComponent(order: $0, reps: 5, weight: 225, rpe: nil, exercise: squat,
                                  id: 100 + $0, completed: completed[$0])
            },
            serverId: 42
        )
    }

    @Test func loggingASavedSetSendsItsResult() async {
        let sync = FakeSync()
        let viewModel = StrengthWorkoutViewModel(workout: savedBlock(), stats: makeStore(), sync: sync)

        viewModel.log(1, weight: 235, reps: 4)
        await viewModel.waitForPendingWrites()

        #expect(sync.calls == [.complete(pieceId: 42, sets: [
            StrengthSetResult(componentId: 101, reps: 4, weight: 235, rpe: nil),
        ])])
        #expect(viewModel.completed[1] == CompletedSet(weightUsed: 235, reps: 4))
        #expect(viewModel.syncError == nil)
    }

    @Test func uncheckingSendsUndo() async {
        let sync = FakeSync()
        let viewModel = StrengthWorkoutViewModel(workout: savedBlock(), stats: makeStore(), sync: sync)

        viewModel.toggleComplete(0)
        viewModel.toggleComplete(0)
        await viewModel.waitForPendingWrites()

        #expect(sync.calls == [
            .complete(pieceId: 42, sets: [StrengthSetResult(componentId: 100, reps: 5, weight: 225, rpe: nil)]),
            .uncomplete(pieceId: 42, componentIds: [100]),
        ])
        #expect(viewModel.completed[0] == nil)
    }

    @Test func failedSaveRollsBackAndReports() async {
        let sync = FakeSync()
        sync.failing = [0]
        let viewModel = StrengthWorkoutViewModel(workout: savedBlock(), stats: makeStore(), sync: sync)

        viewModel.log(0, weight: 225, reps: 5)
        #expect(viewModel.completed[0] != nil) // optimistic
        await viewModel.waitForPendingWrites()

        #expect(viewModel.completed[0] == nil)
        #expect(viewModel.syncError != nil)
        #expect(viewModel.currentIndex == 0)
    }

    @Test func failedUndoRestoresTheLoggedSet() async {
        let sync = FakeSync()
        sync.failing = [0]
        let logged = CompletedSet(weightUsed: 230, reps: 5)
        let viewModel = StrengthWorkoutViewModel(workout: savedBlock(completed: [0: logged]), stats: makeStore(), sync: sync)

        viewModel.toggleComplete(0)
        await viewModel.waitForPendingWrites()

        #expect(viewModel.completed[0] == logged)
        #expect(viewModel.entry(for: 0) == SetEntry(weight: 230, reps: 5))
    }

    @Test func slowFailureDoesNotClobberALaterTap() async {
        let sync = FakeSync()
        sync.failing = [0]
        let viewModel = StrengthWorkoutViewModel(
            workout: savedBlock(completed: [0: CompletedSet(weightUsed: 230, reps: 5)]),
            stats: makeStore(),
            sync: sync
        )

        viewModel.toggleComplete(0)              // undo: fails
        viewModel.log(0, weight: 240, reps: 5)   // re-log before the failure lands
        await viewModel.waitForPendingWrites()

        #expect(viewModel.completed[0] == CompletedSet(weightUsed: 240, reps: 5))
    }

    @Test func successClearsAnEarlierError() async {
        let sync = FakeSync()
        sync.failing = [0]
        let viewModel = StrengthWorkoutViewModel(workout: savedBlock(), stats: makeStore(), sync: sync)

        viewModel.log(0, weight: 225, reps: 5)
        await viewModel.waitForPendingWrites()
        viewModel.log(0, weight: 225, reps: 5)
        await viewModel.waitForPendingWrites()

        #expect(viewModel.syncError == nil)
        #expect(viewModel.completed[0] != nil)
    }

    @Test func reloggingKeepsAServerRecordedRpe() async {
        let sync = FakeSync()
        let viewModel = StrengthWorkoutViewModel(
            workout: savedBlock(completed: [0: CompletedSet(weightUsed: 225, reps: 5, rpe: 8)]),
            stats: makeStore(),
            sync: sync
        )

        viewModel.log(0, weight: 230, reps: 5)
        await viewModel.waitForPendingWrites()

        #expect(sync.calls == [.complete(pieceId: 42, sets: [
            StrengthSetResult(componentId: 100, reps: 5, weight: 230, rpe: 8),
        ])])
    }

    @Test func streamedBlockStaysLocal() async {
        let sync = FakeSync()
        let streamed = StrengthWorkout(id: 0, name: "Squat", instructions: "", components: [
            StrengthComponent(order: 0, reps: 5, weight: 225, rpe: nil, exercise: squat),
        ])
        let viewModel = StrengthWorkoutViewModel(workout: streamed, stats: makeStore(), sync: sync)

        viewModel.toggleComplete(0)
        await viewModel.waitForPendingWrites()

        #expect(sync.calls.isEmpty)
        #expect(viewModel.completed[0] != nil)
    }

    /// The bug this guards: a block opened mid-generation logged sets locally
    /// and never sent them once the session was saved.
    @Test func setsLoggedWhileStreamingAreSentOnceSaved() async {
        let sync = FakeSync()
        let streamed = StrengthWorkout(id: 0, name: "Squat", instructions: "", components: (0..<3).map {
            StrengthComponent(order: $0, reps: 5, weight: 225, rpe: nil, exercise: squat)
        })
        let viewModel = StrengthWorkoutViewModel(workout: streamed, stats: makeStore(), sync: sync)

        viewModel.log(0, weight: 230, reps: 5)
        viewModel.log(2, weight: 235, reps: 4)
        await viewModel.waitForPendingWrites()
        #expect(sync.calls.isEmpty)

        viewModel.adoptSaved(savedBlock())
        await viewModel.waitForPendingWrites()
        #expect(sync.calls == [.complete(pieceId: 42, sets: [
            StrengthSetResult(componentId: 100, reps: 5, weight: 230, rpe: nil),
            StrengthSetResult(componentId: 102, reps: 4, weight: 235, rpe: nil),
        ])])

        // And later taps go straight to the server.
        viewModel.toggleComplete(1)
        await viewModel.waitForPendingWrites()
        #expect(sync.calls.last == .complete(pieceId: 42, sets: [
            StrengthSetResult(componentId: 101, reps: 5, weight: 225, rpe: nil),
        ]))
    }

    @Test func adoptingAMismatchedBlockReportsInsteadOfGuessing() async {
        let sync = FakeSync()
        let streamed = StrengthWorkout(id: 0, name: "Squat", instructions: "", components: [
            StrengthComponent(order: 0, reps: 5, weight: 225, rpe: nil, exercise: squat),
        ])
        let viewModel = StrengthWorkoutViewModel(workout: streamed, stats: makeStore(), sync: sync)

        viewModel.log(0, weight: 225, reps: 5)
        viewModel.adoptSaved(savedBlock()) // 3 sets vs 1
        await viewModel.waitForPendingWrites()

        #expect(sync.calls.isEmpty)
        #expect(viewModel.syncError != nil)
    }

    @Test func blockIsCompletedOnlyOnceEverySetIsLogged() async {
        var reported: StrengthWorkout?
        let viewModel = StrengthWorkoutViewModel(
            workout: savedBlock(),
            stats: makeStore(),
            sync: FakeSync(),
            onChange: { reported = $0 }
        )

        viewModel.log(0, weight: 225, reps: 5)
        viewModel.log(1, weight: 225, reps: 5)
        await viewModel.waitForPendingWrites()
        #expect(reported?.isCompleted == false)

        viewModel.log(2, weight: 225, reps: 3)
        await viewModel.waitForPendingWrites()
        #expect(reported?.isCompleted == true)

        viewModel.toggleComplete(1)
        await viewModel.waitForPendingWrites()
        #expect(reported?.isCompleted == false)
    }

    @Test func emptyBlockIsNeverCompleted() {
        #expect(!StrengthWorkout(id: 0, name: "Empty", instructions: "", components: []).isCompleted)
    }

    @Test func seedsLoggedSetsFromTheServer() {
        let viewModel = StrengthWorkoutViewModel(
            workout: savedBlock(completed: [
                0: CompletedSet(weightUsed: 235, reps: 5),
                1: CompletedSet(weightUsed: 235, reps: 3),
            ]),
            stats: makeStore(),
            sync: FakeSync()
        )

        #expect(viewModel.currentIndex == 2)
        #expect(viewModel.entry(for: 1) == SetEntry(weight: 235, reps: 3))
    }

    @Test func savedSetsAreReportedToTheOwner() async {
        var reported: StrengthWorkout?
        let viewModel = StrengthWorkoutViewModel(
            workout: savedBlock(),
            stats: makeStore(),
            sync: FakeSync(),
            onChange: { reported = $0 }
        )

        viewModel.log(2, weight: 245, reps: 5)
        await viewModel.waitForPendingWrites()

        #expect(reported?.components[2].completed == CompletedSet(weightUsed: 245, reps: 5))
        #expect(reported?.components[0].completed == nil)
        #expect(reported?.serverId == 42)
    }
}
