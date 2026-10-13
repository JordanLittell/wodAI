//
//  HealthSync.swift
//  wodAI
//
//  Apple Health for the rest of the app: connecting (read, then upload the
//  summary), disconnecting, and saving finished workouts.
//
//  What gets written:
//  - A session from the Workout page, as its work is logged: one workout from
//    the first logged work to the last, with the heart rate any of its metcons
//    recorded. Each later write replaces it, so a session done in part still
//    reaches Health, and finishing it brings the workout up to date.
//  - A metcon done on its own (a saved workout), when its result is saved.
//  Nothing is written while the athlete isn't connected or has writing off,
//  and a write never blocks or fails a workout. A write that's skipped is
//  reported to Sentry as `health.write_skipped` with its reason, once per
//  session and reason.
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
    /// How long a session's write waits for more work, so a run of sets
    /// writes once.
    private let sessionWriteDelay: Duration
    /// The write waiting on each session, by session id.
    private var pendingSessionWrites: [String: Task<Void, Never>] = [:]
    /// Skips already reported, as "<session id>|<reason>".
    private var reportedSkips: Set<String> = []

    init(
        source: HealthDataSource = HealthKitDataSource.shared,
        api: HealthAPI = ApolloHealthAPI(),
        defaults: UserDefaults = .standard,
        clock: @escaping () -> Date = Date.init,
        sessionWriteDelay: Duration = .seconds(20)
    ) {
        self.source = source
        self.api = api
        self.defaults = defaults
        self.clock = clock
        self.sessionWriteDelay = sessionWriteDelay
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

    /// Work in a session on the Workout page was saved on the server. Writes
    /// the session's workout from what's logged so far, after a short wait
    /// for more (at once when `completed`), keyed by the session so each
    /// write replaces the last rather than adding one.
    @discardableResult
    func sessionProgressed(id: String, completed: Bool) -> Task<Void, Never>? {
        // Once per run rather than per session: many athletes never connect.
        guard isConnected else { reportSkip(.notConnected, session: "*"); return nil }
        guard writesWorkouts else { return nil }
        pendingSessionWrites[id]?.cancel()
        let delay = completed ? .zero : sessionWriteDelay
        let task = Task { [weak self] in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled, let self else { return }
            self.pendingSessionWrites[id] = nil
            await self.writeSession(id: id)
        }
        pendingSessionWrites[id] = task
        return task
    }

    private func writeSession(id: String) async {
        guard canWrite else { return }
        let session: HealthSessionInfo?
        do {
            session = try await api.session(id: id)
        } catch {
            reportSkip(.fetchFailed, session: id)
            return
        }
        guard let session, let write = Self.write(for: session, heartRate: pieceHeartRate) else {
            TelemetryService.addBreadcrumb(category: "health", message: "nothing logged", data: ["session": id])
            return
        }
        if session.completedAt != nil {
            for result in session.hiitResults { pieceHeartRate[result.pieceId] = nil }
        }
        await save(write, session: id)
    }

    /// The Health workout for a session's logged work; nil when nothing in
    /// it is logged. Pure, for tests.
    static func write(
        for session: HealthSessionInfo,
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
            // Later work ends later, so its write replaces the earlier one.
            syncVersion: Int(plan.end.timeIntervalSince1970),
            activity: plan.activity,
            start: plan.start,
            end: plan.end,
            title: session.name
        )
        write.heartRate = recorded.flatMap(\.samples).sorted { $0.date < $1.date }
        write.activeEnergyKcal = kcal.isEmpty ? nil : kcal.reduce(0, +)
        return write
    }

    private func save(_ workout: HealthWorkoutWrite, session: String? = nil) async {
        do {
            let outcome = try await source.save(workout)
            TelemetryService.addBreadcrumb(category: "health", message: "write", data: ["outcome": "\(outcome)"])
            switch outcome {
            case .saved: break
            case .skippedOverlap: reportSkip(.overlap, session: session ?? workout.syncIdentifier)
            case .notAllowed: reportSkip(.notAllowed, session: session ?? workout.syncIdentifier)
            }
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "HealthWrite"])
        }
    }

    enum SkipReason: String {
        /// Writing is on but Apple Health isn't connected in the app.
        case notConnected
        /// The session couldn't be fetched to time its workout.
        case fetchFailed
        /// Another app has a workout at that time.
        case overlap
        /// iOS doesn't allow the app to write workouts.
        case notAllowed
    }

    /// Reports why a workout didn't reach Health, once per session and reason.
    private func reportSkip(_ reason: SkipReason, session: String) {
        guard reportedSkips.insert("\(session)|\(reason.rawValue)").inserted else { return }
        TelemetryService.captureMessage("health.write_skipped", level: .warning, tags: ["reason": reason.rawValue])
    }
}
