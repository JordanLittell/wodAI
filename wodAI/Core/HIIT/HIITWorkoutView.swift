//
//  HIITWorkoutView.swift
//  wodAI

import SwiftUI
import UIKit

struct HIITWorkoutView: View {
    @StateObject private var viewModel: HIITWorkoutViewModel
    @ObservedObject private var watch = HIITSessionManager.shared.bridge
    @State private var showingAvailableTags = false

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
                            tagSection
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
        .onAppear {
            // Restore an in-flight workout (e.g. after the app was killed mid-session) so it
            // is never replaced by the default workout.
            viewModel.restoreActiveSession()
            if let id = viewModel.currentWorkout?.id {
                viewModel.fetchIsSaved(workoutId: id)
            } else {
                viewModel.loadWorkout()
            }
        }
        .overlay {
            if viewModel.showConfetti {
                ConfettiView { viewModel.showConfetti = false }
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Tag section

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Row 1: selected tags + toggle button
            HStack(spacing: 8) {
                if viewModel.isExecuting || viewModel.isPaused {
                    PulsingDot(color: viewModel.isExecuting ? .green : .orange)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.selectedTags) { tag in
                            selectedTagPill(tag)
                        }
                        addButton
                    }
                }

                if viewModel.isCountingDown {
                    // Pre-roll countdown, in lockstep with the watch (shared t0).
                    Text("Starting in \(Int(ceil(viewModel.countdownRemaining)))")
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundColor(.green)
                        .monospacedDigit()
                } else if viewModel.isExecuting || viewModel.isPaused {
                    Text(formatTimer(viewModel.displaySeconds))
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundColor(viewModel.isExecuting ? .green : .orange)
                        .monospacedDigit()
                }
            }

            // Row 2: available tags (slides in inline)
            if showingAvailableTags {
                availableTagsRow
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingAvailableTags)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.selectedTags.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.availableTags.count)
    }

    private var addButton: some View {
        Button(action: {
            if !showingAvailableTags {
                viewModel.fetchAvailableTags()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showingAvailableTags.toggle()
            }
        }) {
            Image(systemName: showingAvailableTags ? "chevron.up" : "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(showingAvailableTags ? Color("BrandPrimary") : Color("SecondaryText"))
                .frame(width: 26, height: 26)
                .background(showingAvailableTags ? Color("BrandPrimary").opacity(0.12) : Color("Surface2"))
                .cornerRadius(8)
        }
        .disabled(viewModel.isExecuting || viewModel.isPaused)
    }

    @ViewBuilder
    private var availableTagsRow: some View {
        if viewModel.isLoadingTags {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7)
                Text("Loading…")
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
            }
        } else if viewModel.availableTags.isEmpty {
            Text("No more options")
                .font(.caption)
                .foregroundColor(Color("TertiaryText"))
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.availableTags) { tag in
                        Button(action: {
                            viewModel.addTag(tag)
                            if viewModel.availableTags.isEmpty {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingAvailableTags = false
                                }
                            }
                        }) {
                            Text(tag.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("SecondaryText"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color("Surface2"))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color("Border"), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }

    private func selectedTagPill(_ tag: HIITTagItem) -> some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.caption)
                .fontWeight(.medium)
            Button(action: { viewModel.removeTag(id: tag.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundColor(Color("BrandPrimary"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("BrandPrimary").opacity(0.12))
        .cornerRadius(8)
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

            if let tags = viewModel.currentWorkout?.tags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tags) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.purple.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.purple.opacity(0.08))
                            .cornerRadius(6)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    cardBorderColor,
                    lineWidth: (viewModel.isExecuting || viewModel.isPaused || viewModel.isCountingDown) ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.4), value: viewModel.isExecuting)
        .animation(.easeInOut(duration: 0.4), value: viewModel.isPaused)
    }

    // MARK: - Watch status

    // WatchConnectivity has no pairing prompt — pairing is done once in the system Watch app.
    // This surfaces the connection state (the closest thing to a "pair your watch" affordance).
    @ViewBuilder
    private var watchStatusBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: watch.isWatchAppInstalled ? "applewatch" : "applewatch.slash")
                .foregroundColor(watch.isWatchAppInstalled ? .green : .secondary)
            Text(watchStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
            if watch.isWatchAppInstalled && watch.isReachable {
                PulsingDot(color: .green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BrandPrimary").opacity(0.08))
        .cornerRadius(10)
    }

    private var watchStatusText: String {
        if !watch.isPaired {
            return "No Apple Watch paired — set one up in the Watch app to track sensors"
        }
        if !watch.isWatchAppInstalled {
            return "Install wodAI on your Apple Watch to track heart rate & motion"
        }
        return watch.isReachable ? "Apple Watch connected" : "Apple Watch paired — waking…"
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            watchStatusBanner

            Group {
                if viewModel.isCountingDown {
                    exitButton            // cancel the pre-roll before the clock starts
                } else if viewModel.isExecuting {
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

    private var pauseButton: some View {
        Button(action: { viewModel.pauseExecution() }) {
            HStack {
                Image(systemName: "pause.fill")
                Text("Pause").fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Surface"))
            .foregroundColor(Color("PrimaryText"))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Border"), lineWidth: 1))
        }
    }

    private var finishButton: some View {
        Button(action: { viewModel.finishExecution() }) {
            HStack {
                Image(systemName: "checkmark")
                Text("Finish").fontWeight(.semibold)
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
                        startPoint: .leading, endPoint: .trailing
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

    private var cardBorderColor: Color {
        if viewModel.isPaused { return Color.red.opacity(0.3) }
        if viewModel.isExecuting || viewModel.isCountingDown { return Color.green.opacity(0.45) }
        return Color("Border")
    }

    private func formatTimer(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
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

// MARK: - Confetti

private struct ConfettiView: View {
    let onDismiss: () -> Void
    private let pieces: [ConfettiPiece] = (0..<60).map { _ in ConfettiPiece() }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in FallingShape(piece: piece) }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { onDismiss() }
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
    let color: Color = [Color("BrandPrimary"), Color("BrandSecondary"), .green, .yellow, .orange, .pink, .purple].randomElement()!
    let isCircle: Bool = Bool.random()
}

private struct FallingShape: View {
    let piece: ConfettiPiece
    @State private var fallen = false

    var body: some View {
        GeometryReader { geo in
            Group {
                if piece.isCircle {
                    Circle().fill(piece.color).frame(width: piece.size, height: piece.size)
                } else {
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.5)
                        .rotationEffect(.degrees(fallen ? piece.rotation + piece.rotationSpeed : piece.rotation))
                }
            }
            .position(x: geo.size.width * piece.x, y: fallen ? geo.size.height + 20 : -20)
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
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
        HIITWorkoutView(preloaded: HIITWorkoutViewModel.preview().currentWorkout!)
    }
}

#Preview("Loading") {
    NavigationStack {
        HIITWorkoutView()
    }
}
