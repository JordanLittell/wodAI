//
//  HealthSync.swift
//  wodAI
//
//  Apple Health for the rest of the app: connecting (read, then upload the
//  summary), disconnecting, and saving finished workouts.
//
//  What gets written:
//  - A session from the Workout page, once it completes on the server (its
//    last set or HIIT result logged): one workout from the first logged work
//    to the last, with the heart rate any of its metcons recorded.
//  - A metcon done on its own (a saved workout), when its result is saved.
//  Nothing is written while the athlete isn't connected or has writing off,
//  and a write never blocks or fails a workout.
//

import Foundation
import Combine

/// What onboarding needs from Health. Reading returns as soon as the phone
/// has answered; the upload (which suggests a level) is separate so a slow
/// network never holds up the prefill.
@MainActor
protocol HealthConnecting {
    var isAvailable: Bool { get }
    func connect() async throws -> HealthSnapshot
    func upload(_ snapshot: HealthSnapshot) async throws -> HealthSuggestion?
}

@MainActor
final class HealthSync: ObservableObject, HealthConnecting {
    static let shared = HealthSync()

    /// Connected Apple Health (in onboarding or the Apple Health screen) and
    /// hasn't disconnected.
    @Published private(set) var isConnected: Bool {
        didSet { defaults.set(isConnected, forKey: Keys.connected) }
    }
    /// The athlete's switch for saving workouts to Health. On by default.
    @Published var writesWorkouts: Bool {
        didSet { defaults.set(writesWorkouts, forKey: Keys.writesWorkouts) }
    }

    private enum Keys {
        static let connected = "health.isConnected"
        static let writesWorkouts = "health.writesWorkouts"
    }

    private let source: HealthDataSource
    private let api: HealthAPI
    private let defaults: UserDefaults
    private let clock: () -> Date
    /// Heart rate a metcon in a session recorded, by its WorkoutHiitPiece id,
    /// until the session's workout is written. Memory only: a session
    /// finished after the app restarts is written without it.
    private var pieceHeartRate: [Int: (samples: [(date: Date, bpm: Double)], kcal: Double?)] = [:]

    init(
        source: HealthDataSource = HealthKitDataSource.shared,
        api: HealthAPI = ApolloHealthAPI(),
        defaults: UserDefaults = .standard,
        clock: @escaping () -> Date = Date.init
    ) {
        self.source = source
        self.api = api
        self.defaults = defaults
        self.clock = clock
        isConnected = defaults.bool(forKey: Keys.connected)
        writesWorkouts = defaults.object(forKey: Keys.writesWorkouts) as? Bool ?? true
    }

    var isAvailable: Bool { source.isAvailable }

    // MARK: - Connecting

    func connect() async throws -> HealthSnapshot {
        try await source.requestAuthorization()
        isConnected = true
        let started = clock()
        let snapshot = await source.readSnapshot(now: clock())
        TelemetryService.addBreadcrumb(category: "health", message: "read", data: [
            "ms": Int(clock().timeIntervalSince(started) * 1000),
            "workouts": snapshot.workouts.workoutCount,
        ])
        return snapshot
    }

    func upload(_ snapshot: HealthSnapshot) async throws -> HealthSuggestion? {
        let started = clock()
        let suggestion = try await api.importSnapshot(snapshot)
        TelemetryService.addBreadcrumb(category: "health", message: "upload", data: [
            "ms": Int(clock().timeIntervalSince(started) * 1000),
        ])
        return suggestion
    }

    func connection() async throws -> HealthConnectionInfo? {
        try await api.connection()
    }

    func confirm(_ level: OnboardingLevel) async throws {
        try await api.setFitnessLevel(level)
    }

    /// Deletes what the server keeps from Health. iOS permissions stay as
    /// they are; only the Health app can take them back.
    func disconnect() async throws {
        try await api.disconnect()
        isConnected = false
        pieceHeartRate = [:]
    }

    private var canWrite: Bool { isConnected && writesWorkouts }

    // MARK: - Writing

    /// A metcon in a session saved its result; keep its heart rate for the
    /// session's workout.
    func metconFinished(pieceId: Int, heartRate: [(date: Date, bpm: Double)], kcal: Double?) {
        guard canWrite, !heartRate.isEmpty || kcal != nil else { return }
        pieceHeartRate[pieceId] = (heartRate, kcal)
    }

    /// A metcon done outside a session saved its result.
    func metconFinished(
        completionId: Int,
        title: String,
        start: Date,
        end: Date,
        heartRate: [(date: Date, bpm: Double)],
        kcal: Double?
    ) async {
        guard canWrite else { return }
        var workout = HealthWorkoutWrite(
            syncIdentifier: "wodai-hiit-\(completionId)",
            syncVersion: 1,
            activity: .hiit,
            start: start,
            end: max(end, start.addingTimeInterval(SessionWorkoutPlan.minimumDuration)),
            title: title
        )
        workout.heartRate = heartRate
        workout.activeEnergyKcal = kcal
        await save(workout)
    }

    /// A session on the Workout page looks done. Writes its workout once the
    /// server agrees (it completes sessions itself when the last work is
    /// logged), keyed by the session so a repeat replaces rather than adds.
    func sessionMayHaveCompleted(id: String) async {
        guard canWrite else { return }
        let session: HealthSessionInfo?
        do {
            session = try await api.session(id: id)
        } catch {
            return
        }
        guard let session, let completedAt = session.completedAt,
              let write = Self.write(for: session, completedAt: completedAt, heartRate: pieceHeartRate)
        else { return }
        for result in session.hiitResults { pieceHeartRate[result.pieceId] = nil }
        await save(write)
    }

    /// The Health workout for a completed session. Pure, for tests.
    static func write(
        for session: HealthSessionInfo,
        completedAt: Date,
        heartRate: [Int: (samples: [(date: Date, bpm: Double)], kcal: Double?)]
    ) -> HealthWorkoutWrite? {
        guard let plan = SessionWorkoutPlan(
            setTimes: session.setTimes,
            hiitResults: session.hiitResults.map { ($0.completedAt, $0.durationSeconds) }
        ) else { return nil }
        let recorded = session.hiitResults.compactMap { heartRate[$0.pieceId] }
        let kcal = recorded.compactMap(\.kcal)
        var write = HealthWorkoutWrite(
            syncIdentifier: "wodai-session-\(session.id)",
            // A session reopened and finished again replaces its workout.
            syncVersion: Int(completedAt.timeIntervalSince1970),
            activity: plan.activity,
            start: plan.start,
            end: plan.end,
            title: session.name
        )
        write.heartRate = recorded.flatMap(\.samples).sorted { $0.date < $1.date }
        write.activeEnergyKcal = kcal.isEmpty ? nil : kcal.reduce(0, +)
        return write
    }

    private func save(_ workout: HealthWorkoutWrite) async {
        do {
            let outcome = try await source.save(workout)
            TelemetryService.addBreadcrumb(category: "health", message: "write", data: ["outcome": "\(outcome)"])
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "HealthWrite"])
        }
    }
}
