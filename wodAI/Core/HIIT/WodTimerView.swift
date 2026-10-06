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
        let readout = viewModel.readout
        let running = viewModel.isExecuting
        let accent = running ? Color("Success") : Color("Warning")
        let showHours = viewModel.activeConfig.hasHourLongPhase || readout.displaySeconds >= 3600

        return VStack(spacing: 0) {
            HeartRateHUD(zoneThresholds: viewModel.heartRateZoneThresholds)
                .padding(.top, 12)

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
                    .padding(.horizontal)
            }

            Spacer()

            controls
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
                HStack(spacing: 12) {
                    tapButton(title: "Exit", systemImage: "xmark", tint: Color("Error")) {
                        viewModel.exitExecution()
                    }
                    tapButton(title: "Resume", systemImage: "play.fill",
                              tint: Color("BrandPrimary")) {
                        viewModel.resumeExecution()
                    }
                }
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
