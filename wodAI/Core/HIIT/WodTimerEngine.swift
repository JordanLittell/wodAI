//
//  WodTimerEngine.swift
//  wodAI
//
//  An abstract WOD timer engine. A workout's timing is expressed as an ordered
//  list of segments; each segment repeats its phases `rounds` times, and each
//  phase counts up or down for a duration (or open-ended for a capless "For
//  Time"). This mirrors the backend `WodTimerConfig` and can express For Time,
//  AMRAP (with rest), EMOM/E2MOM, and Tabata.
//
//  The engine is a pure function of elapsed time: given the seconds elapsed
//  since the workout started (from the view model's Date-math clock), it reports
//  the current round, in-phase value, and completion. This keeps it decoupled
//  from Apollo and trivially testable.
//

import Foundation
import WodAiAPI

// MARK: - Engine model

enum PhaseDirection {
    case up
    case down
}

struct TimerPhase {
    /// Length of the phase in seconds. `nil` means open-ended (count-up "For
    /// Time" with no cap) — the phase never ends on its own.
    let duration: TimeInterval?
    let direction: PhaseDirection
    let label: String?
}

struct TimerSegment {
    /// Number of times this segment's phases repeat. Each repetition is a round.
    let rounds: Int
    let phases: [TimerPhase]
}

struct WodTimerConfig {
    let segments: [TimerSegment]

    /// Total rounds across every segment (Tabata = 8, single AMRAP = 1, …).
    var totalRounds: Int {
        segments.reduce(0) { $0 + max(0, $1.rounds) }
    }

    /// True if any phase runs an hour or longer, so the clock should render
    /// hours for the whole workout (e.g. a 60-minute cap).
    var hasHourLongPhase: Bool {
        segments.contains { segment in
            segment.phases.contains { ($0.duration ?? 0) >= 3600 }
        }
    }
}

/// A snapshot of the timer at a given elapsed time.
struct TimerReadout {
    let roundNumber: Int          // 1-based, across all segments
    let totalRounds: Int
    /// Remaining time for a countdown phase, or elapsed time for a count-up phase.
    let displaySeconds: TimeInterval
    let phaseLabel: String?
    let isComplete: Bool
}

// MARK: - Readout

extension WodTimerConfig {
    /// Map an absolute elapsed time onto the current round / phase / value.
    func readout(atElapsed elapsed: TimeInterval) -> TimerReadout {
        let total = totalRounds
        guard total > 0 else {
            return TimerReadout(roundNumber: 0, totalRounds: 0,
                                displaySeconds: 0, phaseLabel: nil, isComplete: true)
        }

        let clamped = max(0, elapsed)
        var cursor: TimeInterval = 0
        var roundNumber = 0

        for segment in segments {
            for _ in 0..<max(0, segment.rounds) {
                roundNumber += 1
                for phase in segment.phases {
                    guard let duration = phase.duration else {
                        // Open-ended count-up: we stay here indefinitely.
                        let inPhase = max(0, clamped - cursor)
                        return TimerReadout(roundNumber: roundNumber, totalRounds: total,
                                            displaySeconds: inPhase, phaseLabel: phase.label,
                                            isComplete: false)
                    }
                    if clamped < cursor + duration {
                        let inPhase = clamped - cursor
                        let value = phase.direction == .up ? inPhase : (duration - inPhase)
                        return TimerReadout(roundNumber: roundNumber, totalRounds: total,
                                            displaySeconds: max(0, value), phaseLabel: phase.label,
                                            isComplete: false)
                    }
                    cursor += duration
                }
            }
        }

        // Past the end of every phase: the workout is complete.
        let lastPhase = segments.last?.phases.last
        let endValue: TimeInterval = lastPhase?.direction == .up ? (lastPhase?.duration ?? 0) : 0
        return TimerReadout(roundNumber: total, totalRounds: total,
                            displaySeconds: endValue, phaseLabel: lastPhase?.label,
                            isComplete: true)
    }
}

// MARK: - Fallback

extension WodTimerConfig {
    /// Used when a workout has no backend `timingScheme`: a single round with a
    /// countdown to the cap, or an open-ended count-up when there is no cap.
    static func fallback(timeCap: Int?) -> WodTimerConfig {
        let phase: TimerPhase
        if let cap = timeCap, cap > 0 {
            phase = TimerPhase(duration: TimeInterval(cap), direction: .down, label: nil)
        } else {
            phase = TimerPhase(duration: nil, direction: .up, label: nil)
        }
        return WodTimerConfig(segments: [TimerSegment(rounds: 1, phases: [phase])])
    }

    /// A single-segment "For Time" config: capped countdown or open-ended count-up.
    /// Used by the editable time-cap control for For-Time workouts.
    static func forTime(timeCap: Int?) -> WodTimerConfig {
        fallback(timeCap: timeCap)
    }
}

// MARK: - Apollo mapping

/// Structural bridges so the generated (per-operation) timingScheme selection
/// sets can all feed the same engine initializer.
protocol TimingPhaseFragment {
    var durationSeconds: Int? { get }
    var direction: GraphQLEnum<WodAiAPI.PhaseDirection> { get }
    var label: String? { get }
}

protocol TimingSegmentFragment {
    associatedtype Phase: TimingPhaseFragment
    var rounds: Int { get }
    var phases: [Phase] { get }
}

protocol TimingSchemeFragment {
    associatedtype Segment: TimingSegmentFragment
    var version: Int { get }
    var segments: [Segment] { get }
}

extension WodTimerConfig {
    init<Scheme: TimingSchemeFragment>(fragment: Scheme) {
        self.segments = fragment.segments.map { segment in
            TimerSegment(
                rounds: segment.rounds,
                phases: segment.phases.map { phase in
                    TimerPhase(
                        duration: phase.durationSeconds.map(TimeInterval.init),
                        direction: phase.direction.value == .down ? .down : .up,
                        label: phase.label
                    )
                }
            )
        }
    }
}
