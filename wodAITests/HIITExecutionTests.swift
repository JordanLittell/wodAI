//
//  HIITExecutionTests.swift
//  wodAITests
//
//  Pure-logic tests for the watch execution layer: timing math, interval parsing,
//  frame wire round-trip, and the sensor buffer. No device/HealthKit needed.
//

import Testing
import Foundation
@testable import wodAI

private func payload(
    format: WorkoutFormat,
    constraintType: String,
    magnitude: Int,
    movements: [String] = [],
    interval: IntervalConfig? = nil
) -> WorkoutExecutionPayload {
    WorkoutExecutionPayload(
        sessionId: nil, wodId: 1, format: format,
        constraintType: constraintType, constraintMagnitude: magnitude,
        movements: movements, displayText: "", intervalConfig: interval,
        startedAt: Date()
    )
}

struct TimingModelTests {

    @Test func amrapCountsDownFromCap() {
        let model = TimingModel(payload: payload(format: .amrap, constraintType: "minutes", magnitude: 10))
        #expect(model.displaySeconds(at: 0) == 600)
        #expect(model.displaySeconds(at: 90) == 510)
        #expect(model.displaySeconds(at: 600) == 0)
        #expect(model.isComplete(at: 600))
        #expect(!model.isComplete(at: 599))
    }

    @Test func forTimeCountsUpAndNeverAutoCompletes() {
        let model = TimingModel(payload: payload(format: .forTime, constraintType: "rounds", magnitude: 3))
        #expect(model.displaySeconds(at: 0) == 0)
        #expect(model.displaySeconds(at: 125) == 125)
        #expect(!model.isComplete(at: 99_999))   // user-driven, no cap
    }

    @Test func emomMinuteAndMovementCycle() {
        let model = TimingModel(payload: payload(
            format: .emom, constraintType: "minutes", magnitude: 4,
            movements: ["Thruster", "Pull-up"]
        ))
        #expect(model.emomMinuteIndex(at: 0) == 0)
        #expect(model.emomMinuteIndex(at: 59) == 0)
        #expect(model.emomMinuteIndex(at: 60) == 1)
        #expect(model.emomCurrentMovement(at: 0) == "Thruster")
        #expect(model.emomCurrentMovement(at: 60) == "Pull-up")
        #expect(model.emomCurrentMovement(at: 120) == "Thruster")  // wraps
        // Clamp at the final minute.
        #expect(model.emomMinuteIndex(at: 99_999) == 3)
    }

    @Test func emomSecondsRemainingInMinute() {
        let model = TimingModel(payload: payload(format: .emom, constraintType: "minutes", magnitude: 5))
        #expect(model.emomSecondsRemainingInMinute(at: 0) == 60)
        #expect(model.emomSecondsRemainingInMinute(at: 15) == 45)
        #expect(model.emomSecondsRemainingInMinute(at: 75) == 45)
    }

    @Test func tabataPhaseAndRemaining() {
        let cfg = IntervalConfig(workSeconds: 20, restSeconds: 10, rounds: 8)
        let model = TimingModel(payload: payload(
            format: .tabata, constraintType: "intervals", magnitude: 8, interval: cfg
        ))
        // Round 1 work
        #expect(model.tabataPhase(at: 0) == .work)
        #expect(model.tabataPhaseRemaining(at: 0) == 20)
        #expect(model.tabataRound(at: 5) == 1)
        // Into rest of round 1
        #expect(model.tabataPhase(at: 25) == .rest)
        #expect(model.tabataPhaseRemaining(at: 25) == 5)
        // Round 2 work (cycle = 30s)
        #expect(model.tabataPhase(at: 30) == .work)
        #expect(model.tabataRound(at: 30) == 2)
        // Total cap = 8 * 30 = 240
        #expect(model.isComplete(at: 240))
    }
}

struct ExecutionEngineSyncTests {

    @Test func futureT0StartsCountdown() {
        let engine = ExecutionEngine(payload: payload(format: .forTime, constraintType: "rounds", magnitude: 3))
        engine.begin(mainStart: Date().addingTimeInterval(10))
        #expect(engine.isCounting)
        #expect(!engine.isRunning)
        #expect(engine.elapsed == 0)
        #expect(engine.countdownRemaining > 9 && engine.countdownRemaining <= 10)
    }

    @Test func pastT0JoinsRunningMidClock() {
        // A watch that launched late anchors to the same t0 and joins the clock in progress.
        let engine = ExecutionEngine(payload: payload(format: .forTime, constraintType: "rounds", magnitude: 3))
        engine.begin(mainStart: Date().addingTimeInterval(-5))
        #expect(engine.isRunning)
        #expect(abs(engine.elapsed - 5) < 0.5)
    }

    @Test func snapshotRestoreRunningPreservesElapsed() {
        let p = payload(format: .forTime, constraintType: "rounds", magnitude: 3)
        let original = ExecutionEngine(payload: p)
        original.begin(mainStart: Date().addingTimeInterval(-30))
        guard let snap = original.snapshot else { Issue.record("expected a snapshot"); return }
        #expect(snap.phase == .running)

        let restored = ExecutionEngine(payload: p)
        restored.restore(from: snap)
        #expect(restored.isRunning)
        #expect(abs(restored.elapsed - original.elapsed) < 0.5)
    }

    @Test func snapshotRestorePausedPreservesElapsed() {
        let p = payload(format: .forTime, constraintType: "rounds", magnitude: 3)
        let original = ExecutionEngine(payload: p)
        original.begin(mainStart: Date().addingTimeInterval(-12))
        original.pause()
        guard let snap = original.snapshot else { Issue.record("expected a snapshot"); return }
        #expect(snap.phase == .paused)

        let restored = ExecutionEngine(payload: p)
        restored.restore(from: snap)
        #expect(restored.isPaused)
        #expect(abs(restored.displaySeconds - original.displaySeconds) < 0.01)
    }

    @Test func restoreAfterCapElapsedFinishes() {
        // AMRAP cap = 60s; restoring a session whose t0 was 5 minutes ago settles into finished.
        let p = payload(format: .amrap, constraintType: "minutes", magnitude: 1)
        let snap = ExecutionEngine.Snapshot(phase: .running,
                                            mainStart: Date().addingTimeInterval(-300),
                                            pausedElapsed: 0, completedRounds: 0)
        let restored = ExecutionEngine(payload: p)
        restored.restore(from: snap)
        #expect(restored.isFinished)
    }
}

struct IntervalParsingTests {
    @Test func parsesExplicitSpec() {
        let cfg = IntervalConfig.parse(from: "Tabata: 30s on / 15s off x 6")
        #expect(cfg.workSeconds == 30)
        #expect(cfg.restSeconds == 15)
        #expect(cfg.rounds == 6)
    }

    @Test func parsesWorkRestWording() {
        let cfg = IntervalConfig.parse(from: "40 work, 20 rest, 5 rounds")
        #expect(cfg.workSeconds == 40)
        #expect(cfg.restSeconds == 20)
        #expect(cfg.rounds == 5)
    }

    @Test func fallsBackToClassicTabata() {
        let cfg = IntervalConfig.parse(from: "just do tabata")
        #expect(cfg == .tabataDefault)
    }
}

struct WorkoutFormatTests {
    @Test func classifiesFreeText() {
        #expect(WorkoutFormat(rawFormat: "AMRAP") == .amrap)
        #expect(WorkoutFormat(rawFormat: "For Time") == .forTime)
        #expect(WorkoutFormat(rawFormat: "EMOM") == .emom)
        #expect(WorkoutFormat(rawFormat: "Tabata") == .tabata)
        #expect(WorkoutFormat(rawFormat: "21-15-9") == .other)
        #expect(WorkoutFormat(rawFormat: nil) == .other)
    }
}

struct SensorFrameWireTests {
    @Test func compactRoundTripPreservesValues() {
        let frame = SensorFrame(timestamp: 1.5, accelX: 0.1, accelY: -0.2, accelZ: 0.9,
                                gyroX: 0.01, gyroY: 0.02, gyroZ: 0.03,
                                heartRate: 165, relativeAltitude: 0.4)
        let rebuilt = SensorFrame(timestamp: frame.timestamp, compactRow: frame.compactRow)
        #expect(rebuilt == frame)
    }

    @Test func batchExpandsToTimestampedFrames() {
        let batch = SensorFrameBatch(
            startOffsetMs: 1000, hz: 50,
            rows: [[0,0,1, nil,nil,nil, 160, nil,nil,nil,nil],
                   [0,0,1, nil,nil,nil, 161, nil,nil,nil,nil]]
        )
        let frames = batch.frames()
        #expect(frames.count == 2)
        #expect(frames[0].timestamp == 1.0)
        #expect(frames[1].timestamp == 1.02)   // +1/50s
        #expect(frames[1].heartRate == 161)
    }
}

struct SensorFrameBufferTests {
    @Test func appendDrainEmpties() {
        let buffer = SensorFrameBuffer()
        buffer.append([SensorFrame(timestamp: 0), SensorFrame(timestamp: 1)])
        #expect(buffer.count == 2)
        let drained = buffer.drain()
        #expect(drained.count == 2)
        #expect(buffer.count == 0)
    }

    @Test func reenqueuePreservesOrderAtFront() {
        let buffer = SensorFrameBuffer()
        buffer.append([SensorFrame(timestamp: 2)])
        buffer.reenqueue([SensorFrame(timestamp: 0), SensorFrame(timestamp: 1)])
        let all = buffer.drain()
        #expect(all.map(\.timestamp) == [0, 1, 2])
    }

    @Test func capDropsOldest() {
        let buffer = SensorFrameBuffer(capacity: 3)
        buffer.append((0..<5).map { SensorFrame(timestamp: Double($0)) })
        let all = buffer.drain()
        #expect(all.map(\.timestamp) == [2, 3, 4])
    }
}
