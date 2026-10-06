//
//  ExerciseStatsStoreTests.swift
//  wodAITests
//

import Testing
import Foundation
@testable import wodAI

@MainActor
struct ExerciseStatsStoreTests {
    /// A throwaway defaults suite per test, so nothing touches the app's data.
    private func makeStore() -> (ExerciseStatsStore, UserDefaults) {
        let suite = "ExerciseStatsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (ExerciseStatsStore(defaults: defaults), defaults)
    }

    private func block(_ components: [StrengthComponent]) -> StrengthWorkout {
        StrengthWorkout(id: 1, name: "Block", instructions: "", components: components)
    }

    @Test func oneRepMaxIsPerExerciseIgnoringCaseAndSpacing() {
        let (store, _) = makeStore()
        store.setOneRepMax(275, for: "Back Squat")
        #expect(store.oneRepMax(for: "back squat ") == 275)
        #expect(store.oneRepMax(for: "Front Squat") == nil)
    }

    @Test func clearingOneRepMax() {
        let (store, _) = makeStore()
        store.setOneRepMax(275, for: "Back Squat")
        store.setOneRepMax(nil, for: "Back Squat")
        #expect(store.oneRepMax(for: "Back Squat") == nil)
        store.setOneRepMax(275, for: "Back Squat")
        store.setOneRepMax(0, for: "Back Squat")
        #expect(store.oneRepMax(for: "Back Squat") == nil)
    }

    @Test func valuesSurviveANewStore() {
        let (store, defaults) = makeStore()
        store.setOneRepMax(300, for: "Deadlift")
        store.recordWeight(255, for: "Deadlift", reps: 3, rpe: 8)
        let reloaded = ExerciseStatsStore(defaults: defaults)
        #expect(reloaded.oneRepMax(for: "Deadlift") == 300)
        #expect(reloaded.lastWeight(for: "Deadlift", reps: 3, rpe: 8) == 255)
    }

    /// RPE alone is relative: RPE 7 for 10 reps and for 3 are different loads.
    @Test func historyIsPerEffortNotPerRPE() {
        let (store, _) = makeStore()
        store.recordWeight(155, for: "Back Squat", reps: 10, rpe: 7)
        store.recordWeight(225, for: "back squat", reps: 3, rpe: 7)
        #expect(store.lastWeight(for: "Back Squat", reps: 10, rpe: 7) == 155)
        #expect(store.lastWeight(for: "Back Squat", reps: 3, rpe: 7) == 225)
        #expect(store.lastWeight(for: "Back Squat", reps: 3, rpe: 8) == nil)
        #expect(store.lastWeight(for: "Back Squat", reps: 5, rpe: 7) == nil)
    }

    @Test func noRPEIsItsOwnEffort() {
        let (store, _) = makeStore()
        store.recordWeight(135, for: "Back Squat", reps: 5, rpe: nil)
        #expect(store.lastWeight(for: "Back Squat", reps: 5, rpe: nil) == 135)
        #expect(store.lastWeight(for: "Back Squat", reps: 5, rpe: 7) == nil)
    }

    @Test func loggingASetRecordsWeightForItsPrescribedEffort() {
        let (store, _) = makeStore()
        let squat = ExerciseName(name: "Back Squat")
        let viewModel = StrengthWorkoutViewModel(workout: block([
            StrengthComponent(order: 0, reps: 5, weight: 185, rpe: 7, exercise: squat),
            StrengthComponent(order: 1, reps: 3, weight: 205, rpe: 8, exercise: squat),
        ]), stats: store)

        viewModel.log(0, weight: 185, reps: 5)
        // Fell short on reps: still filed under the prescription (3 @ RPE 8).
        viewModel.log(1, weight: 210, reps: 2)
        #expect(store.lastWeight(for: "Back Squat", reps: 5, rpe: 7) == 185)
        #expect(store.lastWeight(for: "Back Squat", reps: 3, rpe: 8) == 210)   // lifted, not prescribed
        #expect(store.lastWeight(for: "Back Squat", reps: 2, rpe: 8) == nil)
    }

    @Test func lastWeightFollowsEarlierSetsOfTheSameEffort() {
        let (store, _) = makeStore()
        let squat = ExerciseName(name: "Back Squat")
        let viewModel = StrengthWorkoutViewModel(workout: block([
            StrengthComponent(order: 0, reps: 5, weight: nil, rpe: 7, exercise: squat),
            StrengthComponent(order: 1, reps: 5, weight: nil, rpe: 7, exercise: squat),
            StrengthComponent(order: 2, reps: 3, weight: nil, rpe: 8, exercise: squat),
        ]), stats: store)
        #expect(viewModel.lastWeight(forSet: 1) == nil)          // no history: show nothing
        viewModel.log(0, weight: 175, reps: 5)
        #expect(viewModel.lastWeight(forSet: 1) == 175)
        #expect(viewModel.lastWeight(forSet: 2) == nil)          // different effort
    }

    @Test func checkingOffASetRecordsToo() {
        let (store, _) = makeStore()
        let viewModel = StrengthWorkoutViewModel(workout: block([
            StrengthComponent(order: 0, reps: 3, weight: 205, rpe: 8, exercise: ExerciseName(name: "Back Squat")),
        ]), stats: store)
        viewModel.toggleComplete(0)
        #expect(store.lastWeight(for: "Back Squat", reps: 3, rpe: 8) == 205)
    }

    @Test func bodyweightSetRecordsNothing() {
        let (store, _) = makeStore()
        let viewModel = StrengthWorkoutViewModel(workout: block([
            StrengthComponent(order: 0, reps: 8, weight: nil, rpe: 8, exercise: ExerciseName(name: "Pull-up")),
        ]), stats: store)
        viewModel.log(0, weight: nil, reps: 8)
        #expect(store.effortWeights.isEmpty)
    }

    @Test func muscleGroupsParseFromTheCatalogString() {
        #expect(ExerciseName.muscleGroups(fromCatalog: "quads, glutes,lower back") == ["Quads", "Glutes", "Lower Back"])
        #expect(ExerciseName.muscleGroups(fromCatalog: "") == [])
        #expect(ExerciseName.muscleGroups(fromCatalog: " , ") == [])
    }

    @Test func muscleGroupsComeFromTheExercisesSets() {
        let (store, _) = makeStore()
        let viewModel = StrengthWorkoutViewModel(workout: block([
            StrengthComponent(order: 0, reps: 5, weight: nil, rpe: nil,
                              exercise: ExerciseName(name: "Back Squat", muscleGroups: ["Quads", "Glutes"])),
            StrengthComponent(order: 1, reps: 10, weight: nil, rpe: nil, exercise: ExerciseName(name: "Pull-up")),
        ]), stats: store)
        #expect(viewModel.muscleGroups(for: "Back Squat") == ["Quads", "Glutes"])
        #expect(viewModel.muscleGroups(for: "Pull-up") == [])
    }

    /// Supersets: the header shows whichever exercise's set was tapped.
    @Test func headerFollowsTheSelectedSet() {
        let (store, _) = makeStore()
        let viewModel = StrengthWorkoutViewModel(workout: block([
            StrengthComponent(order: 0, reps: 5, weight: 185, rpe: nil, exercise: ExerciseName(name: "Front Squat")),
            StrengthComponent(order: 1, reps: 8, weight: 135, rpe: nil, exercise: ExerciseName(name: "Pendlay Row")),
            StrengthComponent(order: 2, reps: 5, weight: 185, rpe: nil, exercise: ExerciseName(name: "Front Squat")),
        ]), stats: store)
        #expect(viewModel.headerExercise == "Front Squat")      // nothing tapped: current set
        viewModel.select(1)
        #expect(viewModel.headerExercise == "Pendlay Row")
        viewModel.log(0, weight: 185, reps: 5)
        #expect(viewModel.headerExercise == "Pendlay Row")      // selection wins over progress
        viewModel.select(2)
        #expect(viewModel.headerExercise == "Front Squat")
        viewModel.select(99)
        #expect(viewModel.selectedIndex == 2)                   // out of range is ignored
    }

    @Test func focusFollowsTheCurrentSet() {
        let (store, _) = makeStore()
        let viewModel = StrengthWorkoutViewModel(workout: block([
            StrengthComponent(order: 0, reps: 5, weight: 185, rpe: nil, exercise: ExerciseName(name: "Back Squat")),
            StrengthComponent(order: 1, reps: 10, weight: nil, rpe: nil, exercise: ExerciseName(name: "Pull-up")),
        ]), stats: store)
        #expect(viewModel.headerExercise == "Back Squat")
        #expect(viewModel.tracksOneRepMax("Back Squat"))
        #expect(!viewModel.tracksOneRepMax("Pull-up"))

        viewModel.log(0, weight: 185, reps: 5)
        #expect(viewModel.headerExercise == "Pull-up")
        viewModel.log(1, weight: nil, reps: 10)
        #expect(viewModel.headerExercise == "Pull-up")   // stays on the last set once done
    }
}
