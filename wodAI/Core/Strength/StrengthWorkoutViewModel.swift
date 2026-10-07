//
//  StrengthWorkoutViewModel.swift
//  wodAI
//
//  Created by Jordan Littell on 9/28/26.
//

import Foundation
import SwiftUI
import Combine
import Apollo
import WodAiAPI


struct StrengthWorkout: Identifiable, Hashable {
    /// Identity within the session (stable across streaming → saved).
    let id: Int
    let name: String
    let instructions: String
    var components: [StrengthComponent]
    /// The server's StrengthWorkout id. Nil while the block is still streaming
    /// and unsaved, in which case completion stays local.
    var serverId: Int? = nil

    /// Every set has a logged result. An empty block is never complete.
    var isCompleted: Bool {
        !components.isEmpty && components.allSatisfy { $0.completed != nil }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StrengthWorkout, rhs: StrengthWorkout) -> Bool {
        lhs.id == rhs.id
    }
}

struct StrengthComponent: Hashable {
    let order: Int
    let reps: Int
    let weight: Double?
    let rpe: Int?
    let exercise: ExerciseName
    /// The server's StrengthComponent id; nil for a streamed, unsaved set.
    var id: Int? = nil
    /// What the athlete logged on the server, if anything.
    var completed: CompletedSet? = nil
    
    func hasEffort() -> Bool {
        weight != nil || rpe != nil
    }
    
    func getEffort() -> Int? {
        if let weight = weight {
            return Int(weight)
        } else if let rpe = rpe {
            return rpe as Int
        } else {
            return nil
        }
    }
}

struct ExerciseName: Hashable {
    let name: String
    /// Display-ready target muscles, e.g. ["Quads", "Glutes"]. Empty when unknown.
    var muscleGroups: [String] = []
    /// How-to demo video (YouTube today, maybe self-hosted later). Nil when none.
    var videoURL: URL? = nil

    /// The catalog stores muscle groups as one comma-separated string
    /// ("quads, glutes"); split and title-case it for display.
    static func muscleGroups(fromCatalog value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
            .filter { !$0.isEmpty }
    }
}

/// What the athlete says they lifted on one set. Starts out as the
/// prescription and is edited in place when they go lighter, heavier, or fall
/// short on reps.
struct SetEntry: Equatable {
    /// Nil for bodyweight or when left blank.
    var weight: Double?
    /// Nil while the field is cleared mid-edit; a set can't be logged without it.
    var reps: Int?
}

/// A set the athlete has marked done, with what they actually did.
struct CompletedSet: Hashable {
    let weightUsed: Double?
    let reps: Int
    /// Not entered in the app today, but kept so re-logging a set doesn't
    /// erase an RPE recorded elsewhere (e.g. via the MCP tools).
    var rpe: Int? = nil
}

/// Tracks set-by-set progress through one strength block. Sets are addressed
/// by their index in `sets`: `order` isn't guaranteed unique, and two sets
/// with identical prescriptions are still different sets.
///
/// Completion is saved to the server optimistically: the set is checked at
/// once and the `completeStrengthComponents` / `uncompleteStrengthComponents`
/// mutation follows. If it fails the set is rolled back and `syncError` says
/// so, so the athlete can tap again.
///
/// A block opened while the session is still streaming has no server ids yet.
/// Its sets are held locally until `adoptSaved` delivers the saved block, then
/// sent in one batch.
@MainActor
final class StrengthWorkoutViewModel: ObservableObject {
    private(set) var sets: [StrengthComponent]
    @Published private(set) var completed: [Int: CompletedSet] = [:]
    /// Entries the athlete has typed into. Untouched sets have no draft and
    /// show `defaultEntry`, so their prefill can follow earlier sets.
    @Published private var drafts: [Int: SetEntry] = [:]
    /// Set when a save or undo failed and was rolled back; cleared by the next
    /// successful write.
    @Published private(set) var syncError: String?

    private var workout: StrengthWorkout
    private let stats: ExerciseStatsStore
    /// Test seam. Nil (the app) sends the Apollo mutations directly.
    private let sync: StrengthCompletionSyncing?
    /// Called after each successful write with the block's current state, so
    /// the owner can keep its copy fresh for when the block is reopened.
    private let onChange: ((StrengthWorkout) -> Void)?
    /// Writes run one after another so a quick check → un-check reaches the
    /// server in the order it was tapped.
    private var pending: Task<Void, Never>?
    /// Bumped on every local change to a set. A failed write only rolls back
    /// if nothing newer has touched that set since, so a slow failure can't
    /// clobber a later tap.
    private var revisions: [Int: Int] = [:]

    init(
        workout: StrengthWorkout,
        stats: ExerciseStatsStore = .shared,
        sync: StrengthCompletionSyncing? = nil,
        onChange: ((StrengthWorkout) -> Void)? = nil
    ) {
        self.workout = workout
        self.sets = workout.components.sorted { $0.order < $1.order }
        self.stats = stats
        self.sync = sync
        self.onChange = onChange
        for (index, set) in sets.enumerated() {
            guard let done = set.completed else { continue }
            completed[index] = done
            drafts[index] = SetEntry(weight: done.weightUsed, reps: done.reps)
        }
    }

    /// Takes the server ids from the saved copy of this block, once the
    /// session finishes saving, and sends any sets checked off before then.
    /// Matching is by position: the saved block is the streamed one, persisted.
    func adoptSaved(_ saved: StrengthWorkout) {
        guard workout.serverId == nil, let pieceId = saved.serverId else { return }
        let savedSets = saved.components.sorted { $0.order < $1.order }
        guard savedSets.count == sets.count else {
            TelemetryService.captureMessage("strength.adopt_saved_mismatch")
            syncError = "This block changed while saving. Reopen it to log your sets."
            return
        }
        workout.serverId = pieceId
        for index in sets.indices {
            sets[index].id = savedSets[index].id
        }

        let unsent = sets.indices.compactMap { index -> StrengthSetResult? in
            guard let done = completed[index], let componentId = sets[index].id else { return nil }
            return StrengthSetResult(componentId: componentId, reps: done.reps, weight: done.weightUsed, rpe: done.rpe)
        }
        guard !unsent.isEmpty else { return }
        enqueue(onFailure: { [weak self] in
            self?.syncError = "Couldn't save your sets. Check your connection and try again."
        }) { sync in
            try await Self.send(.complete(unsent), pieceId: pieceId, via: sync)
        }
    }

    /// Resolves once every write queued so far has finished. For tests.
    func waitForPendingWrites() async {
        await pending?.value
    }

    /// The first set not yet done: where the athlete is in the block.
    var currentIndex: Int? {
        sets.indices.first { completed[$0] == nil }
    }

    var isFinished: Bool { currentIndex == nil }

    /// The set the athlete last tapped (row, chip or check), or nil before
    /// they've tapped anything. Drives the header, so in a superset tapping a
    /// Front Squat set shows Front Squat and tapping a Pendlay Row set shows
    /// Pendlay Row.
    @Published private(set) var selectedIndex: Int?

    func select(_ index: Int) {
        guard sets.indices.contains(index) else { return }
        selectedIndex = index
    }

    /// The exercise the header describes: the selected set's; before any
    /// selection, the current set's, or the last set's once the block is
    /// done. Nil only for an empty block.
    var headerExercise: String? {
        guard let index = selectedIndex ?? currentIndex ?? sets.indices.last else { return nil }
        return sets[index].exercise.name
    }

    /// 1RM only means something for loaded lifts: an exercise with a
    /// prescribed weight or RPE on any of its sets. Bodyweight work
    /// (pull-ups for reps) has none.
    func tracksOneRepMax(_ exercise: String) -> Bool {
        sets.contains { $0.exercise.name == exercise && ($0.weight != nil || $0.rpe != nil) }
    }

    /// The target muscles of `exercise`, from the first set that has them.
    func muscleGroups(for exercise: String) -> [String] {
        sets.first { $0.exercise.name == exercise && !$0.exercise.muscleGroups.isEmpty }?.exercise.muscleGroups ?? []
    }

    func videoURL(for exercise: String) -> URL? {
        sets.first { $0.exercise.name == exercise && $0.exercise.videoURL != nil }?.exercise.videoURL
    }

    /// The weight (pounds) last logged for the same effort as set `index`:
    /// same exercise, reps and RPE. Nil when there's no history.
    func lastWeight(forSet index: Int) -> Double? {
        let set = sets[index]
        return stats.lastWeight(for: set.exercise.name, reps: set.reps, rpe: set.rpe)
    }

    /// What the row shows: logged values once edited, otherwise the prefill.
    func entry(for index: Int) -> SetEntry {
        drafts[index] ?? defaultEntry(for: index)
    }

    /// Record what was lifted and check the set off in one step: the
    /// keypad's Log button. Weight is in pounds; nil is bodyweight.
    func log(_ index: Int, weight: Double?, reps: Int) {
        guard sets.indices.contains(index), reps > 0 else { return }
        markDone(index, entry: SetEntry(weight: weight, reps: reps), reps: reps)
    }

    /// Where the keypad goes after logging `index`: the next set not yet
    /// done, wrapping to an earlier skipped one, or nil when all are done.
    func nextIncomplete(after index: Int) -> Int? {
        sets.indices.first { $0 > index && completed[$0] == nil }
            ?? sets.indices.first { completed[$0] == nil }
    }

    /// Check or un-check a set. Checking logs whatever the inputs currently show.
    func toggleComplete(_ index: Int) {
        guard sets.indices.contains(index) else { return }
        if completed[index] != nil {
            markUndone(index)
            return
        }
        let entry = entry(for: index)
        guard let reps = entry.reps, reps > 0 else { return }
        // Pin the values so later sets' prefill can't shift what was logged.
        markDone(index, entry: entry, reps: reps)
    }

    // MARK: - Sync

    private func markDone(_ index: Int, entry: SetEntry, reps: Int) {
        let previous = (completed[index], drafts[index])
        let done = CompletedSet(weightUsed: entry.weight, reps: reps, rpe: completed[index]?.rpe)
        drafts[index] = entry
        completed[index] = done
        recordStats(index, weight: entry.weight)

        write(index, rollback: previous) { componentId in
            .complete([StrengthSetResult(componentId: componentId, reps: done.reps, weight: done.weightUsed, rpe: done.rpe)])
        }
    }

    private func markUndone(_ index: Int) {
        let previous = (completed[index], drafts[index])
        completed[index] = nil

        write(index, rollback: previous) { componentId in
            .uncomplete([componentId])
        }
    }

    /// Queues a server write for set `index`. The local change has already
    /// been applied; on failure it's reverted to `rollback`.
    private func write(
        _ index: Int,
        rollback: (CompletedSet?, SetEntry?),
        _ request: (Int) -> SyncRequest
    ) {
        let revision = (revisions[index] ?? 0) + 1
        revisions[index] = revision

        // Still streaming: adoptSaved sends this once the ids arrive.
        guard let pieceId = workout.serverId else { return }
        guard let componentId = sets[index].id else {
            // A saved block whose set has no id can never be saved. Say so
            // rather than leaving a check mark that isn't on the server.
            TelemetryService.captureMessage("strength.missing_component_id")
            completed[index] = rollback.0
            drafts[index] = rollback.1
            syncError = "Couldn't save set \(index + 1). Reopen the workout and try again."
            return
        }

        let request = request(componentId)
        enqueue(onFailure: { [weak self] in
            guard let self, self.revisions[index] == revision else { return }
            self.completed[index] = rollback.0
            self.drafts[index] = rollback.1
            self.syncError = "Couldn't save set \(index + 1). Check your connection and try again."
        }) { sync in
            try await Self.send(request, pieceId: pieceId, via: sync)
        }
    }

    /// Runs `operation` after every earlier write, then reports the result.
    private func enqueue(
        onFailure: @escaping () -> Void,
        _ operation: @escaping (StrengthCompletionSyncing?) async throws -> Void
    ) {
        let previous = pending
        let sync = sync
        pending = Task { [weak self] in
            await previous?.value
            do {
                try await operation(sync)
                guard let self else { return }
                self.syncError = nil
                self.onChange?(self.currentWorkout)
            } catch {
                onFailure()
            }
        }
    }

    // MARK: - Network

    enum SyncRequest {
        case complete([StrengthSetResult])
        case uncomplete([Int])
    }

    /// Sends `request` for piece `pieceId`: through `sync` in tests, otherwise
    /// as a GraphQL mutation on the shared Apollo client.
    private static func send(_ request: SyncRequest, pieceId: Int, via sync: StrengthCompletionSyncing?) async throws {
        if let sync {
            switch request {
            case let .complete(sets): try await sync.complete(strengthWorkoutId: pieceId, sets: sets)
            case let .uncomplete(ids): try await sync.uncomplete(strengthWorkoutId: pieceId, componentIds: ids)
            }
            return
        }

        switch request {
        case let .complete(sets):
            let mutation = CompleteStrengthComponentsMutation(
                strengthWorkoutId: pieceId,
                components: sets.map {
                    StrengthComponentResultInput(
                        id: $0.componentId,
                        reps: $0.reps,
                        weight: $0.weight.map { .some($0) } ?? .null,
                        rpe: $0.rpe.map { .some($0) } ?? .null
                    )
                }
            )
            try await perform(mutation, operation: "CompleteStrengthComponents")
        case let .uncomplete(ids):
            let mutation = UncompleteStrengthComponentsMutation(strengthWorkoutId: pieceId, componentIds: ids)
            try await perform(mutation, operation: "UncompleteStrengthComponents")
        }
    }

    /// Same shape as HIITWorkoutViewModel.performCompletion: GraphQL errors
    /// count as failures, and both kinds are reported to telemetry.
    private static func perform<M: GraphQLMutation>(_ mutation: M, operation: String) async throws {
        let result: GraphQLResult<M.Data>
        do {
            result = try await withCheckedThrowingContinuation { continuation in
                Network.shared.client.perform(mutation: mutation) { result in
                    continuation.resume(with: result)
                }
            }
        } catch {
            print("⚠️ \(operation) failed: \(error)")
            TelemetryService.captureError(error, tags: ["operation": operation])
            throw error
        }
        if let errors = result.errors, !errors.isEmpty {
            let messages = errors.compactMap { $0.message }.joined(separator: "; ")
            print("⚠️ \(operation) GraphQL errors: \(messages)")
            TelemetryService.captureGraphQLErrors(messages: messages, operation: operation)
            throw StrengthCompletionSyncError.graphQL(messages)
        }
    }

    /// The block as it stands now, with each set's logged result.
    private var currentWorkout: StrengthWorkout {
        var updated = workout
        updated.components = sets.indices.map { index in
            var set = sets[index]
            set.completed = completed[index]
            return set
        }
        return updated
    }

    /// A finished set updates the last weight for its effort (the
    /// prescription's exercise, reps and RPE, not the reps actually done).
    /// Un-checking doesn't roll it back: the lift still happened.
    private func recordStats(_ index: Int, weight: Double?) {
        let set = sets[index]
        guard let weight else { return }
        stats.recordWeight(weight, for: set.exercise.name, reps: set.reps, rpe: set.rpe)
    }

    /// Prefill: the prescribed reps, and the prescribed load. With no
    /// prescribed load, whatever was used on the previous set of the same
    /// exercise, so the athlete isn't retyping it every set.
    private func defaultEntry(for index: Int) -> SetEntry {
        let set = sets[index]
        if let weight = set.weight { return SetEntry(weight: weight, reps: set.reps) }
        let previousWeight = sets[..<index].indices.reversed()
            .first { sets[$0].exercise == set.exercise && completed[$0]?.weightUsed != nil }
            .flatMap { completed[$0]?.weightUsed }
        return SetEntry(weight: previousWeight, reps: set.reps)
    }
}
