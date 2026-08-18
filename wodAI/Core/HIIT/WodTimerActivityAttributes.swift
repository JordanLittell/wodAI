//
//  WodTimerActivityAttributes.swift
//  wodAI
//
//  Shared contract between the app and the Live Activity widget extension.
//
//  TARGET MEMBERSHIP: this file must belong to BOTH the `wodAI` app target and
//  the `wodAIWidgets` extension target. The app builds the state, the extension
//  renders it.
//
//  The state carries the current phase as an absolute Date *window* rather than
//  a seconds-remaining number. That is deliberate: `Text(timerInterval:)` on the
//  Lock Screen counts within a date range with zero process time, so the clock
//  stays live even while the app is suspended or killed. Sending a countdown
//  number instead would freeze the moment the app stopped running.
//

import Foundation
import ActivityKit

struct WodTimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the current phase began.
        let phaseStart: Date
        /// When the current phase ends, or `nil` for an open-ended phase
        /// (uncapped "For Time"), which counts up indefinitely.
        let phaseEnd: Date?
        /// Whether this phase counts down to `phaseEnd` or up from `phaseStart`.
        let countsDown: Bool

        let phaseLabel: String?
        let roundNumber: Int
        let totalRounds: Int

        /// Paused activities cannot use a live date range — the clock has to
        /// stop — so the extension renders this static value instead.
        let isPaused: Bool
        let pausedDisplaySeconds: TimeInterval
    }

    /// Shown as the activity's heading; fixed for the life of the workout.
    let workoutTitle: String
}
