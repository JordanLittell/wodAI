//
//  WodTimerLiveActivity.swift
//  wodAIWidgets
//
//  Lock Screen and Dynamic Island presentation of a running WOD.
//
//  The clock is a `Text(timerInterval:)` over an absolute date range, so it
//  counts natively without the extension or the app running — that is what keeps
//  the timer readable with the phone locked or in a pocket. Only phase changes
//  cost an update.
//
//  Layout mirrors `WodTimerView` so the Lock Screen reads as the same timer:
//  round line only when there is more than one round, uppercased phase label,
//  monospaced digits, and the same Success/Warning run-vs-paused accent.
//

import SwiftUI
import WidgetKit
import ActivityKit

struct WodTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WodTimerActivityAttributes.self) { context in
            lockScreenView(context.state, title: context.attributes.workoutTitle)
                .padding()
                .activityBackgroundTint(Color("Background"))
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if state.totalRounds > 1 {
                        Text("\(state.roundNumber)/\(state.totalRounds)")
                            .font(.headline.monospacedDigit())
                            .foregroundColor(accent(state))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let label = state.phaseLabel, !label.isEmpty {
                        Text(label.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    clock(state)
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                }
            } compactLeading: {
                Image(systemName: state.isPaused ? "pause.fill" : "timer")
                    .foregroundColor(accent(state))
            } compactTrailing: {
                clock(state)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: state.isPaused ? "pause.fill" : "timer")
                    .foregroundColor(accent(state))
            }
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func lockScreenView(_ state: WodTimerActivityAttributes.ContentState,
                                title: String) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                Spacer()
                if state.totalRounds > 1 {
                    Text("ROUND \(state.roundNumber) / \(state.totalRounds)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(accent(state))
                }
            }

            if let label = state.phaseLabel, !label.isEmpty {
                Text(label.uppercased())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .tracking(1.5)
                    .foregroundColor(.secondary)
            }

            clock(state)
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
    }

    // MARK: - Clock

    /// A paused workout cannot use a live range — the clock has to stop — so it
    /// falls back to the static value captured at the pause.
    @ViewBuilder
    private func clock(_ state: WodTimerActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(clockString(state.pausedDisplaySeconds))
                .monospacedDigit()
                .foregroundColor(accent(state))
        } else if state.countsDown, let end = state.phaseEnd {
            Text(timerInterval: state.phaseStart...end, countsDown: true)
                .monospacedDigit()
                .foregroundColor(accent(state))
        } else {
            // Open-ended or count-up phase: count forward from the phase start.
            // The far end is only an upper bound the athlete will never reach.
            Text(timerInterval: state.phaseStart...(state.phaseEnd
                ?? state.phaseStart.addingTimeInterval(24 * 3600)),
                 countsDown: false)
                .monospacedDigit()
                .foregroundColor(accent(state))
        }
    }

    private func accent(_ state: WodTimerActivityAttributes.ContentState) -> Color {
        state.isPaused ? Color("Warning") : Color("Success")
    }

    private func clockString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}
