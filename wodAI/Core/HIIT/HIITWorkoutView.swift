//
//  HIITWorkoutView.swift
//  wodAI

import SwiftUI
import UIKit

struct HIITWorkoutView: View {
    @StateObject private var viewModel: HIITWorkoutViewModel
    /// Drives the filter row's fallback from an even three-way split to a stack.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init() {
        self._viewModel = StateObject(wrappedValue: HIITWorkoutViewModel.shared)
    }

    init(preloaded: HIITWorkoutItem) {
        self._viewModel = StateObject(wrappedValue: HIITWorkoutViewModel(preloaded: preloaded))
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            if let error = viewModel.error, viewModel.currentWorkout == nil {
                HIITErrorCard(error: error) { viewModel.loadWorkout() }
            } else if viewModel.currentWorkout != nil || viewModel.isLoading {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            filterBar
                            if viewModel.isLoading {
                                HIITSkeletonCard()
                            } else {
                                workoutCard
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }

                    if viewModel.currentWorkout != nil {
                        bottomBar
                    }
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
        .toolbar {
            if !viewModel.filterSelection.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    clearFiltersButton
                }
            }
        }
        .onAppear {
            viewModel.loadFilterCatalog()
            if let id = viewModel.currentWorkout?.id {
                viewModel.fetchIsSaved(workoutId: id)
            } else {
                viewModel.loadWorkout()
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

    // MARK: - Filter bar

    /// A row of single-select dropdowns, one per filter dimension, dividing the
    /// full width evenly between them.
    ///
    /// Deliberately *not* in a horizontal ScrollView: `.frame(maxWidth:
    /// .infinity)` resolves against content size inside one, so the even split
    /// would silently collapse back to intrinsic widths. With three dimensions
    /// the row fits without scrolling anyway.
    ///
    /// "Clear" lives in the navigation bar rather than here. A fourth element
    /// appearing on first selection would resize all three chips mid-interaction,
    /// which is exactly the jarring reflow this layout exists to remove.
    private var filterBar: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // At accessibility sizes an even three-way split can't hold a
                // legible label, so the chips stack full-width instead.
                VStack(spacing: 6) { filterChips }
            } else {
                HStack(spacing: 6) { filterChips }
            }
        }
        // Room for the chips' strokes so nothing clips against the card below.
        .padding(.vertical, 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.filterSelection)
    }

    @ViewBuilder
    private var filterChips: some View {
        ForEach(FilterDimension.allCases) { dimension in
            if let options = viewModel.filterOptions[dimension] {
                filterMenu(for: dimension, options: options)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func filterMenu(for dimension: FilterDimension, options: [ResolvedFilterOption]) -> some View {
        let selected = viewModel.filterSelection[dimension]

        return Menu {
            Button {
                viewModel.setFilter(dimension, to: nil)
            } label: {
                // A checkmark on "Any" makes the unselected state explicit
                // rather than leaving the menu looking like nothing is set.
                menuRowLabel("Any \(dimension.title.lowercased())", isSelected: selected == nil)
            }

            Divider()

            // Every option here yields at least one workout — the view model
            // drops the rest — so there are no dead or disabled rows, and no
            // counts to advertise how small the catalog is.
            ForEach(options) { option in
                Button {
                    viewModel.setFilter(dimension, to: option)
                } label: {
                    menuRowLabel(option.label, isSelected: selected?.id == option.id)
                }
            }
        } label: {
            filterChip(dimension: dimension, selected: selected)
        }
        .disabled(viewModel.isExecuting || viewModel.isPaused)
    }

    /// A menu row that shows a checkmark only when selected. `Label` with an
    /// empty `systemImage` would still reserve an (empty) icon slot, so the
    /// selected and unselected rows are built separately.
    @ViewBuilder
    private func menuRowLabel(_ text: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(text, systemImage: "checkmark")
        } else {
            Text(text)
        }
    }

    /// One chip. Sized by its container (an equal third of the row), so the
    /// content is centred and both the icon and the chevron stay put in every
    /// state — anything that appears or disappears here shifts the label.
    ///
    /// The chip shows `chipLabel` (the abbreviated form) because it only has
    /// ~100pt to work with; the menu behind it shows the full `label`.
    private func filterChip(dimension: FilterDimension, selected: ResolvedFilterOption?) -> some View {
        let isActive = selected != nil

        return HStack(spacing: 5) {
            Image(systemName: dimension.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(selected?.chipLabel ?? dimension.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                // A floor rather than a licence to shrink: labels are picked to
                // fit, so this only catches a long one at larger type sizes.
                .minimumScaleFactor(0.9)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(isActive ? Color("BrandPrimary") : Color("SecondaryText"))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isActive ? Color("BrandPrimary").opacity(0.12) : Color("Surface2"))
        .cornerRadius(9)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(isActive ? Color("BrandPrimary").opacity(0.35) : Color("Border"), lineWidth: 1)
        )
    }

    /// Lives in the navigation bar so the filter row's geometry never depends on
    /// whether a filter is set. Every menu also offers "Any …", so this is a
    /// shortcut rather than the only way to clear.
    private var clearFiltersButton: some View {
        Button(action: { viewModel.clearFilters() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color("SecondaryText"))
        }
        .disabled(viewModel.isExecuting || viewModel.isPaused)
        .accessibilityLabel("Clear filters")
    }

    // MARK: - Workout card

    private var workoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                if let format = viewModel.currentWorkout?.format {
                    Text(format)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryText"))
                }
                Spacer()
                bookmarkButton
            }

            Text(viewModel.currentWorkout?.displayText ?? "")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color("PrimaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            newWorkoutButton
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

    private var newWorkoutButton: some View {
        Button(action: { viewModel.nextWorkout() }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Generate").fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Surface"))
            .foregroundColor(Color("PrimaryText"))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Border"), lineWidth: 1))
        }
        .disabled(viewModel.isLoading)
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

// MARK: - Skeleton card

private struct HIITSkeletonCard: View {
    @State private var shimmerPhase: CGFloat = 0
    @State private var phraseIndex: Int = 0

    private let phrases = ["Thinking…", "Generating…", "Crafting your workout…", "Personalizing…"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                skeletonBar(width: 88, height: 13, color: Color("BrandPrimary").opacity(0.28))
                Spacer()
                skeletonBar(width: 16, height: 16)
            }

            VStack(alignment: .leading, spacing: 10) {
                skeletonBar(width: 260, height: 12)
                skeletonBar(width: 220, height: 12)
                skeletonBar(width: 245, height: 12)
                skeletonBar(width: 195, height: 12)
                skeletonBar(width: 235, height: 12)
                skeletonBar(width: 170, height: 12)
                skeletonBar(width: 210, height: 12)
            }

            ZStack {
                ForEach(0..<phrases.count, id: \.self) { i in
                    Text(phrases[i])
                        .opacity(i == phraseIndex ? 1 : 0)
                }
            }
            .font(.caption)
            .foregroundColor(Color("BrandPrimary").opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .animation(.easeInOut(duration: 0.5), value: phraseIndex)
        }
        .padding()
        .background(Color("Surface"))
        .overlay(
            GeometryReader { geo in
                let w = geo.size.width
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.22), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 160)
                .offset(x: -160 + shimmerPhase * (w + 160))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
        .onAppear {
            phraseIndex = Int.random(in: 0..<phrases.count)
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
        .onReceive(Timer.publish(every: 2.2, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                phraseIndex = (phraseIndex + 1) % phrases.count
            }
        }
    }

    private func skeletonBar(width: CGFloat, height: CGFloat, color: Color = Color("Surface2")) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: width, height: height)
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
        HIITWorkoutView(preloaded: HIITWorkoutViewModel.preview().currentWorkout!)
    }
}

#Preview("Loading") {
    NavigationStack {
        HIITWorkoutView()
    }
}
