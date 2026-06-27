//
//  ExecutionEngine.swift
//  wodAI
//
//  SHARED logic, primarily driven on the Watch (the timing authority). Add Target
//  Membership to BOTH `wodAI` and `wodAI Watch` (the phone reuses the pure timing
//  model as a watch-less fallback).
//
//  Split into two layers:
//   • `TimingModel` — a PURE, value-type description of how a workout maps elapsed
//     time → on-screen state. No timers, no clock, no Combine. Fully unit-testable.
//   • `ExecutionEngine` — an ObservableObject that owns the FSM, anchors a monotonic
//     clock to `Date`, drives a display tick, and tracks user-driven round taps.
//

import Foundation
import Combine

// MARK: - Pure timing model (unit-testable)

/// What phase a Tabata-style interval is currently in.
enum IntervalPhase: Equatable {
    case work
    case rest
}

/// Pure mapping from elapsed seconds → display state for a given payload.
/// Every method is a deterministic function of `elapsed`, so tests can assert
/// boundary behavior without a running timer.
struct TimingModel {
    let payload: WorkoutExecutionPayload

    /// Primary value shown on the Time screen. Counts down for AMRAP/EMOM (toward 0),
    /// up for For Time/other. For Tabata, see `tabataPhaseRemaining` instead.
    func displaySeconds(at elapsed: TimeInterval) -> TimeInterval {
        let clamped = max(0, elapsed)
        if payload.format == .tabata {
            return tabataPhaseRemaining(at: clamped)
        }
        if payload.countsDown, let cap = payload.capSeconds {
            return max(0, cap - clamped)
        }
        return clamped
    }

    /// Whether the timer has reached a hard cap and the workout should auto-finish.
    /// User-driven formats (For Time / other with no cap) never auto-finish.
    func isComplete(at elapsed: TimeInterval) -> Bool {
        guard let cap = payload.capSeconds else { return false }
        return elapsed >= cap
    }

    // MARK: EMOM

    /// Zero-based minute index, clamped to the workout's minute count.
    func emomMinuteIndex(at elapsed: TimeInterval) -> Int {
        let lastMinute = max(0, payload.constraintMagnitude - 1)
        return min(Int(max(0, elapsed) / 60), lastMinute)
    }

    /// Movement to display for the current minute, cycling the movement list.
    /// Returns `nil` when no movements were provided.
    func emomCurrentMovement(at elapsed: TimeInterval) -> String? {
        guard !payload.movements.isEmpty else { return nil }
        let index = emomMinuteIndex(at: elapsed) % payload.movements.count
        return payload.movements[index]
    }

    /// Seconds remaining in the current EMOM minute (60 → 0).
    func emomSecondsRemainingInMinute(at elapsed: TimeInterval) -> TimeInterval {
        60 - (max(0, elapsed).truncatingRemainder(dividingBy: 60))
    }

    // MARK: Tabata

    private var cycleLength: TimeInterval {
        let cfg = payload.intervalConfig ?? .tabataDefault
        return TimeInterval(cfg.workSeconds + cfg.restSeconds)
    }

    /// One-based round number within the Tabata set.
    func tabataRound(at elapsed: TimeInterval) -> Int {
        let cfg = payload.intervalConfig ?? .tabataDefault
        guard cycleLength > 0 else { return 1 }
        let index = Int(max(0, elapsed) / cycleLength)
        return min(index + 1, cfg.rounds)
    }

    /// Current work/rest phase.
    func tabataPhase(at elapsed: TimeInterval) -> IntervalPhase {
        let cfg = payload.intervalConfig ?? .tabataDefault
        guard cycleLength > 0 else { return .work }
        let within = max(0, elapsed).truncatingRemainder(dividingBy: cycleLength)
        return within < TimeInterval(cfg.workSeconds) ? .work : .rest
    }

    /// Seconds remaining in the current work or rest interval.
    func tabataPhaseRemaining(at elapsed: TimeInterval) -> TimeInterval {
        let cfg = payload.intervalConfig ?? .tabataDefault
        guard cycleLength > 0 else { return 0 }
        let within = max(0, elapsed).truncatingRemainder(dividingBy: cycleLength)
        switch tabataPhase(at: elapsed) {
        case .work: return TimeInterval(cfg.workSeconds) - within
        case .rest: return cycleLength - within
        }
    }
}

// MARK: - Execution engine (observable FSM + clock)

final class ExecutionEngine: ObservableObject {

    enum State: Equatable {
        case idle
        /// Pre-roll countdown; associated value is the configured pre-roll length.
        case countdown(total: TimeInterval, startedAt: Date)
        /// Main workout running; `start` is when the timer hit 0, `priorElapsed` covers prior run segments after a pause.
        case running(start: Date, priorElapsed: TimeInterval)
        case paused(elapsed: TimeInterval)
        case finished(elapsed: TimeInterval)
    }

    @Published private(set) var state: State = .idle
    /// User-driven round/rep counter (AMRAP rounds, For Time rounds completed).
    @Published private(set) var completedRounds: Int = 0

    let payload: WorkoutExecutionPayload
    let timing: TimingModel
    let preRoll: TimeInterval

    /// Fired when the main timer starts (countdown → running) and when it finishes,
    /// so the owner can drive haptics / telemetry t=0 alignment.
    let didStartMainTimer = PassthroughSubject<Date, Never>()
    let didFinish = PassthroughSubject<TimeInterval, Never>()

    /// Pure boundary events the watch translates into haptics. No WatchKit here so the
    /// engine stays cross-platform and testable.
    enum Boundary: Equatable {
        case countdownTick(Int)        // final pre-roll ticks (3, 2, 1)
        case minute(Int)               // EMOM rolled to a new minute (1-based)
        case intervalPhase(IntervalPhase) // Tabata switched work↔rest
    }
    let boundary = PassthroughSubject<Boundary, Never>()

    private var tick: AnyCancellable?
    private var lastCountdownSecond: Int = -1
    private var lastMinuteIndex: Int = -1
    private var lastPhase: IntervalPhase?

    /// Absolute moment the MAIN timer hits t=0 (end of pre-roll). Shared by phone + watch
    /// so both anchor `elapsed` to the SAME instant and stay in lockstep. Set by
    /// `begin(mainStart:)` / `beginCountdown()` and used as the `.running` start.
    private var anchoredStart: Date?

    init(payload: WorkoutExecutionPayload, preRoll: TimeInterval = 10) {
        self.payload = payload
        self.timing = TimingModel(payload: payload)
        self.preRoll = preRoll
    }

    // MARK: Derived state for the UI

    /// Seconds elapsed in the MAIN workout (0 during countdown/idle).
    var elapsed: TimeInterval {
        switch state {
        case .idle, .countdown: return 0
        case .running(let start, let prior): return prior + Date().timeIntervalSince(start)
        case .paused(let elapsed): return elapsed
        case .finished(let elapsed): return elapsed
        }
    }

    /// Seconds left in the pre-roll countdown (10 → 0), or 0 when not counting down.
    var countdownRemaining: TimeInterval {
        guard case .countdown(let total, let startedAt) = state else { return 0 }
        return max(0, total - Date().timeIntervalSince(startedAt))
    }

    var isRunning: Bool { if case .running = state { return true }; return false }
    var isCounting: Bool { if case .countdown = state { return true }; return false }
    var isPaused: Bool { if case .paused = state { return true }; return false }
    var isFinished: Bool { if case .finished = state { return true }; return false }

    var displaySeconds: TimeInterval { timing.displaySeconds(at: elapsed) }

    // MARK: Lifecycle

    /// Begin, anchored to an ABSOLUTE main-start instant `t0` (end of pre-roll). The phone
    /// computes `t0` and sends it in the payload so the watch anchors to the same instant —
    /// both then show identical countdowns and elapsed time. If `t0` is already in the past
    /// (e.g. the watch launched late), we join the running clock mid-stream.
    func begin(mainStart t0: Date) {
        guard case .idle = state else { return }
        resetBoundaryTracking()
        anchoredStart = t0
        let remaining = t0.timeIntervalSinceNow
        if remaining > 0 {
            state = .countdown(total: remaining, startedAt: Date())
        } else {
            state = .running(start: t0, priorElapsed: 0)
            didStartMainTimer.send(t0)
        }
        startTick()
    }

    /// Begin the pre-roll countdown anchored to `now + preRoll` (watch-less / local default).
    func beginCountdown() {
        begin(mainStart: Date().addingTimeInterval(preRoll))
    }

    /// Skip straight into the running state (used when there is no pre-roll).
    func startNow() {
        let now = Date()
        anchoredStart = now
        state = .running(start: now, priorElapsed: 0)
        didStartMainTimer.send(now)
        startTick()
    }

    private func resetBoundaryTracking() {
        lastCountdownSecond = -1
        lastMinuteIndex = -1
        lastPhase = nil
    }

    func pause() {
        guard isRunning else { return }
        state = .paused(elapsed: elapsed)
        tick?.cancel()
    }

    func resume() {
        guard case .paused(let elapsed) = state else { return }
        state = .running(start: Date(), priorElapsed: elapsed)
        startTick()
    }

    /// User-marked round (AMRAP / For Time). Auto-finishes For Time when the target is hit.
    func completeRound() {
        completedRounds += 1
        if let target = payload.roundTarget, completedRounds >= target {
            finish()
        }
    }

    func finish() {
        let final = elapsed
        tick?.cancel()
        state = .finished(elapsed: final)
        didFinish.send(final)
    }

    // MARK: Persistence (phone-side restore across app relaunch)

    /// A compact, `Codable` description of an in-flight session, enough to rebuild the
    /// engine after the app is killed. Running/countdown restore exactly (anchored to the
    /// shared `mainStart`); paused restores the frozen elapsed.
    struct Snapshot: Codable {
        enum Phase: String, Codable { case countdown, running, paused }
        var phase: Phase
        var mainStart: Date            // shared t0 (== payload.startedAt)
        var pausedElapsed: TimeInterval
        var completedRounds: Int
    }

    /// Non-nil only while a session is in flight (idle/finished produce no snapshot).
    var snapshot: Snapshot? {
        switch state {
        case .countdown:
            guard let t0 = anchoredStart else { return nil }
            return Snapshot(phase: .countdown, mainStart: t0, pausedElapsed: 0, completedRounds: completedRounds)
        case .running(let start, let prior):
            // Effective t0 (where elapsed == 0) is start shifted back by any prior segments.
            return Snapshot(phase: .running, mainStart: start.addingTimeInterval(-prior), pausedElapsed: 0, completedRounds: completedRounds)
        case .paused(let elapsed):
            return Snapshot(phase: .paused, mainStart: anchoredStart ?? Date(), pausedElapsed: elapsed, completedRounds: completedRounds)
        case .idle, .finished:
            return nil
        }
    }

    /// Rebuild engine state from a persisted snapshot. If the workout's time cap already
    /// elapsed while the app was closed, it settles directly into `.finished`.
    func restore(from snapshot: Snapshot) {
        guard case .idle = state else { return }
        resetBoundaryTracking()
        anchoredStart = snapshot.mainStart
        completedRounds = snapshot.completedRounds
        switch snapshot.phase {
        case .countdown:
            let remaining = snapshot.mainStart.timeIntervalSinceNow
            if remaining > 0 {
                state = .countdown(total: remaining, startedAt: Date())
            } else {
                state = .running(start: snapshot.mainStart, priorElapsed: 0)
                didStartMainTimer.send(snapshot.mainStart)
            }
        case .running:
            state = .running(start: snapshot.mainStart, priorElapsed: 0)
            didStartMainTimer.send(snapshot.mainStart)
        case .paused:
            state = .paused(elapsed: snapshot.pausedElapsed)
        }
        startTick()
        if case .running = state, timing.isComplete(at: elapsed) { finish() }
    }

    // MARK: Tick driver

    private func startTick() {
        tick?.cancel()
        // 10Hz keeps countdown/Tabata-phase transitions visually crisp; cheap on watchOS.
        tick = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.onTick() }
    }

    private func onTick() {
        switch state {
        case .countdown:
            let secondsLeft = Int(ceil(countdownRemaining))
            if secondsLeft != lastCountdownSecond, (1...3).contains(secondsLeft) {
                lastCountdownSecond = secondsLeft
                boundary.send(.countdownTick(secondsLeft))
            }
            if countdownRemaining <= 0 {
                // Anchor the running clock to the shared t0 (not Date()), so the phone and
                // watch — each firing its own tick — compute the exact same elapsed time.
                let start = anchoredStart ?? Date()
                state = .running(start: start, priorElapsed: 0)
                didStartMainTimer.send(start)
            }
        case .running:
            emitRunningBoundaries()
            if timing.isComplete(at: elapsed) {
                finish()
                return
            }
        default:
            break
        }
        objectWillChange.send()
    }

    /// Detect EMOM minute rollovers and Tabata phase switches, emitting one event each.
    private func emitRunningBoundaries() {
        switch payload.format {
        case .emom:
            let index = timing.emomMinuteIndex(at: elapsed)
            if index != lastMinuteIndex {
                lastMinuteIndex = index
                boundary.send(.minute(index + 1))
            }
        case .tabata:
            let phase = timing.tabataPhase(at: elapsed)
            if phase != lastPhase {
                lastPhase = phase
                boundary.send(.intervalPhase(phase))
            }
        default:
            break
        }
    }
}
