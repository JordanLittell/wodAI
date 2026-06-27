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
    var isFinished: Bool { if case .finished = state { return true }; return false }

    var displaySeconds: TimeInterval { timing.displaySeconds(at: elapsed) }

    // MARK: Lifecycle

    /// Begin the pre-roll countdown. Sensor collection / HKWorkoutSession should
    /// already be starting (to warm the HR sensor) when this is called.
    func beginCountdown() {
        guard case .idle = state else { return }
        lastCountdownSecond = -1
        lastMinuteIndex = -1
        lastPhase = nil
        state = .countdown(total: preRoll, startedAt: Date())
        startTick()
    }

    /// Skip straight into the running state (used when there is no pre-roll).
    func startNow() {
        let now = Date()
        state = .running(start: now, priorElapsed: 0)
        didStartMainTimer.send(now)
        startTick()
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
                let now = Date()
                state = .running(start: now, priorElapsed: 0)
                didStartMainTimer.send(now)
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
