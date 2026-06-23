//
//  HIITWorkoutView.swift
//  wodAI
//

import SwiftUI

struct HIITWorkoutView: View {
    @StateObject private var viewModel: HIITWorkoutViewModel

    init(viewModel: HIITWorkoutViewModel = HIITWorkoutViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.currentWorkout == nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .tint(Color("BrandPrimary"))
            } else if let error = viewModel.error, viewModel.currentWorkout == nil {
                HIITErrorCard(error: error) { viewModel.loadWorkout() }
            } else if let workout = viewModel.currentWorkout {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Constraint row: badges + optional timer
                            HStack(spacing: 8) {
                                if viewModel.isExecuting || viewModel.isPaused {
                                    PulsingDot(color: viewModel.isExecuting ? .green : .orange)
                                }

                                Text(constraintBadgeText(workout))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("BrandPrimary"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color("BrandPrimary").opacity(0.12))
                                    .cornerRadius(8)

                                Text(workout.stimulus)
                                    .font(.caption)
                                    .foregroundColor(Color("SecondaryText"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color("Surface2"))
                                    .cornerRadius(8)

                                Spacer()

                                if viewModel.isExecuting || viewModel.isPaused {
                                    Text(formatTimer(viewModel.displaySeconds))
                                        .font(.system(.body, design: .monospaced).weight(.semibold))
                                        .foregroundColor(viewModel.isExecuting ? .green : .orange)
                                        .monospacedDigit()
                                }
                            }

                            // Workout display text card
                            Text(workout.displayText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(Color("PrimaryText"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color("Surface"))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            cardBorderColor(for: viewModel.executionState),
                                            lineWidth: (viewModel.isExecuting || viewModel.isPaused) ? 1.5 : 1
                                        )
                                )
                                .animation(.easeInOut(duration: 0.4), value: viewModel.isExecuting)
                                .animation(.easeInOut(duration: 0.4), value: viewModel.isPaused)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }

                    // Bottom action bar
                    Group {
                        if viewModel.isExecuting {
                            HStack(spacing: 12) {
                                pauseButton
                                finishButton
                            }
                        } else if viewModel.isPaused {
                            HStack(spacing: 12) {
                                exitButton
                                resumeButton
                                finishButton
                            }
                        } else {
                            VStack(spacing: 12) {
                                newWorkoutButton
                                startButton
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .padding(.top, 12)
                    .background(
                        Color("Surface")
                            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -5)
                    )
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isExecuting)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isPaused)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 56))
                        .foregroundColor(Color("TertiaryText"))
                    Text("No workout available")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    Button("Load Workout") { viewModel.loadWorkout() }
                        .foregroundColor(Color("BrandPrimary"))
                }
            }
        }
        .navigationTitle("WOD Generator")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadWorkout() }
        .overlay {
            if viewModel.showConfetti {
                ConfettiView { viewModel.showConfetti = false }
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Buttons

    private var startButton: some View {
        Button(action: { viewModel.startExecution() }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    private var newWorkoutButton: some View {
        Button(action: { viewModel.nextWorkout() }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Generate")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Surface"))
            .foregroundColor(Color("PrimaryText"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("Border"), lineWidth: 1)
            )
        }
    }

    private var pauseButton: some View {
        Button(action: { viewModel.pauseExecution() }) {
            HStack {
                Image(systemName: "pause.fill")
                Text("Pause")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Surface"))
            .foregroundColor(Color("PrimaryText"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("Border"), lineWidth: 1)
            )
        }
    }

    private var finishButton: some View {
        Button(action: { viewModel.finishExecution() }) {
            HStack {
                Image(systemName: "checkmark")
                Text("Finish")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.85))
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    private var resumeButton: some View {
        Button(action: { viewModel.resumeExecution() }) {
            Image(systemName: "play.fill")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    private var exitButton: some View {
        Button(action: { viewModel.exitExecution() }) {
            Text("Exit")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.red.opacity(0.25), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Helpers

    private func cardBorderColor(for state: WorkoutExecutionState) -> Color {
        switch state {
        case .idle:    return Color("Border")
        case .running: return Color.green.opacity(0.45)
        case .paused:  return Color.red.opacity(0.3)
        }
    }

    private func formatTimer(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // Converts stored seconds to a human-readable constraint label.
    // Time-based types store magnitude in seconds; all others use the raw magnitude.
    private func constraintBadgeText(_ workout: HIITWorkoutItem) -> String {
        let magnitude = workout.constraintMagnitude
        switch workout.constraintType.lowercased() {
        case "amrap":
            return "\(magnitude / 60) min AMRAP"
        case "emom":
            return "\(magnitude / 60) min EMOM"
        case "timecap", "time_cap", "time cap":
            return "\(magnitude / 60) min Cap"
        case "minutes", "min", "fortime", "for_time", "for time":
            let mins = magnitude / 60
            let secs = magnitude % 60
            return secs == 0 ? "\(mins) min" : "\(mins):\(String(format: "%02d", secs)) min"
        case "rounds", "round":
            return magnitude == 1 ? "1 Round" : "\(magnitude) Rounds"
        case "reps", "rep":
            return "\(magnitude) Reps"
        case "calories", "cals", "cal":
            return "\(magnitude) Cal"
        default:
            // Heuristic: large values are likely seconds
            if magnitude > 119 {
                return "\(magnitude / 60) min"
            }
            return "\(magnitude) \(workout.constraintType.capitalized)"
        }
    }
}

// MARK: - Pulsing dot

private struct PulsingDot: View {
    let color: Color
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(pulsing ? 1.4 : 0.8)
            .opacity(pulsing ? 1.0 : 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}

// MARK: - Confetti

private struct ConfettiView: View {
    let onDismiss: () -> Void

    private let pieces: [ConfettiPiece] = (0..<60).map { _ in ConfettiPiece() }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                FallingShape(piece: piece)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                onDismiss()
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1)
    let delay: Double = Double.random(in: 0...0.8)
    let duration: Double = Double.random(in: 1.8...2.8)
    let size: CGFloat = CGFloat.random(in: 6...12)
    let rotation: Double = Double.random(in: 0...360)
    let rotationSpeed: Double = Double.random(in: 180...540)
    let color: Color = [
        Color("BrandPrimary"), Color("BrandSecondary"),
        .green, .yellow, .orange, .pink, .purple
    ].randomElement()!
    let isCircle: Bool = Bool.random()
}

private struct FallingShape: View {
    let piece: ConfettiPiece
    @State private var fallen = false

    var body: some View {
        GeometryReader { geo in
            Group {
                if piece.isCircle {
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                } else {
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.5)
                        .rotationEffect(.degrees(fallen ? piece.rotation + piece.rotationSpeed : piece.rotation))
                }
            }
            .position(
                x: geo.size.width * piece.x,
                y: fallen ? geo.size.height + 20 : -20
            )
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeIn(duration: piece.duration)
                    .delay(piece.delay)
                ) {
                    fallen = true
                }
            }
        }
    }
}

// MARK: - Error card

private struct HIITErrorCard: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color("Warning"))
            Text("Unable to load workout")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
            Button("Try Again", action: retry)
                .foregroundColor(Color("BrandPrimary"))
        }
        .padding(40)
    }
}

// MARK: - Previews

#Preview("Workout loaded") {
    NavigationStack {
        HIITWorkoutView(viewModel: .preview())
    }
}

#Preview("Loading") {
    NavigationStack {
        HIITWorkoutView()
    }
}
