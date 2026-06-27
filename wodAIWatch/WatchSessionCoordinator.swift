//
//  WatchSessionCoordinator.swift
//  wodAI Watch
//
//  Top-level watch object. Owns the connectivity relay, HealthKit workout session, and
//  motion collector, and creates an `ExecutionEngine` when the phone sends a workout.
//  Bridges the engine's pure boundary events to haptics, and motion frames to the relay.
//
//  Timing is anchored to the shared `payload.startedAt` (t0) so the watch and phone count
//  down and run off the exact same clock. Lifecycle actions sync in BOTH directions.
//

import Foundation
import Combine

@MainActor
final class WatchSessionCoordinator: ObservableObject {
    /// Non-nil while a workout is loaded/running; drives the root view.
    @Published private(set) var engine: ExecutionEngine?
    /// True once Health + Motion permissions are granted (drives the setup screen).
    @Published private(set) var isSetUp = false

    let workout = WatchWorkoutSession()
    let motion = MotionCollector()
    let relay = WatchConnectivityRelay()

    private var cancellables = Set<AnyCancellable>()
    private var engineCancellables = Set<AnyCancellable>()
    /// Set while applying a phone-initiated end, so we don't echo `.finish` back to the phone.
    private var suppressFinishNotify = false

    init() {
        relay.onStart = { [weak self] payload in self?.begin(payload) }
        relay.onControl = { [weak self] control in self?.applyRemoteControl(control) }
        // Captured directly (not via self): this fires on the motion queue, off the main
        // actor. `relay.enqueue` is internally lock-guarded and safe to call from there.
        let relay = self.relay
        motion.onFrame = { frame in relay.enqueue(frame) }

        // Keep the latest HR available to stamp onto outgoing sensor frames.
        workout.$heartRate
            .sink { [weak self] hr in self?.motion.latestHeartRate = hr > 0 ? hr : nil }
            .store(in: &cancellables)
    }

    /// Call once on launch.
    func activate() {
        relay.activate()
        refreshSetupState()
        reportDeviceStatus()        // let the phone's Devices page know our current state
    }

    // MARK: - Setup (permissions granted once, off the workout hot path)

    func requestSetupAuthorization() async {
        await workout.requestAuthorization()
        _ = await motion.requestAuthorization()
        refreshSetupState()
        reportDeviceStatus()
    }

    private func refreshSetupState() {
        isSetUp = workout.shareAuthorized && MotionCollector.isAuthorized
    }

    private func reportDeviceStatus() {
        relay.sendDeviceStatus(health: workout.shareAuthorized, motion: MotionCollector.isAuthorized)
    }

    // MARK: - Lifecycle initiated ON THE WATCH (apply locally + notify the phone)

    func pause()  { engine?.pause();  relay.sendControl(.pause) }
    func resume() { engine?.resume(); relay.sendControl(.resume) }
    /// User tapped Stop on the watch. `didFinish` notifies the phone (suppress flag is off).
    func finish() { engine?.finish() }

    // MARK: - Lifecycle initiated ON THE PHONE (apply locally, do NOT echo back)

    private func applyRemoteControl(_ control: WatchMessage.ControlAction) {
        switch control {
        case .pause:  engine?.pause()
        case .resume: engine?.resume()
        case .finish, .abandon: endFromRemote()
        }
    }

    private func endFromRemote() {
        suppressFinishNotify = true
        engine?.finish()
        suppressFinishNotify = false
    }

    // MARK: - Session

    private func begin(_ payload: WorkoutExecutionPayload) {
        // Replace any prior session.
        engineCancellables.removeAll()
        let engine = ExecutionEngine(payload: payload)

        // Align telemetry t=0 + motion sampling to the main-timer start.
        engine.didStartMainTimer
            .sink { [weak self] t0 in
                self?.motion.start(t0: t0)
                WKHaptics.start()
            }
            .store(in: &engineCancellables)

        engine.didFinish
            .sink { [weak self] _ in self?.handleFinish() }
            .store(in: &engineCancellables)

        engine.boundary
            .sink { event in
                switch event {
                case .countdownTick: WKHaptics.countdownTick()
                case .minute, .intervalPhase: WKHaptics.boundary()
                }
            }
            .store(in: &engineCancellables)

        self.engine = engine
        workout.start()                       // warm HR during the pre-roll
        engine.begin(mainStart: payload.startedAt)   // anchor to the SHARED t0
    }

    private func handleFinish() {
        endSession()
        if !suppressFinishNotify {
            relay.sendControl(.finish)        // tell the phone we finished (watch- or cap-driven)
        }
    }

    private func endSession() {
        motion.stop()
        relay.flush()          // ship any remaining frames
        workout.stop()
    }
}
