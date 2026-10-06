//
//  AssistantView.swift
//  wodAI
//

import SwiftUI

struct AssistantView: View {
    @StateObject private var viewModel: AssistantViewModel
    @State private var stimulusExpanded = false
    /// Where the incoming day slides in from: trailing when moving forward.
    @State private var slideEdge: Edge = .trailing
    @State private var isMenuOpen = false
    @State private var isScanning = false
    @State private var isCreating = false
    /// The "Create with AI" text, kept so a retry starts from it.
    @State private var createRequest = ""
    /// The session waiting on the delete confirmation.
    @State private var pendingDeletion: AssistantSession?
    @State private var swipeGuard = DaySwipeGuard()

    init() {
        self._viewModel = StateObject(wrappedValue: AssistantViewModel())
    }

    init(viewModel: AssistantViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            WeekStrip(
                week: viewModel.week,
                selectedDay: viewModel.selectedDay,
                hasSession: viewModel.hasSession(on:),
                onSelect: select
            )
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    dayContent
                        // A new identity per day so changing days slides the old
                        // day out and the new one in.
                        .id(viewModel.selectedDay)
                        .transition(.asymmetric(
                            insertion: .move(edge: slideEdge),
                            removal: .move(edge: slideEdge == .trailing ? .leading : .trailing)
                        ))
                }
                // Room below the last block so the + button never covers it.
                .contentMargins(.bottom, 96, for: .scrollContent)
                // Simultaneous so vertical scrolling is untouched; only a clearly
                // horizontal drag changes the day.
                .simultaneousGesture(daySwipe)
                // Scrolling puts back a section left showing Delete.
                .onScrollPhaseChange { _, phase in
                    if phase == .interacting, viewModel.revealedSessionId != nil {
                        withAnimation(.spring(duration: 0.3)) { viewModel.reveal(nil) }
                    }
                }
                .clipped()
                // A new import scrolls into view as it starts.
                .onChange(of: viewModel.focusedSessionId) { _, id in
                    guard let id else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
        .background(Color("Background").ignoresSafeArea())
        .overlay { FloatingActionScrim(isOpen: $isMenuOpen) }
        .overlay(alignment: .bottomTrailing) {
            FloatingActionMenu(
                isOpen: $isMenuOpen,
                isEnabled: viewModel.hasLoaded && !viewModel.isAddingSession,
                onSelect: perform
            )
            .padding(20)
        }
        .sheet(isPresented: $isCreating) {
            CreateSessionSheet(request: $createRequest) { request in
                withAnimation(.spring(duration: 0.35)) {
                    viewModel.createSession(request: request)
                }
            }
        }
        .confirmationDialog(
            pendingDeletion.map { "Delete \"\($0.name)\"?" } ?? "",
            isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { session in
            Button("Delete", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(duration: 0.35)) {
                    viewModel.deleteSession(id: session.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { session in
            Text(SessionDeletion.message(for: session))
        }
        .fullScreenCover(isPresented: $isScanning) {
            WhiteboardScannerView { capture in
                withAnimation(.spring(duration: 0.35)) {
                    viewModel.importWhiteboard(capture)
                }
            }
        }
        .task {
            viewModel.loadWeek()
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
        .navigationDestination(for: AssistantBlockRoute.self) { route in
            // Reads the live session, so blocks pick up later changes (ids,
            // sets logged and saved) and show their completion in the dots.
            BlockPagerView(viewModel: viewModel, sessionId: route.sessionId, startingAt: route.blockId)
        }
    }

    /// The month of the day being shown, e.g. "October". A week can span two
    /// months, so it follows the selected day.
    private var title: String {
        viewModel.selectedDay.formatted(.dateTime.month(.wide))
    }

    @ViewBuilder
    private var dayContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let notice = viewModel.planningNotice {
                planningBanner(notice)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(Color("Error"))
            }

            if let addError = viewModel.addError {
                addErrorBanner(addError)
            }

            let sessions = viewModel.daySessions
            if !sessions.isEmpty {
                ForEach(sessions) { session in
                    SessionSectionView(
                        session: session,
                        isExpanded: viewModel.isExpanded(session),
                        onToggle: {
                            withAnimation(.spring(duration: 0.35)) {
                                viewModel.toggleExpanded(session)
                            }
                        },
                        isRevealed: viewModel.revealedSessionId == session.id,
                        onReveal: { viewModel.reveal($0 ? session.id : nil) },
                        onDelete: { pendingDeletion = session },
                        onSwipe: { swipeGuard.lastSectionSwipeAt = Date() }
                    ) {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(session.blocks) { block in
                                blockLink(block, in: session)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .id(session.id)
                    .animation(.easeOut(duration: 0.25), value: session.blocks.map(\.id))
                }
            } else if viewModel.isLoading || (!viewModel.hasLoaded && viewModel.errorMessage == nil) {
                placeholder(icon: nil, title: "Loading this week…", detail: nil)
            } else if viewModel.hasLoaded {
                Text("No workout scheduled")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Quick actions

    private func perform(_ action: QuickAction) {
        viewModel.dismissAddError()
        viewModel.reveal(nil)
        switch action {
        case .createWithAI:
            isCreating = true
        case .importWhiteboard:
            isScanning = true
        }
    }

    /// Reopens whatever failed: the camera, or the create sheet with the
    /// request that was sent.
    private func retry() {
        switch viewModel.lastFailedAdd {
        case let .created(request):
            createRequest = request
            perform(.createWithAI)
        case .whiteboard, nil:
            perform(.importWhiteboard)
        }
    }

    /// While the server plans the rest of the week after onboarding.
    private func planningBanner(_ notice: PlanningNotice) -> some View {
        HStack(spacing: 12) {
            switch notice {
            case .planning:
                ProgressView().tint(Color.brandPrimary)
                Text("Planning the rest of your week…")
            case let .failed(message):
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Color("Warning"))
                Text(message)
            }
            Spacer(minLength: 0)
        }
        .font(.subheadline.weight(.medium))
        .foregroundColor(Color("PrimaryText"))
        .padding()
        .background(Color.brandPrimary.opacity(0.08))
        .cornerRadius(14)
        .transition(.opacity)
        .animation(.easeInOut, value: notice)
    }

    /// Why the last new session failed, with a way to try again.
    private func addErrorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color("Warning"))
            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryText"))
                Button("Try again", action: retry)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.brandPrimary)
            }
            Spacer(minLength: 0)
            Button {
                withAnimation { viewModel.dismissAddError() }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color("SecondaryText"))
            }
            .accessibilityLabel("Dismiss")
        }
        .padding()
        .background(Color("Warning").opacity(0.12))
        .cornerRadius(14)
        .transition(.opacity)
    }

    // MARK: - Day navigation

    /// Swipe left for the next day, right for the previous one. A drag only
    /// counts when it's mostly sideways and long enough to be deliberate.
    private var daySwipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy), abs(dx) > 60 else { return }
                // A swipe on a session header is that section's.
                guard swipeGuard.allowsDaySwipe(at: Date()) else { return }
                if dx < 0 {
                    move(forward: true)
                } else {
                    move(forward: false)
                }
            }
    }

    private func move(forward: Bool) {
        slideEdge = forward ? .trailing : .leading
        let moved = withAnimation(.easeInOut(duration: 0.25)) {
            forward ? viewModel.goForward() : viewModel.goBack()
        }
        // The week is the limit: a light tap says there's nothing further.
        if !moved {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func select(_ day: Date) {
        guard day != viewModel.selectedDay else { return }
        slideEdge = day > viewModel.selectedDay ? .trailing : .leading
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.select(day)
        }
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

    /// The block's letter, or a check once every component is done.
    private func blockLetter(_ label: String, completed: Bool) -> some View {
        ZStack {
            Circle()
                .fill(completed ? Color("Success") : Color.brandPrimary)
                .frame(width: 40, height: 40)
            if completed {
                Image(systemName: "checkmark")
                    .font(.body.weight(.bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text(label)
                    .foregroundColor(Color.white)
                    .font(Font.body.monospacedDigit())
            }
        }
        .padding(10)
    }

    private var completedTag: some View {
        Label("Completed", systemImage: "checkmark.seal.fill")
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("Success"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color("Success").opacity(0.12)))
            .transition(.opacity)
    }

    /// Wraps a block in a `NavigationLink` that opens the block pager on it
    /// (strength → the strength screen, HIIT → the Metcon screen); `.other`
    /// blocks, and blocks of a session still streaming in, aren't tappable.
    @ViewBuilder
    private func blockLink(_ block: AssistantBlock, in session: AssistantSession) -> some View {
        if block.isOpenable && !session.isPending {
            NavigationLink(value: AssistantBlockRoute(sessionId: session.id, blockId: block.id)) {
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
                blockLetter(block.letter, completed: block.isCompleted)
                Text(block.label)
                    .font(.headline)
                Spacer(minLength: 8)
                if block.isCompleted {
                    completedTag
                        .padding(.trailing, 10)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(block.isCompleted ? "Completed" : "")


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
                ), completed: block.isCompleted)
            case .hiit(let workout):
                HIITWorkoutCard(format: workout.format, displayText: workout.displayText) {
                  
                }
            case .other:
                EmptyView()
            }
        }
        .background(Color.surface2)
        .animation(.spring(duration: 0.35), value: block.isCompleted)
    }
    

    /// The set list, drawn on the same card surface as the HIIT WOD card.
    /// A completed block keeps its sets fully readable (it's the record of
    /// what was lifted) and swaps the border for the success color.
    private func whiteboard(_ lines: [String], completed: Bool) -> some View {
        Text(lines.joined(separator: "\n"))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(Color("PrimaryText"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(completed ? Color("Success") : Color("Border"), lineWidth: completed ? 1.5 : 1)
            )
    }
}

#Preview {
    NavigationStack {
        AssistantView(viewModel: .preview())
    }
}
