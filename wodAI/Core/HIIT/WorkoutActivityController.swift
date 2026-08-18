//
//  WorkoutActivityController.swift
//  wodAI
//
//  Owns the Live Activity for a running workout: Lock Screen and Dynamic Island.
//
//  The clock itself needs no updates — the state carries an absolute date window
//  that `Text(timerInterval:)` counts through on its own. We only push an update
//  when the *phase* changes (new round, Work → Rest), which is a handful of
//  updates across a workout rather than one per second.
//

import Foundation
import ActivityKit

final class WorkoutActivityController {

    private var activity: Activity<WodTimerActivityAttributes>?
    /// Guards against redundant updates: only push when the phase actually moves.
    private var lastPhaseKey: String?

    var isActive: Bool { activity != nil }

    // MARK: - Lifecycle

    func start(workoutTitle: String, config: WodTimerConfig, workoutStart: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }

        let state = Self.state(config: config,
                               workoutStart: workoutStart,
                               elapsed: 0,
                               isPaused: false)
        lastPhaseKey = Self.phaseKey(state)

        do {
            activity = try Activity.request(
                attributes: WodTimerActivityAttributes(workoutTitle: workoutTitle),
                content: ActivityContent(state: state, staleDate: config.totalDuration
                    .map { workoutStart.addingTimeInterval($0 + 60) })
            )
        } catch {
            // A failed Live Activity must never disrupt the workout — the
            // in-app timer is unaffected.
            TelemetryService.captureError(error, tags: ["operation": "WorkoutActivity.start"])
        }
    }

    /// Push a new phase to the activity, but only when the phase has actually
    /// changed. Called from the existing 1s tick.
    func update(config: WodTimerConfig, workoutStart: Date, elapsed: TimeInterval, isPaused: Bool) {
        guard let activity else { return }

        let state = Self.state(config: config,
                               workoutStart: workoutStart,
                               elapsed: elapsed,
                               isPaused: isPaused)
        let key = Self.phaseKey(state)
        guard key != lastPhaseKey else { return }
        lastPhaseKey = key

        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        lastPhaseKey = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    // MARK: - State construction

    /// Identity of a phase for change detection — pause transitions count as a
    /// change so the activity switches to and from the frozen clock.
    private static func phaseKey(_ state: WodTimerActivityAttributes.ContentState) -> String {
        "\(state.roundNumber)|\(state.phaseLabel ?? "")|\(state.phaseStart.timeIntervalSince1970)|\(state.isPaused)"
    }

    /// Maps elapsed time onto the phase window containing it, using the same
    /// `timeline` projection that drives audio cues so the Lock Screen and the
    /// beeps can never disagree about where a phase starts.
    private static func state(config: WodTimerConfig,
                              workoutStart: Date,
                              elapsed: TimeInterval,
                              isPaused: Bool) -> WodTimerActivityAttributes.ContentState {
        let timeline = config.timeline
        let current = timeline.last { $0.offset <= elapsed } ?? timeline.first

        let offset = current?.offset ?? 0
        let phase = current?.phase
        let start = workoutStart.addingTimeInterval(offset)

        return WodTimerActivityAttributes.ContentState(
            phaseStart: start,
            phaseEnd: phase?.duration.map { start.addingTimeInterval($0) },
            countsDown: phase?.direction == .down,
            phaseLabel: phase?.label,
            roundNumber: current?.roundNumber ?? 1,
            totalRounds: config.totalRounds,
            isPaused: isPaused,
            pausedDisplaySeconds: config.readout(atElapsed: elapsed).displaySeconds
        )
    }
}
