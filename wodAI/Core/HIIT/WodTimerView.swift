//
//  WodTimerView.swift
//  wodAI
//
//  Full-screen WOD timer shown during workout execution. Renders the current
//  round and a large H:MM:SS / MM:SS clock driven by the engine, with
//  swipe-to-confirm controls for exit and finish. A "Workout" / "Timer" button
//  just above the controls switches between the big clock and the metcon
//  itself under a compact clock (tapping that clock also goes back); the
//  controls stay in both modes, and both read the same live readout.
//

import SwiftUI
import UIKit

struct WodTimerView: View {
    @ObservedObject var viewModel: HIITWorkoutViewModel
    /// Showing the metcon under a compact clock instead of the big timer.
    /// Resets to the big timer each time the cover opens.
    @State private var showsWorkout: Bool
    @Namespace private var clockSpace

    init(viewModel: HIITWorkoutViewModel, startsOnWorkout: Bool = false) {
        self.viewModel = viewModel
        self._showsWorkout = State(initialValue: startsOnWorkout)
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            if let remaining = viewModel.countdownRemaining {
                countdownView(remaining)
            } else {
                runningView
            }
        }
    }

    // MARK: - Get-ready countdown

    private func countdownView(_ remaining: Int) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("GET READY")
                    .font(.title2)
                    .fontWeight(.bold)
                    .tracking(3)
                    .foregroundColor(Color("SecondaryText"))

                Text("\(remaining)")
                    .font(.system(size: 200, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(Color("BrandPrimary"))
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: remaining)
                    .padding(.horizontal)
            }

            Spacer()

            tapButton(title: "Cancel", systemImage: "xmark", tint: Color("Error")) {
                viewModel.cancelCountdown()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Running timer

    private var runningView: some View {
        VStack(spacing: 0) {
            HeartRateHUD(zoneThresholds: viewModel.heartRateZoneThresholds)
                .padding(.top, 12)

            if showsWorkout {
                workoutMode
            } else {
                timerMode
            }

            controls
        }
    }

    private var accent: Color {
        viewModel.isExecuting ? Color("Success") : Color("Warning")
    }

    private var showHours: Bool {
        viewModel.activeConfig.hasHourLongPhase || viewModel.readout.displaySeconds >= 3600
    }

    private func setShowsWorkout(_ value: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.snappy) { showsWorkout = value }
    }

    // MARK: - Timer mode

    private var timerMode: some View {
        let readout = viewModel.readout

        return VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                if readout.totalRounds > 1 {
                    Text("ROUND \(readout.roundNumber) / \(readout.totalRounds)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundColor(accent)
                }

                if let label = readout.phaseLabel, !label.isEmpty {
                    Text(label.uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .tracking(1.5)
                        .foregroundColor(Color("SecondaryText"))
                }

                Text(clockString(readout.displaySeconds, showHours: showHours))
                    .font(.system(size: 130, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(Color("PrimaryText"))
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "clock", in: clockSpace)
                    .padding(.horizontal)
            }

            Spacer()

            modeToggleButton(title: "Workout", systemImage: "list.bullet.rectangle",
                             accessibilityLabel: "Show workout") {
                setShowsWorkout(true)
            }
        }
    }

    /// Switches between the two views; sits in the same spot, just above the
    /// controls, in both.
    private func modeToggleButton(title: String, systemImage: String,
                                  accessibilityLabel: String,
                                  action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color("PrimaryText"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color("Surface2")))
                .overlay(Capsule().stroke(Color("Border"), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .padding(.bottom, 16)
    }

    // MARK: - Workout mode

    private var workoutMode: some View {
        VStack(spacing: 0) {
            compactClock
                .padding(.horizontal)
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    workoutCard
                    if let stimulus = viewModel.currentWorkout?.pieceStimulus, !stimulus.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Stimulus")
                                .font(.headline)
                                .foregroundColor(Color("PrimaryText"))
                            Text(stimulus)
                                .font(.subheadline)
                                .foregroundColor(Color("PrimaryText"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
            }

            // Outside the scroll view, so it stays put above the controls.
            modeToggleButton(title: "Timer", systemImage: "timer",
                             accessibilityLabel: "Show full timer") {
                setShowsWorkout(false)
            }
            .padding(.top, 8)
        }
    }

    /// Round, phase and the running clock in one bar. Tapping it is a shortcut
    /// back to the big timer (the Timer button is the visible way).
    private var compactClock: some View {
        let readout = viewModel.readout

        return Button { setShowsWorkout(false) } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if readout.totalRounds > 1 {
                        Text("R \(readout.roundNumber)/\(readout.totalRounds)")
                            .font(.headline)
                            .foregroundColor(accent)
                    }
                    if let label = readout.phaseLabel, !label.isEmpty {
                        Text(label.uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(1)
                            .foregroundColor(Color("SecondaryText"))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Text(clockString(readout.displaySeconds, showHours: showHours))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(Color("PrimaryText"))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "clock", in: clockSpace)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color("Surface"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.5), lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Show full timer")
    }

    /// The metcon, read-only: no swaps or adjustments mid-run.
    @ViewBuilder
    private var workoutCard: some View {
        if let workout = viewModel.currentWorkout {
            if !workout.lines.isEmpty {
                HIITPrescriptionCard(
                    format: workout.format,
                    lines: workout.lines,
                    parts: workout.parts
                ) { EmptyView() }
            } else {
                HIITWorkoutCard(
                    format: workout.format,
                    displayText: workout.displayText
                ) { EmptyView() }
            }
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 12) {
            if viewModel.isExecuting {
                tapButton(title: "Pause", systemImage: "pause.fill") {
                    viewModel.pauseExecution()
                }
            } else {
                tapButton(title: "Resume", systemImage: "play.fill",
                          tint: Color("BrandPrimary")) {
                    viewModel.resumeExecution()
                }
                SwipeToConfirmButton(
                    title: "Swipe to exit",
                    systemImage: "xmark",
                    tint: Color("Error"),
                    action: { viewModel.exitExecution() }
                )
            }

            SwipeToConfirmButton(
                title: "Swipe to finish",
                action: { viewModel.finishExecution() }
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
        .padding(.top, 12)
        .background(
            Color("Surface")
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isExecuting)
    }

    private func tapButton(title: String, systemImage: String, tint: Color? = nil,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(tint == nil ? Color("PrimaryText") : .white)
            .background(tint ?? Color("Surface2"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(tint == nil ? Color("Border") : .clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Formatting

    private func clockString(_ seconds: TimeInterval, showHours: Bool) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if showHours {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Previews

#Preview("Timer") {
    WodTimerView(viewModel: HIITWorkoutViewModel.preview())
}

#Preview("Timer, workout showing") {
    WodTimerView(viewModel: HIITWorkoutViewModel.preview(), startsOnWorkout: true)
}
