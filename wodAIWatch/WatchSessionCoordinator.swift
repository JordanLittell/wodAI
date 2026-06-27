//
//  WatchSessionCoordinator.swift
//  wodAI Watch
//
//  Top-level watch object. Owns the connectivity relay, HealthKit workout session, and
//  motion collector, and creates an `ExecutionEngine` when the phone sends a workout.
//  Bridges the engine's pure boundary events to haptics, and motion frames to the relay.
//

import Foundation
import Combine

@MainActor
final class WatchSessionCoordinator: ObservableObject {
    /// Non-nil while a workout is loaded/running; drives the root view.
    @Published private(set) var engine: ExecutionEngine?

    let workout = WatchWorkoutSession()
    let motion = MotionCollector()
    let relay = WatchConnectivityRelay()

    private var cancellables = Set<AnyCancellable>()
    private var engineCancellables = Set<AnyCancellable>()

    init() {
        relay.onStart = { [weak self] payload in self?.begin(payload) }
        relay.onStop = { [weak self] in self?.engine?.finish() }
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
        Task { await workout.requestAuthorization() }
    }

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
            .sink { [weak self] _ in self?.endSession() }
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
        workout.start()        // warm HR during the pre-roll
        engine.beginCountdown()
    }

    private func endSession() {
        motion.stop()
        relay.flush()          // ship any remaining frames
        workout.stop()
    }
}
