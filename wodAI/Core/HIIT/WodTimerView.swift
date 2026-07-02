//
//  WodTimerView.swift
//  wodAI
//
//  Full-screen WOD timer shown during workout execution. Renders the current
//  round and a large H:MM:SS / MM:SS clock driven by the engine, with
//  hold-to-confirm controls for resume and finish.
//

import SwiftUI

struct WodTimerView: View {
    @ObservedObject var viewModel: HIITWorkoutViewModel

    var body: some View {
        let readout = viewModel.readout
        let running = viewModel.isExecuting
        let accent = running ? Color("Success") : Color("Warning")
        let showHours = viewModel.activeConfig.hasHourLongPhase || readout.displaySeconds >= 3600

        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                if let format = viewModel.currentWorkout?.format {
                    Text(format.uppercased())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(Color("SecondaryText"))
                        .padding(.top, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    if readout.totalRounds > 1 {
                        Text("ROUND \(readout.roundNumber) / \(readout.totalRounds)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .tracking(1)
                            .foregroundColor(accent)
                    }

                    if let label = readout.phaseLabel, !label.isEmpty {
                        Text(label.uppercased())
                            .font(.headline)
                            .tracking(1.5)
                            .foregroundColor(Color("SecondaryText"))
                    }

                    Text(clockString(readout.displaySeconds, showHours: showHours))
                        .font(.system(size: 76, weight: .semibold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(Color("PrimaryText"))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal)
                }

                Spacer()

                controls
            }
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        Group {
            if viewModel.isExecuting {
                HStack(spacing: 12) {
                    tapButton(title: "Pause", systemImage: "pause.fill") {
                        viewModel.pauseExecution()
                    }
                    HoldToConfirmButton(
                        title: "Finish",
                        systemImage: "checkmark",
                        style: .solid(Color("Success")),
                        action: { viewModel.finishExecution() }
                    )
                }
            } else {
                HStack(spacing: 12) {
                    tapButton(title: "Exit", systemImage: "xmark", tint: Color("Error")) {
                        viewModel.exitExecution()
                    }
                    HoldToConfirmButton(
                        title: "Resume",
                        systemImage: "play.fill",
                        style: .gradient,
                        action: { viewModel.resumeExecution() }
                    )
                    HoldToConfirmButton(
                        title: "Finish",
                        systemImage: "checkmark",
                        style: .solid(Color("Success")),
                        action: { viewModel.finishExecution() }
                    )
                }
            }
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
