//
//  AssistantView.swift
//  wodAI
//

import SwiftUI

struct AssistantView: View {
    @StateObject private var viewModel: AssistantViewModel
    @State private var stimulusExpanded = false

    init() {
        self._viewModel = StateObject(wrappedValue: AssistantViewModel())
    }

    init(viewModel: AssistantViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(Color("Error"))
                }

                if let session = viewModel.session {
                    ForEach(session.blocks) { block in
                        blockLink(block)
                    }
                } else if viewModel.isLoadingLatest {
                    placeholder(icon: nil, title: "Loading your latest workout…", detail: nil)
                } else if viewModel.hasLoadedLatest {
                    placeholder(
                        icon: "sparkles",
                        title: "No workout yet",
                        detail: "Tap Generate Workout and the assistant will build today's session for you."
                    )
                }
                Button {
                    viewModel.generate()
                } label: {
                    HStack {
                        if viewModel.isGenerating { ProgressView() }
                        Text(viewModel.isGenerating ? "Generating…" : "Generate Workout")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating)
            }
            .padding()
        }
        .background(Color("Background").ignoresSafeArea())
        .task {
            viewModel.warmUpGeneration()
            viewModel.loadLatest()
        }
        // Set as a principal item as well as the title: a pushed block's own
        // principal title (StrengthWorkoutView) can otherwise linger here after
        // popping back.
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                    .lineLimit(1)
            }
        }
        .navigationDestination(for: AssistantRoute.self) { route in
            switch route {
            case let .hiit(workout):
                HIITWorkoutView(preloaded: workout, showsFeedControls: false)
            case let .strength(detail):
                // The live copy, not the one captured at push time, so a block
                // opened mid-generation still gets its ids once it's saved.
                StrengthWorkoutView(
                    workout: viewModel.strengthWorkout(id: detail.id) ?? detail,
                    onChange: viewModel.updateStrength
                )
            }
        }
    }

    /// "Programming for 1/23/25" once a session is showing, else the page name.
    private var title: String {
        guard let date = viewModel.session?.scheduledDate else { return "Assistant" }
        return "Programming for \(date.formatted(.dateTime.month(.defaultDigits).day().year(.twoDigits)))"
    }

    // MARK: - Empty / loading

    /// Fills the space where the session goes, so the page is never blank.
    /// A nil icon shows a spinner instead.
    private func placeholder(icon: String?, title: String, detail: String?) -> some View {
        VStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(Color("TertiaryText"))
            } else {
                ProgressView()
            }
            Text(title)
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Session header

    private func header(_ session: AssistantSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let stimulus = session.stimulus, !stimulus.isEmpty {
                Text("Stimulus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
                Text(stimulus)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .lineLimit(stimulusExpanded ? nil : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mask(stimulusFadeMask)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stimulusExpanded.toggle()
                        }
                    }
            }
        }
    }

    /// Fades the bottom of the stimulus text when collapsed, hinting there's more to read.
    @ViewBuilder
    private var stimulusFadeMask: some View {
        if stimulusExpanded {
            Rectangle()
        } else {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.6),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Blocks

    private func blockLetter(_ label: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 40, height: 40)
            Text(label)
                .foregroundColor(Color.white)
                .font(Font.body.monospacedDigit())
        }
        .padding(10)
    }

    /// Wraps a block in a `NavigationLink` that routes by kind (strength → the
    /// strength screen, HIIT → the WOD screen); `.other` blocks aren't tappable.
    @ViewBuilder
    private func blockLink(_ block: AssistantBlock) -> some View {
        if let route = block.route {
            NavigationLink(value: route) {
                blockView(block)
            }
            .buttonStyle(.plain)
        } else {
            blockView(block)
        }
    }

    private func blockView(_ block: AssistantBlock) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                blockLetter(block.letter)
                Text(block.label)
                    .font(.headline)
            }


            switch block.kind {
            case .strength(let workout):
                // A summary, not the StrengthWorkoutView itself: that's a full
                // screen (GeometryReader + List) with no natural height, so
                // inside this ScrollView it collapses to a scrollable sliver
                // and its nav title leaks into this page's bar. The full view
                // opens via blockLink's NavigationLink.
                whiteboard(AssistantFormatting.whiteboardLines(
                    workout.components
                        .sorted { $0.order < $1.order }
                        .map { WhiteboardSet(exercise: $0.exercise.name, reps: $0.reps, weight: $0.weight, rpe: $0.rpe) }
                ))
            case .hiit(let workout):
                HIITWorkoutCard(format: workout.format, displayText: workout.displayText) {
                  
                }
            case .other:
                EmptyView()
            }
        }.background(Color.surface2)
    }
    

    /// The set list, drawn on the same card surface as the HIIT WOD card.
    private func whiteboard(_ lines: [String]) -> some View {
        Text(lines.joined(separator: "\n"))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(Color("PrimaryText"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("Border"), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        AssistantView(viewModel: .preview())
    }
}
