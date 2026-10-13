//
//  HealthTests.swift
//  wodAITests
//
//  Apple Health: the 90-day summary, how a finished session is timed and
//  written, when writes happen, and the activity mapping.
//

import Foundation
import HealthKit
import Testing
@testable import wodAI

private let now = ISO8601DateFormatter().date(from: "2026-10-13T12:00:00Z")!
private func daysAgo(_ days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }

struct WorkoutHistorySummaryTests {
    private func record(_ days: Double, _ name: String, _ category: HealthWorkoutCategory, maxHR: Double? = nil) -> HealthWorkoutRecord {
        HealthWorkoutRecord(start: daysAgo(days), activityName: name, category: category, maxHeartRate: maxHR)
    }

    @Test func countsPerWeekOverThirteenWeeks() {
        let workouts = (0..<26).map { record(Double($0) * 3, "running", .cardio) }
            + (0..<13).map { record(Double($0) * 7 + 1, "strength training", .strength) }
        let summary = WorkoutHistorySummary(workouts, now: now)

        #expect(summary.workoutCount == 39)
        #expect(summary.workoutsPerWeek == 3)
        #expect(summary.cardioPerWeek == 2)
        #expect(summary.strengthPerWeek == 1)
        #expect(summary.activeWeeks == 13)
        #expect(summary.topActivityTypes == ["running", "strength training"])
    }

    @Test func leavesOutWorkoutsOlderThanThirteenWeeks() {
        let summary = WorkoutHistorySummary([record(10, "running", .cardio), record(120, "running", .cardio)], now: now)
        #expect(summary.workoutCount == 1)
        #expect(summary.activeWeeks == 1)
    }

    @Test func walksAreNotCardio() {
        let summary = WorkoutHistorySummary([record(1, "walking", .other), record(2, "walking", .other)], now: now)
        #expect(summary.cardioPerWeek == 0)
        #expect(summary.workoutCount == 2)
    }

    @Test func keepsTheHighestHeartRate() {
        let summary = WorkoutHistorySummary(
            [record(1, "HIIT", .cardio, maxHR: 181), record(3, "running", .cardio, maxHR: 188), record(5, "yoga", .other)],
            now: now
        )
        #expect(summary.maxHeartRate == 188)
    }

    @Test func aWorkoutRightAtTheEdgeCountsInTheOldestWeek() {
        let summary = WorkoutHistorySummary([record(91, "running", .cardio)], now: now)
        #expect(summary.activeWeeks == 1)
    }
}

struct HealthSnapshotTests {
    @Test func ageIsWholeYears() {
        var snapshot = HealthSnapshot()
        snapshot.dateOfBirth = DateComponents(year: 1990, month: 11, day: 1)
        let calendar = Calendar(identifier: .gregorian)
        #expect(snapshot.age(on: now, calendar: calendar) == 35) // birthday not yet this year
    }

    @Test func emptyMeansNothingCameBack() {
        #expect(HealthSnapshot().isEmpty)
        var snapshot = HealthSnapshot()
        snapshot.dailySteps = 4000
        #expect(!snapshot.isEmpty)
    }
}

struct SessionWorkoutPlanTests {
    @Test func runsFromTheFirstLoggedWorkToTheLast() throws {
        let plan = try #require(SessionWorkoutPlan(
            setTimes: [daysAgo(0.03), daysAgo(0.025)],
            hiitResults: [(completedAt: daysAgo(0.005), durationSeconds: 600)]
        ))
        #expect(plan.activity == .mixed)
        #expect(plan.start == daysAgo(0.03))
        #expect(plan.end == daysAgo(0.005))
    }

    @Test func aMetconStartsItsDurationBeforeItsResult() throws {
        let plan = try #require(SessionWorkoutPlan(setTimes: [], hiitResults: [(completedAt: now, durationSeconds: 720)]))
        #expect(plan.activity == .hiit)
        #expect(plan.start == now.addingTimeInterval(-720))
    }

    @Test func oneSetStillLastsAMinute() throws {
        let plan = try #require(SessionWorkoutPlan(setTimes: [now], hiitResults: []))
        #expect(plan.activity == .strength)
        #expect(plan.end.timeIntervalSince(plan.start) == SessionWorkoutPlan.minimumDuration)
    }

    @Test func nothingLoggedIsNothingToWrite() {
        #expect(SessionWorkoutPlan(setTimes: [], hiitResults: []) == nil)
    }
}

struct HealthActivityTests {
    @Test func mapsSessionsToWorkoutTypes() {
        #expect(HealthActivity.activityType(for: .strength) == .traditionalStrengthTraining)
        #expect(HealthActivity.activityType(for: .hiit) == .highIntensityIntervalTraining)
        #expect(HealthActivity.activityType(for: .mixed) == .functionalStrengthTraining)
    }

    @Test func groupsOutsideWorkouts() {
        #expect(HealthActivity.describe(.running).category == .cardio)
        #expect(HealthActivity.describe(.functionalStrengthTraining).category == .strength)
        #expect(HealthActivity.describe(.walking).category == .other)
    }
}

// MARK: - HealthSync

private final class FakeSource: HealthDataSource {
    var isAvailable = true
    var canWriteWorkouts = true
    var snapshot = HealthSnapshot()
    private(set) var saved: [HealthWorkoutWrite] = []

    func requestAuthorization() async throws {}
    func readSnapshot(now: Date) async -> HealthSnapshot { snapshot }
    func save(_ workout: HealthWorkoutWrite) async throws -> HealthWriteOutcome {
        saved.append(workout)
        return .saved
    }
}

private final class FakeHealthAPI: HealthAPI {
    var sessions: [String: HealthSessionInfo] = [:]
    private(set) var disconnects = 0

    func importSnapshot(_ snapshot: HealthSnapshot) async throws -> HealthSuggestion? { nil }
    func disconnect() async throws { disconnects += 1 }
    func connection() async throws -> HealthConnectionInfo? { nil }
    func setFitnessLevel(_ level: OnboardingLevel) async throws {}
    func session(id: String) async throws -> HealthSessionInfo? { sessions[id] }
}

@MainActor
struct HealthSyncTests {
    private let source = FakeSource()
    private let api = FakeHealthAPI()

    private func sync(connected: Bool = true) -> HealthSync {
        let defaults = UserDefaults(suiteName: "HealthSyncTests-\(UUID().uuidString)")!
        defaults.set(connected, forKey: "health.isConnected")
        return HealthSync(source: source, api: api, defaults: defaults, clock: { now }, sessionWriteDelay: .milliseconds(10))
    }

    private func session(completed: Bool) -> HealthSessionInfo {
        HealthSessionInfo(
            id: "w1",
            name: "Squat day",
            completedAt: completed ? now : nil,
            setTimes: [daysAgo(0.03)],
            hiitResults: [.init(pieceId: 9, completedAt: daysAgo(0.01), durationSeconds: 300)]
        )
    }

    @Test func writingIsOnByDefault() {
        #expect(sync().writesWorkouts)
    }

    @Test func aCompletedSessionIsWrittenWithItsMetconsHeartRate() async throws {
        let health = sync()
        api.sessions["w1"] = session(completed: true)
        health.metconFinished(pieceId: 9, heartRate: [(daysAgo(0.012), 150), (daysAgo(0.011), 162)], kcal: 80)

        await health.sessionProgressed(id: "w1", completed: true)?.value

        let write = try #require(source.saved.first)
        #expect(source.saved.count == 1)
        #expect(write.syncIdentifier == "wodai-session-w1")
        #expect(write.syncVersion == Int(daysAgo(0.01).timeIntervalSince1970))
        #expect(write.activity == .mixed)
        #expect(write.title == "Squat day")
        #expect(write.start == daysAgo(0.03))
        #expect(write.end == daysAgo(0.01))
        #expect(write.heartRate.map(\.bpm) == [150, 162])
        #expect(write.activeEnergyKcal == 80)
    }

    @Test func aPartlyDoneSessionIsWrittenWithWhatWasLogged() async throws {
        let health = sync()
        api.sessions["w1"] = HealthSessionInfo(
            id: "w1", name: "Squat day", completedAt: nil, setTimes: [daysAgo(0.03), daysAgo(0.02)], hiitResults: []
        )
        await health.sessionProgressed(id: "w1", completed: false)?.value

        let write = try #require(source.saved.first)
        #expect(write.activity == .strength)
        #expect(write.start == daysAgo(0.03))
        #expect(write.end == daysAgo(0.02))
    }

    @Test func moreWorkReplacesTheEarlierWrite() async throws {
        let health = sync()
        api.sessions["w1"] = HealthSessionInfo(id: "w1", name: "Day", completedAt: nil, setTimes: [daysAgo(0.03)], hiitResults: [])
        await health.sessionProgressed(id: "w1", completed: false)?.value
        api.sessions["w1"] = session(completed: true)
        await health.sessionProgressed(id: "w1", completed: true)?.value

        #expect(source.saved.count == 2)
        #expect(Set(source.saved.map(\.syncIdentifier)) == ["wodai-session-w1"])
        #expect(source.saved[1].syncVersion > source.saved[0].syncVersion)
    }

    @Test func aRunOfSetsWritesOnce() async {
        let health = sync()
        api.sessions["w1"] = session(completed: false)
        let first = health.sessionProgressed(id: "w1", completed: false)
        let second = health.sessionProgressed(id: "w1", completed: false)
        await first?.value
        await second?.value
        #expect(source.saved.count == 1)
    }

    @Test func nothingLoggedIsNotWritten() async {
        let health = sync()
        api.sessions["w1"] = HealthSessionInfo(id: "w1", name: "Day", completedAt: nil, setTimes: [], hiitResults: [])
        await health.sessionProgressed(id: "w1", completed: false)?.value
        #expect(source.saved.isEmpty)
    }

    @Test func nothingIsWrittenWhenNotConnectedOrSwitchedOff() async {
        api.sessions["w1"] = session(completed: true)

        await sync(connected: false).sessionProgressed(id: "w1", completed: true)?.value
        let off = sync()
        off.writesWorkouts = false
        await off.sessionProgressed(id: "w1", completed: true)?.value

        #expect(source.saved.isEmpty)
    }

    @Test func aMetconOnItsOwnIsWrittenWhenSaved() async throws {
        let health = sync()
        await health.metconFinished(
            completionId: 42, title: "Fran", start: daysAgo(0.01), end: now,
            heartRate: [], kcal: nil
        )
        let write = try #require(source.saved.first)
        #expect(write.syncIdentifier == "wodai-hiit-42")
        #expect(write.activity == .hiit)
        #expect(write.title == "Fran")
    }

    @Test func disconnectingStopsWrites() async throws {
        let health = sync()
        try await health.disconnect()
        #expect(!health.isConnected)
        #expect(api.disconnects == 1)

        api.sessions["w1"] = session(completed: true)
        await health.sessionProgressed(id: "w1", completed: true)?.value
        #expect(source.saved.isEmpty)
    }

    @Test func connectingMarksItConnected() async throws {
        let health = sync(connected: false)
        _ = try await health.connect()
        #expect(health.isConnected)
    }
}

// MARK: - The Workout page

@MainActor
struct SessionCompletionHookTests {
    private let hiit = HIITWorkoutItem(
        id: 1, format: "AMRAP 12", displayText: "12 Cal Row", stimulus: "",
        constraintType: "time", constraintMagnitude: 720, timeCap: 720,
        timingScheme: nil, tags: []
    )

    private func viewModel() -> AssistantViewModel {
        let squat = StrengthComponent(order: 0, reps: 5, weight: 225, rpe: nil, exercise: ExerciseName(name: "Back Squat"))
        return AssistantViewModel(session: AssistantSession(
            id: "w1", name: "Day", description: "", stimulus: nil, coaching: nil, scheduledDate: nil,
            blocks: [
                AssistantBlock(id: 0, label: "A", letter: "A", kind: .strength(
                    StrengthWorkout(id: 0, name: "Squat", instructions: "", components: [squat])
                )),
                AssistantBlock(id: 1, label: "B", letter: "B", kind: .hiit(hiit)),
            ]
        ))
    }

    @Test func reportsEverySavedPieceOfWorkAndWhenItFinishesTheSession() throws {
        let vm = viewModel()
        var reported: [(id: String, completed: Bool)] = []
        vm.sessionProgressed = { reported.append(($0, $1)) }

        vm.markHiitCompleted(sessionId: "w1", blockId: 1)
        #expect(reported.map(\.id) == ["w1"])
        #expect(reported.map(\.completed) == [false])

        var logged = try #require(vm.strengthWorkout(sessionId: "w1", id: 0))
        logged.components[0].completed = CompletedSet(weightUsed: 225, reps: 5)
        vm.updateStrength(logged, sessionId: "w1")
        #expect(reported.map(\.completed) == [false, true])

        // Re-logging a set on a finished session updates its workout.
        vm.updateStrength(logged, sessionId: "w1")
        #expect(reported.map(\.completed) == [false, true, true])
    }
}
