//
//  WorkoutSensorRecorderTests.swift
//  wodAITests
//
//  The recorder against a fake backend: buffering and batching, retrying a
//  failed batch, skipping invalid readings, and cancellation.
//

import Testing
import Foundation
import Combine
@testable import wodAI

@MainActor
final class FakeTelemetryUploader: SessionTelemetryUploading {
    var createError: Error?
    var failNextAppend = false
    private(set) var created: [(workoutId: Int, source: SensorSource)] = []
    private(set) var appended: [[SensorFrame]] = []
    private(set) var completed: [String] = []
    private(set) var abandoned: [String] = []
    var summary = HeartRateSummary(avg: 150, max: 170, min: 100, coverage: 0.9,
                                   zoneSeconds: [0, 0, 60, 120, 0], trainingLoad: 11, estimatedCalories: nil)

    struct Failure: Error {}

    nonisolated func createSession(workoutId: Int, startedAt: Date, source: SensorSource) async throws -> CreatedSensorSession {
        try await MainActor.run {
            if let createError { throw createError }
            created.append((workoutId, source))
            return CreatedSensorSession(id: "42", zoneThresholds: [94, 112, 131, 150, 168])
        }
    }

    nonisolated func appendFrames(sessionId: String, frames: [SensorFrame]) async throws {
        try await MainActor.run {
            if failNextAppend {
                failNextAppend = false
                throw Failure()
            }
            appended.append(frames)
        }
    }

    nonisolated func completeSession(sessionId: String, endedAt: Date) async throws -> HeartRateSummary? {
        await MainActor.run {
            completed.append(sessionId)
            return summary
        }
    }

    nonisolated func abandonSession(sessionId: String) async throws {
        await MainActor.run { abandoned.append(sessionId) }
    }

    var allAppendedTimestamps: [Double] { appended.flatMap { $0.map(\.timestamp) } }
}

@MainActor
struct WorkoutSensorRecorderTests {
    private let start = Date(timeIntervalSince1970: 1_000)
    private let source = SensorSource(kind: .bluetoothHeartRate, deviceName: "Forerunner 265", brand: .garmin)
    private let samples = PassthroughSubject<HeartRateSample, Never>()
    private let uploader = FakeTelemetryUploader()

    private func makeRecorder() -> WorkoutSensorRecorder {
        let start = self.start
        return WorkoutSensorRecorder(
            uploader: uploader,
            samples: samples.eraseToAnyPublisher(),
            flushInterval: nil,
            now: { start }
        )
    }

    private func send(_ bpm: Int, at seconds: Double, contact: Bool? = true) {
        samples.send(HeartRateSample(date: start.addingTimeInterval(seconds), bpm: bpm, rrIntervalsMs: [], sensorContact: contact))
    }

    @Test func opensASessionWithItsSource() async {
        let recorder = makeRecorder()
        await recorder.start(workoutId: 7, source: source)
        #expect(recorder.sessionId == "42")
        #expect(recorder.zoneThresholds == [94, 112, 131, 150, 168])
        #expect(uploader.created.first?.workoutId == 7)
        #expect(uploader.created.first?.source == source)
    }

    @Test func uploadsBufferedReadingsInBatchesRelativeToStart() async {
        let recorder = makeRecorder()
        await recorder.start(workoutId: 7, source: source)
        send(120, at: 1)
        send(125, at: 2)
        await recorder.flush()
        send(130, at: 3)
        await recorder.flush()

        #expect(uploader.appended.count == 2)
        #expect(uploader.appended[0].map(\.timestamp) == [1, 2])
        #expect(uploader.appended[0].map(\.heartRate) == [120, 125])
        #expect(uploader.appended[1].map(\.timestamp) == [3])
    }

    @Test func resendsAFailedBatchWithTheNextOne() async {
        let recorder = makeRecorder()
        await recorder.start(workoutId: 7, source: source)
        send(120, at: 1)
        uploader.failNextAppend = true
        await recorder.flush()
        send(121, at: 2)
        await recorder.flush()

        #expect(uploader.allAppendedTimestamps == [1, 2])
    }

    @Test func skipsReadingsWithoutSkinContactOrZeroBpm() async {
        let recorder = makeRecorder()
        await recorder.start(workoutId: 7, source: source)
        send(0, at: 1)
        send(120, at: 2, contact: false)
        send(130, at: 3, contact: nil)
        await recorder.flush()

        #expect(uploader.allAppendedTimestamps == [3])
        #expect(recorder.points.map(\.bpm) == [130])
    }

    @Test func finishUploadsTheRestAndReturnsTheSummary() async {
        let recorder = makeRecorder()
        await recorder.start(workoutId: 7, source: source)
        send(150, at: 1)
        let summary = await recorder.finish()

        #expect(uploader.allAppendedTimestamps == [1])
        #expect(uploader.completed == ["42"])
        #expect(summary == uploader.summary)
        // Readings after the finish are ignored.
        send(160, at: 2)
        await recorder.flush()
        #expect(uploader.allAppendedTimestamps == [1])
    }

    @Test func abandonClosesTheSessionWithoutUploading() async {
        let recorder = makeRecorder()
        await recorder.start(workoutId: 7, source: source)
        send(150, at: 1)
        await recorder.abandon()

        #expect(uploader.abandoned == ["42"])
        #expect(uploader.appended.isEmpty)
        #expect(await recorder.finish() == nil)
    }

    @Test func recordsNothingWhenTheSessionCantBeCreated() async {
        uploader.createError = FakeTelemetryUploader.Failure()
        let recorder = makeRecorder()
        await recorder.start(workoutId: 7, source: source)
        send(150, at: 1)

        #expect(recorder.sessionId == nil)
        #expect(await recorder.finish() == nil)
        #expect(uploader.appended.isEmpty)
        #expect(uploader.completed.isEmpty)
    }
}
