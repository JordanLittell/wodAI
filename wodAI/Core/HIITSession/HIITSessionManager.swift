//
//  HIITSessionManager.swift
//  wodAI
//
//  Owns the live-session lifecycle on the phone: creates the backend session, hands the
//  workout to the watch, drains the sensor buffer on a 10s cadence into AppendSensorFrames,
//  and finalizes on finish/abandon.
//
//  Wire `start(workout:)` into the existing HIIT "Start" action (where
//  HIITWorkoutViewModel.startExecution() is invoked). The watch becomes the timing
//  authority; the phone's local timer remains the watch-less fallback.
//

import Foundation
import Combine

@MainActor
final class HIITSessionManager: ObservableObject {
    static let shared = HIITSessionManager()

    @Published private(set) var isActive = false
    @Published private(set) var sessionId: String?

    let buffer = SensorFrameBuffer()
    lazy var bridge = PhoneConnectivityBridge(buffer: buffer)
    private let service = HIITSessionService()

    /// How often buffered frames are flushed to the API.
    private let flushInterval: TimeInterval = 10
    private var flushTimer: Timer?
    private var startedAt = Date()

    /// Call once at app launch to bring up WatchConnectivity.
    func activate() { bridge.activate() }

    /// Begin a live session. `movements` is the ordered movement list (for EMOM display);
    /// pass the workout's components when available, else leave empty.
    func start(workout: HIITWorkoutItem, movements: [String] = []) async {
        guard !isActive else { return }
        startedAt = Date()

        // Create the backend session record. If it fails (e.g. backend not live yet),
        // we still drive the watch locally — frames simply won't upload.
        do {
            sessionId = try await service.create(wodId: workout.id, startedAt: startedAt)
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
            startedAt: startedAt
        )

        bridge.sendStart(payload)
        startFlushTimer()
        isActive = true
    }

    func finish() async {
        stopFlushTimer()
        bridge.sendStop()
        await flush()                       // ship remaining frames
        if let id = sessionId {
            try? await service.complete(sessionId: id, endedAt: Date())
        }
        teardown()
    }

    func abandon() async {
        stopFlushTimer()
        bridge.sendStop()
        if let id = sessionId {
            try? await service.abandon(sessionId: id)
        }
        teardown()
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

    private func teardown() {
        isActive = false
        sessionId = nil
    }
}
