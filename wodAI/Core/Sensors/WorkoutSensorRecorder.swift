//
//  WorkoutSensorRecorder.swift
//  wodAI
//
//  Records one workout's heart rate to the backend: opens a session when the
//  clock starts, uploads readings in batches while it runs, and closes it at
//  the finish to get the server's summary back.
//
//  Heart rate never blocks or fails the workout. If the session can't be
//  created there's simply no recording; a failed batch stays buffered and is
//  sent again with the next one (the server ignores frames it already has).
//

import Foundation
import Combine

/// The backend calls the recorder makes, behind a protocol so tests can fake
/// them. `ApolloSessionTelemetryUploader` is the real one.
protocol SessionTelemetryUploading {
    func createSession(workoutId: Int, startedAt: Date, source: SensorSource) async throws -> CreatedSensorSession
    func appendFrames(sessionId: String, frames: [SensorFrame]) async throws
    func completeSession(sessionId: String, endedAt: Date) async throws -> HeartRateSummary?
    func abandonSession(sessionId: String) async throws
}

struct CreatedSensorSession: Equatable {
    let id: String
    /// bpm where zones 1–5 start, for the live zone.
    let zoneThresholds: [Int]
}

@MainActor
final class WorkoutSensorRecorder {
    private(set) var sessionId: String?
    private(set) var zoneThresholds: [Int] = []
    /// Every valid reading so far, for the completion screen's chart.
    private(set) var points: [HeartRatePoint] = []

    private let uploader: SessionTelemetryUploading
    private let samples: AnyPublisher<HeartRateSample, Never>
    private let now: () -> Date
    /// Upper bound on frames held for upload, so a long outage can't grow
    /// memory without limit; the oldest are dropped first.
    private let maxBufferedFrames: Int
    /// How often to upload while the workout runs; nil for no timer (tests
    /// call `flush()` themselves).
    private let flushInterval: TimeInterval?

    private var startedAt: Date?
    private var buffer: [SensorFrame] = []
    private var subscription: AnyCancellable?
    private var flushTimer: AnyCancellable?
    private var isFlushing = false
    private var isFinished = false

    init(
        uploader: SessionTelemetryUploading,
        samples: AnyPublisher<HeartRateSample, Never>,
        flushInterval: TimeInterval? = 15,
        maxBufferedFrames: Int = 7_200,
        now: @escaping () -> Date = Date.init
    ) {
        self.uploader = uploader
        self.samples = samples
        self.flushInterval = flushInterval
        self.maxBufferedFrames = maxBufferedFrames
        self.now = now
    }

    /// Starts listening right away (so the first seconds aren't lost while the
    /// session is being created) and opens the session.
    func start(workoutId: Int, source: SensorSource) async {
        let start = now()
        startedAt = start
        subscription = samples.sink { [weak self] sample in self?.record(sample) }
        do {
            let session = try await uploader.createSession(workoutId: workoutId, startedAt: start, source: source)
            guard !isFinished else {
                // Cancelled while the session was being created.
                try? await uploader.abandonSession(sessionId: session.id)
                return
            }
            sessionId = session.id
            zoneThresholds = session.zoneThresholds
            if let flushInterval {
                flushTimer = Timer.publish(every: flushInterval, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in Task { await self?.flush() } }
            }
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "CreateHIITSession"])
            stopListening()
        }
    }

    /// Sends what's buffered. Called on a timer while the workout runs.
    func flush() async {
        guard let sessionId, !isFlushing, !buffer.isEmpty else { return }
        isFlushing = true
        defer { isFlushing = false }
        let batch = buffer
        do {
            try await uploader.appendFrames(sessionId: sessionId, frames: batch)
            // By timestamp, not count: frames may have arrived (or been trimmed)
            // while the batch was in flight.
            if let lastSent = batch.last?.timestamp {
                buffer.removeAll { $0.timestamp <= lastSent }
            }
        } catch {
            // Keep them; they go out with the next batch.
            TelemetryService.captureError(error, tags: ["operation": "AppendSensorFrames"])
        }
    }

    /// Uploads the rest and closes the session. Nil when nothing was recorded
    /// or the server couldn't summarize it.
    func finish() async -> HeartRateSummary? {
        guard !isFinished else { return nil }
        isFinished = true
        stopListening()
        guard let sessionId else { return nil }
        // A timer batch may be in flight; let it land before the final one, or
        // it could arrive after the session closes and be ignored.
        while isFlushing { try? await Task.sleep(nanoseconds: 50_000_000) }
        await flush()
        if !buffer.isEmpty { await flush() } // one retry for the final batch
        do {
            return try await uploader.completeSession(sessionId: sessionId, endedAt: now())
        } catch {
            TelemetryService.captureError(error, tags: ["operation": "CompleteHIITSession"])
            return nil
        }
    }

    /// The run was cancelled: drop the session.
    func abandon() async {
        guard !isFinished else { return }
        isFinished = true
        stopListening()
        buffer.removeAll()
        guard let sessionId else { return }
        try? await uploader.abandonSession(sessionId: sessionId)
    }

    private func stopListening() {
        subscription?.cancel()
        subscription = nil
        flushTimer = nil
    }

    private func record(_ sample: HeartRateSample) {
        guard let startedAt, sample.isValid else { return }
        let seconds = sample.date.timeIntervalSince(startedAt)
        guard seconds >= 0 else { return }
        // Millisecond precision: the server dedups retried frames on
        // (session, timestamp), so a resent frame must carry the same value.
        let timestamp = (seconds * 1000).rounded() / 1000
        buffer.append(SensorFrame(timestamp: timestamp, heartRate: Double(sample.bpm), rrIntervalsMs: sample.rrIntervalsMs))
        if buffer.count > maxBufferedFrames {
            buffer.removeFirst(buffer.count - maxBufferedFrames)
        }
        points.append(HeartRatePoint(seconds: timestamp, bpm: sample.bpm))
    }
}
