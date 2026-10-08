//
//  ActivityFeedTests.swift
//  wodAITests
//
//  The Stats feed's pure rules: grouping by day, strength text, RPE bands,
//  and editing a logged result.
//

import Testing
import Foundation
@testable import wodAI

struct ActivityFeedTests {

    /// Los Angeles, so day boundaries aren't UTC midnight.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    private static func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    private static func hiit(_ id: Int, _ iso: String) -> ActivityItem {
        .hiit(CompletedHiitEntry(id: id, completedAt: date(iso), workoutId: id, stimulus: ""))
    }

    private static func strength(_ id: Int, _ iso: String) -> ActivityItem {
        .strength(CompletedStrengthEntry(id: id, completedAt: date(iso), title: "Squat", lifts: []))
    }

    // MARK: - Grouping

    @Test func groupsByLocalDayNewestFirst() {
        let items = [
            Self.hiit(1, "2026-10-05T16:00:00Z"),      // Mon 9:00 PDT
            Self.strength(1, "2026-10-05T15:00:00Z"),  // Mon 8:00 PDT
            Self.hiit(2, "2026-10-07T18:00:00Z"),      // Wed
        ]
        let days = ActivityFeed.days(items, calendar: Self.calendar)

        #expect(days.count == 2)  // Tuesday had nothing, so it gets no divider
        #expect(days[0].items.map(\.id) == ["hiit-2"])
        #expect(days[1].items.map(\.id) == ["hiit-1", "strength-1"])
    }

    @Test func splitsOnLocalMidnightNotUTC() {
        // 06:30Z is still Monday 23:30 in Los Angeles; 07:30Z is Tuesday.
        let days = ActivityFeed.days(
            [Self.hiit(1, "2026-10-06T06:30:00Z"), Self.hiit(2, "2026-10-06T07:30:00Z")],
            calendar: Self.calendar
        )
        #expect(days.count == 2)
        #expect(Self.calendar.component(.weekday, from: days[0].day) == 3)  // Tuesday
        #expect(Self.calendar.component(.weekday, from: days[1].day) == 2)  // Monday
    }

    @Test func noItemsMeansNoDays() {
        #expect(ActivityFeed.days([], calendar: Self.calendar).isEmpty)
    }

    @Test func labelsTodayAndYesterday() {
        let now = Self.date("2026-10-06T19:00:00Z")
        let today = Self.calendar.startOfDay(for: now)
        let yesterday = Self.calendar.date(byAdding: .day, value: -1, to: today)!
        let older = Self.calendar.date(byAdding: .day, value: -3, to: today)!
        #expect(ActivityFeed.dayLabel(today, now: now, calendar: Self.calendar) == "Today")
        #expect(ActivityFeed.dayLabel(yesterday, now: now, calendar: Self.calendar) == "Yesterday")
        #expect(ActivityFeed.dayLabel(older, now: now, calendar: Self.calendar) != "Yesterday")
    }

    // MARK: - Strength

    @Test func groupsSetsByExerciseAndKeepsOnlyLoggedWeights() {
        let done = Self.date("2026-10-05T15:00:00Z")
        let entry = CompletedStrengthEntry(id: 1, completedAt: done, name: nil, sets: [
            .init(order: 2, exercise: "Front Squat", reps: 5, completedAt: done, completedWeight: 165),
            .init(order: 0, exercise: "Front Squat", reps: 5, completedAt: done, completedWeight: 155),
            .init(order: 1, exercise: "Pendlay Row", reps: 8, completedAt: done, completedWeight: 135),
            .init(order: 3, exercise: "Pendlay Row", reps: 8, completedAt: nil, completedWeight: nil),
        ])
        #expect(entry.title == "Front Squat + Pendlay Row")
        #expect(entry.lifts.map(\.exercise) == ["Front Squat", "Pendlay Row"])
        #expect(entry.lifts[0].loggedWeights == [155, 165])
        #expect(entry.lifts[1].prescribedReps == [8, 8])
        #expect(entry.lifts[1].loggedWeights == [135])
    }

    @Test func prefersThePiecesOwnName() {
        let entry = CompletedStrengthEntry(id: 1, completedAt: Date(), name: "Heavy day", sets: [
            .init(order: 0, exercise: "Deadlift", reps: 3, completedAt: Date(), completedWeight: 315),
        ])
        #expect(entry.title == "Heavy day")
    }

    @Test func schemeCollapsesUniformSets() {
        #expect(StrengthText.scheme([5, 5, 5, 5, 5]) == "5 × 5")
        #expect(StrengthText.scheme([5, 3, 3, 1]) == "5-3-3-1")
        #expect(StrengthText.scheme([]) == nil)
    }

    @Test func progressionShowsEverySetEvenAtTheSameLoad() {
        #expect(StrengthText.progression([135, 155, 155, 175, 185], unit: .lb) == "135 → 155 → 155 → 175 → 185 lb")
        #expect(StrengthText.progression([225, 225, 225], unit: .lb) == "225 → 225 → 225 lb")
    }

    @Test func progressionConvertsToKilograms() {
        #expect(StrengthText.progression([220.462, 242.5], unit: .kg) == "100 → 110 kg")
    }

    @Test func progressionHandlesBodyweight() {
        #expect(StrengthText.progression([nil, nil], unit: .lb) == "BW → BW")
        #expect(StrengthText.progression([nil, 25, 45], unit: .lb) == "BW → 25 → 45 lb")
        #expect(StrengthText.progression([], unit: .lb) == nil)
    }

    // MARK: - RPE

    @Test func rpeBandEdges() {
        #expect(RPEBand(rpe: nil) == nil)
        #expect(RPEBand(rpe: 1) == .easy)
        #expect(RPEBand(rpe: 4) == .easy)
        #expect(RPEBand(rpe: 5) == .moderate)
        #expect(RPEBand(rpe: 6) == .moderate)
        #expect(RPEBand(rpe: 7) == .hard)
        #expect(RPEBand(rpe: 8) == .hard)
        #expect(RPEBand(rpe: 9) == .max)
        #expect(RPEBand(rpe: 10) == .max)
    }

    // MARK: - Editing HIIT

    private static func amrapEntry(rounds: Int?, reps: Int?, effort: Int?) -> CompletedHiitEntry {
        CompletedHiitEntry(
            id: 9, completedAt: date("2026-10-05T16:00:00Z"), workoutId: 42,
            format: "AMRAP 20", stimulus: "", perceivedEffort: effort,
            roundsCompleted: rounds, repsCompleted: reps,
            constraintType: "rounds", constraintMagnitude: 20
        )
    }

    @Test func draftStartsAtTheLoggedResult() {
        let draft = Self.amrapEntry(rounds: 7, reps: 12, effort: 6).completionDraft
        #expect(draft.id == 42)  // the workout, not the completion
        #expect(draft.kind == .amrap)
        #expect(draft.roundsCompleted == 7)
        #expect(draft.repsCompleted == 12)
        #expect(draft.perceivedEffort == 6)
    }

    @Test func editSendsOnlyChangedResultsButAlwaysEffort() {
        let entry = Self.amrapEntry(rounds: 7, reps: 12, effort: 6)
        var draft = entry.completionDraft
        draft.perceivedEffort = 8
        #expect(entry.edit(from: draft) == HiitCompletionEdit(perceivedEffort: 8))

        draft.roundsCompleted = 8
        #expect(entry.edit(from: draft) == HiitCompletionEdit(roundsCompleted: 8, perceivedEffort: 8))
    }

    @Test func untouchedEmptyResultStaysEmpty() {
        // Logged with Skip: no score. Re-rating it mustn't record 0 rounds.
        let entry = Self.amrapEntry(rounds: nil, reps: nil, effort: nil)
        var draft = entry.completionDraft
        draft.perceivedEffort = 5
        #expect(entry.edit(from: draft) == HiitCompletionEdit(perceivedEffort: 5))
    }

    // MARK: - Editing strength

    private static func squats(logged: [Double?]) -> StrengthWorkout {
        let squat = ExerciseName(name: "Back Squat")
        return StrengthWorkout(
            id: 3, name: "Back Squat", instructions: "",
            components: logged.enumerated().map { index, weight in
                StrengthComponent(
                    order: index, reps: 5, weight: nil, rpe: nil, exercise: squat, id: 100 + index,
                    completed: weight.map { CompletedSet(weightUsed: $0, reps: 5) }
                )
            },
            serverId: 3
        )
    }

    @Test func strengthEntryFromWorkoutListsOnlyLoggedSets() {
        let entry = CompletedStrengthEntry(
            completedAt: Self.date("2026-10-05T16:00:00Z"), name: nil,
            workout: Self.squats(logged: [135, 155, nil])
        )
        #expect(entry.id == 3)
        #expect(entry.title == "Back Squat")
        #expect(entry.lifts == [.init(exercise: "Back Squat", prescribedReps: [5, 5, 5], loggedWeights: [135, 155])])
        #expect(entry.workout != nil)
    }

    @Test func editedStrengthKeepsDayAndTitle() {
        let completedAt = Self.date("2026-10-05T16:00:00Z")
        let entry = CompletedStrengthEntry(completedAt: completedAt, name: "Heavy Day", workout: Self.squats(logged: [135, 155]))
        let edited = entry.updated(with: Self.squats(logged: [135, 165]))
        #expect(edited?.completedAt == completedAt)
        #expect(edited?.title == "Heavy Day")
        #expect(edited?.lifts.first?.loggedWeights == [135, 165])
    }

    @Test func strengthWithEverySetUncheckedLeavesTheFeed() {
        let entry = CompletedStrengthEntry(
            completedAt: Self.date("2026-10-05T16:00:00Z"), name: nil,
            workout: Self.squats(logged: [135])
        )
        #expect(entry.updated(with: Self.squats(logged: [nil])) == nil)
    }

    @MainActor
    @Test func storeReplacesAndRemovesItems() {
        let store = ActivityFeedStore(preview: [Self.hiit(1, "2026-10-05T16:00:00Z"), Self.strength(2, "2026-10-05T15:00:00Z")])
        var rated = CompletedHiitEntry(id: 1, completedAt: Self.date("2026-10-05T16:00:00Z"), workoutId: 1, stimulus: "")
        rated.perceivedEffort = 9
        store.replace(.hiit(rated))
        #expect(store.items.first == .hiit(rated))

        store.remove(id: "strength-2")
        #expect(store.items.map(\.id) == ["hiit-1"])
    }
}
