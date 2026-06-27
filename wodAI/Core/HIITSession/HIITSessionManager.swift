//
//  HIITSessionManager.swift
//  wodAI
//
//  Owns the live-session lifecycle on the phone: it now mirrors the shared `ExecutionEngine`
//  (the same timing model the watch runs), so phone + watch count down and run off ONE clock
//  anchored to a shared `t0`. Responsibilities:
//   • create the backend session and hand the workout to the watch (auto-launching it),
//   • drive the phone's own engine anchored to the same `t0` the watch uses,
//   • drain the sensor buffer on a 10s cadence into AppendSensorFrames,
//   • keep lifecycle (pause/resume/finish/abandon) in sync in BOTH directions,
//   • persist the active session so it survives an app relaunch.
//

import Foundation
import Combine
import HealthKit

@MainActor
final class HIITSessionManager: ObservableObject {
    static let shared = HIITSessionManager()

    /// Phone-side mirror of the workout clock; non-nil while a session is loaded/running.
    @Published private(set) var engine: ExecutionEngine?
    @Published private(set) var isActive = false
    private(set) var sessionId: String?
    /// The workout currently executing — used to restore the view after a relaunch.
    private(set) var activeItem: HIITWorkoutItem?

    /// How the session ended, so the view can run completion UI (confetti/CompleteWorkout).
    enum EndReason { case finish, abandon }
    struct SessionEnd { let reason: EndReason; let wodId: Int }
    let didEndSession = PassthroughSubject<SessionEnd, Never>()

    let buffer = SensorFrameBuffer()
    lazy var bridge = PhoneConnectivityBridge(buffer: buffer)
    private let service = HIITSessionService()
    private let healthStore = HKHealthStore()

    /// Pre-roll length; also the headroom the watch has to auto-launch before `t0`.
    let preRoll: TimeInterval = 10
    private let flushInterval: TimeInterval = 10
    private var flushTimer: Timer?

    private var activePayload: WorkoutExecutionPayload?
    private var engineCancellable: AnyCancellable?
    private var finishCancellable: AnyCancellable?

    private static let persistKey = "activeHIITSession"

    private init() {
        // Lifecycle actions the user performs ON THE WATCH arrive here.
        bridge.onControl = { [weak self] control in
            Task { @MainActor in self?.applyRemoteControl(control) }
        }
    }

    /// Call once at app launch to bring up WatchConnectivity.
    func activate() { bridge.activate() }

    // MARK: - Start

    /// Begin a live session. `movements` is the ordered movement list (for EMOM display).
    func start(workout: HIITWorkoutItem, movements: [String] = []) async {
        guard !isActive else { return }
        // Shared t0 = end of pre-roll. Both phone and watch anchor to this exact instant.
        let t0 = Date().addingTimeInterval(preRoll)

        // Create the backend session record. If it fails (e.g. backend not live yet), we
        // still drive the watch/phone locally — frames simply won't upload.
        do {
            sessionId = try await service.create(wodId: workout.id, startedAt: t0)
        } catch {
            sessionId = nil
            print("⚠️ CreateHIITSession failed: \(error)")
        }

        let format = WorkoutFormat(rawFormat: workout.format)
        let payload = WorkoutExecutionPayload(
            sessionId: sessionId,
            wodId: workout.id,
            format: format,
            constraintType: workout.constraintType,
            constraintMagnitude: workout.constraintMagnitude,
            movements: movements,
            displayText: workout.displayText,
            intervalConfig: format == .tabata ? .parse(from: workout.displayText) : nil,
            startedAt: t0
        )

        activeItem = workout
        activePayload = payload

        let engine = ExecutionEngine(payload: payload, preRoll: preRoll)
        wireEngine(engine)
        engine.begin(mainStart: t0)
        self.engine = engine

        bridge.sendStart(payload)
        launchWatchApp()              // auto-launch the watch into the workout
        startFlushTimer()
        isActive = true
        persistSnapshot()
    }

    // MARK: - Lifecycle (phone-initiated → also notify the watch)

    func pause() {
        engine?.pause()
        bridge.sendControl(.pause)
        persistSnapshot()
    }

    func resume() {
        engine?.resume()
        bridge.sendControl(.resume)
        persistSnapshot()
    }

    func finish() { localEnd(reason: .finish, notifyWatch: true) }
    func abandon() { localEnd(reason: .abandon, notifyWatch: true) }

    // MARK: - Lifecycle (watch-initiated → apply locally, do NOT echo back)

    private func applyRemoteControl(_ control: WatchMessage.ControlAction) {
        switch control {
        case .pause:  engine?.pause(); persistSnapshot()
        case .resume: engine?.resume(); persistSnapshot()
        case .finish:  localEnd(reason: .finish, notifyWatch: false)
        case .abandon: localEnd(reason: .abandon, notifyWatch: false)
        }
    }

    /// The phone engine hit its own time cap — finalize (the watch detects its cap too).
    private func handleEngineAutoFinish() {
        localEnd(reason: .finish, notifyWatch: false)
    }

    private func localEnd(reason: EndReason, notifyWatch: Bool) {
        guard isActive else { return }
        isActive = false
        stopFlushTimer()
        if notifyWatch {
            bridge.sendControl(reason == .abandon ? .abandon : .finish)
        }

        let id = sessionId
        Task {
            await flush()                       // ship remaining frames
            if let id {
                if reason == .abandon { try? await service.abandon(sessionId: id) }
                else { try? await service.complete(sessionId: id, endedAt: Date()) }
            }
        }

        let endedWodId = activeItem?.id
        clearPersist()
        teardownEngine()
        sessionId = nil
        activeItem = nil
        activePayload = nil
        if let endedWodId {
            didEndSession.send(SessionEnd(reason: reason, wodId: endedWodId))
        }
    }

    // MARK: - Persistence / restore

    private struct Persisted: Codable {
        var payload: WorkoutExecutionPayload
        var sessionId: String?
        var item: HIITWorkoutItem
        var snapshot: ExecutionEngine.Snapshot
    }

    private func persistSnapshot() {
        guard let payload = activePayload, let item = activeItem, let snap = engine?.snapshot else {
            clearPersist(); return
        }
        let record = Persisted(payload: payload, sessionId: sessionId, item: item, snapshot: snap)
        if let data = try? JSONEncoder.iso.encode(record) {
            UserDefaults.standard.set(data, forKey: Self.persistKey)
        }
    }

    private func clearPersist() {
        UserDefaults.standard.removeObject(forKey: Self.persistKey)
    }

    /// Rebuild an in-flight session after the app was killed. Returns the restored workout
    /// so the view can show it instead of loading the default. No-op if nothing to restore.
    @discardableResult
    func restoreActiveSession() -> HIITWorkoutItem? {
        guard !isActive, engine == nil,
              let data = UserDefaults.standard.data(forKey: Self.persistKey),
              let record = try? JSONDecoder.iso.decode(Persisted.self, from: data) else { return nil }

        sessionId = record.sessionId
        activeItem = record.item
        activePayload = record.payload

        let engine = ExecutionEngine(payload: record.payload, preRoll: preRoll)
        wireEngine(engine)
        engine.restore(from: record.snapshot)
        self.engine = engine

        // Time cap already elapsed while the app was closed → finalize immediately.
        if case .finished = engine.state {
            localEnd(reason: .finish, notifyWatch: false)
            return nil
        }

        isActive = true
        startFlushTimer()
        return record.item
    }

    // MARK: - Engine wiring

    private func wireEngine(_ engine: ExecutionEngine) {
        engineCancellable = engine.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()   // re-publish ticks so the view stays live
        }
        finishCancellable = engine.didFinish.sink { [weak self] _ in
            self?.handleEngineAutoFinish()
        }
    }

    private func teardownEngine() {
        engineCancellable = nil
        finishCancellable = nil
        engine = nil
    }

    // MARK: - Watch auto-launch (HealthKit)

    /// Request the minimal HealthKit auth the phone needs to launch the watch app.
    func requestPhoneHealthAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await healthStore.requestAuthorization(toShare: [HKQuantityType.workoutType()], read: [])
    }

    /// Launch the companion watch app straight into the workout (no manual open needed).
    private func launchWatchApp() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .functionalStrengthTraining
        config.locationType = .indoor
        healthStore.startWatchApp(with: config) { success, error in
            if let error { print("⚠️ startWatchApp failed: \(error)") }
        }
    }

    // MARK: - Flush

    private func startFlushTimer() {
        stopFlushTimer()
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            Task { await self?.flush() }
        }
    }

    private func stopFlushTimer() {
        flushTimer?.invalidate()
        flushTimer = nil
    }

    /// Drain the buffer and upload. On failure, frames are re-enqueued for the next tick.
    private func flush() async {
        guard let id = sessionId else { return }
        let frames = buffer.drain()
        guard !frames.isEmpty else { return }
        do {
            try await service.appendFrames(sessionId: id, frames: frames)
        } catch {
            buffer.reenqueue(frames)
            print("⚠️ AppendSensorFrames failed, retrying next tick: \(error)")
        }
    }
}
