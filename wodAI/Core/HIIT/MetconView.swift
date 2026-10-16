//
//  MetconView.swift
//  wodAI
//
//  One metcon: the WOD card, the athlete's stimulus for it (from their
//  session), the workout's own description folded away, and Start, which runs
//  the timer and then the completion screen. Opened from a session block (via the
//  block pager) or a saved workout; there is no feed entry point.

import SwiftUI
import UIKit

struct MetconView: View {
    @StateObject private var viewModel: HIITWorkoutViewModel
    @State private var aboutExpanded = false

    /// Opens a fixed metcon (a session block or a saved workout).
    /// `pieceId` is the session piece it was opened from, if any, so the
    /// result is logged against it. `onCompleted` runs once the result is saved.
    init(preloaded: HIITWorkoutItem, pieceId: Int? = nil, onCompleted: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: HIITWorkoutViewModel(
            preloaded: preloaded,
            pieceId: pieceId,
            advancesAfterCompletion: false,
            onCompleted: onCompleted
        ))
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            if let workout = viewModel.currentWorkout {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            workoutCard
                            if let stimulus = workout.pieceStimulus, !stimulus.isEmpty {
                                pieceStimulus(stimulus)
                            }
                            if !workout.stimulus.isEmpty {
                                Text(workout.stimulus)
                                    .font(.subheadline)
                                    .foregroundColor(Color("SecondaryText"))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }

                    bottomBar
                }
            }
        }
        // The workout's name ("Fran") when it has one, else "Metcon". Set as
        // a principal item too, like StrengthWorkoutView, so it reads as the
        // screen's heading rather than a small label.
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .onAppear {
            if let id = viewModel.currentWorkout?.id {
                viewModel.fetchIsSaved(workoutId: id)
            }
        }
        // Single full-screen cover that swaps between the running timer and the
        // completion screen. Using one cover (instead of two) avoids the SwiftUI
        // race where dismissing the timer cover and presenting a completion cover
        // in the same state update (as `finishExecution()` does) can silently drop
        // the second presentation. When `finishExecution()` sets `executionState`
        // to `.idle` and `completionDraft` at once, the cover stays up and its
        // content switches from the timer to the completion screen.
        .fullScreenCover(isPresented: Binding(
            get: {
                viewModel.isExecuting || viewModel.isPaused || viewModel.isCountingDown
                    || viewModel.completionDraft != nil
            },
            set: { _ in }
        )) {
            if let draft = viewModel.completionDraft {
                HIITWorkoutCompletionView(
                    draft: draft,
                    heartRate: viewModel.completionHeartRate,
                    errorMessage: viewModel.completionError,
                    isSubmitting: viewModel.isSubmittingCompletion,
                    onDone: { viewModel.submitCompletion($0) },
                    onSkip: { viewModel.skipCompletion($0) },
                    onDiscard: { viewModel.discardCompletion() }
                )
            } else {
                WodTimerView(viewModel: viewModel)
            }
        }
    }

    private var title: String {
        viewModel.currentWorkout?.title ?? "Metcon"
    }

    // MARK: - Workout card

    private var workoutCard: some View {
        HIITWorkoutCard(
            format: viewModel.currentWorkout?.format,
            displayText: viewModel.currentWorkout?.displayText ?? "",
            borderColor: cardBorderColor(for: viewModel.executionState),
            borderWidth: (viewModel.isExecuting || viewModel.isPaused) ? 1.5 : 1
        ) {
            bookmarkButton
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.isExecuting)
        .animation(.easeInOut(duration: 0.4), value: viewModel.isPaused)
    }

    // MARK: - Stimulus

    /// How the athlete should run this piece today: target RPE and pacing.
    private func pieceStimulus(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stimulus")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color("PrimaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The workout's own, generic description: long, so folded away.
    private func about(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { aboutExpanded.toggle() }
            } label: {
                HStack {
                    Text("About this workout")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .rotationEffect(.degrees(aboutExpanded ? 180 : 0))
                }
                .foregroundColor(Color("SecondaryText"))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(aboutExpanded ? "Hides the description" : "Shows the description")

            if aboutExpanded {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HeartRateChip()
            startButton
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .padding(.top, 12)
        .background(
            Color("Surface")
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -5)
        )
    }

    // MARK: - Action buttons

    private var startButton: some View {
        Button(action: { viewModel.startExecution() }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start").fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Bookmark button

    private var bookmarkButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            viewModel.toggleSaved()
        }) {
            Image(systemName: viewModel.isFavorited ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(viewModel.isFavorited ? Color("BrandPrimary") : Color("SecondaryText"))
                .scaleEffect(viewModel.isFavorited ? 1.15 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: viewModel.isFavorited)
        }
        .disabled(viewModel.currentWorkout == nil || viewModel.isExecuting || viewModel.isPaused)
    }

    // MARK: - Helpers

    private func cardBorderColor(for state: WorkoutExecutionState) -> Color {
        switch state {
        case .idle:         return Color("Border")
        case .countingDown: return Color("BrandPrimary").opacity(0.45)
        case .running:      return Color.green.opacity(0.45)
        case .paused:       return Color.red.opacity(0.3)
        }
    }
}

// MARK: - Previews

#Preview("Metcon") {
    NavigationStack {
        MetconView(preloaded: HIITWorkoutViewModel.preview().currentWorkout!)
    }
}

#Preview("Metcon in a session") {
    var workout = HIITWorkoutViewModel.preview().currentWorkout!
    workout.pieceStimulus = "RPE 8. Builds the engine to hold a hard pace while your legs burn. "
        + "Pick a pace you can repeat every round, and keep the wall balls unbroken."
    return NavigationStack {
        MetconView(preloaded: workout, pieceId: 1)
    }
}
