//
//  BlockPagerView.swift
//  wodAI
//
//  Opened by tapping a block on the Assistant page: one block at a time, as
//  its full strength or HIIT screen, with a row of dots for that session's
//  blocks (other sessions on the same day aren't included). Swipe left for the next block, right for the previous one. Once a
//  block is finished (last set logged, or a HIIT result saved) it moves on
//  to the next by itself. Finishing the session's last open block instead
//  goes back to the Workout page, with the session collapsed and checked off.
//

import SwiftUI

/// How one dot in the block indicator is drawn.
enum BlockDotState: Equatable {
    case current
    case completed
    case upcoming

    /// The current block always shows as current, even if it's done, so
    /// it's clear where the athlete is.
    init(isCurrent: Bool, isCompleted: Bool) {
        if isCurrent {
            self = .current
        } else if isCompleted {
            self = .completed
        } else {
            self = .upcoming
        }
    }
}

enum BlockNavigation {
    /// The id of the block one step from `id` in `blocks`, or nil at either end.
    static func neighbor(of id: Int, in blocks: [AssistantBlock], forward: Bool) -> Int? {
        guard let index = blocks.firstIndex(where: { $0.id == id }) else { return nil }
        let next = forward ? index + 1 : index - 1
        return blocks.indices.contains(next) ? blocks[next].id : nil
    }

    /// True when finishing `id` leaves nothing in `blocks` undone, so the
    /// pager should leave rather than move on.
    static func completesSession(finishing id: Int, in blocks: [AssistantBlock]) -> Bool {
        !blocks.isEmpty && blocks.allSatisfy { $0.id == id || $0.isCompleted }
    }
}

struct BlockPagerView: View {
    @ObservedObject var viewModel: AssistantViewModel
    let sessionId: String
    @State private var currentId: Int
    /// Where the incoming block slides in from: trailing when moving forward.
    @State private var slideEdge: Edge = .trailing
    /// Set once the session is done and the pager is on its way back.
    @State private var isLeaving = false
    @Environment(\.dismiss) private var dismiss

    /// How long a just-finished block stays up before moving on, so the
    /// last check mark (or the dismissing result screen) is seen.
    private static let autoAdvanceDelay: TimeInterval = 0.8

    init(viewModel: AssistantViewModel, sessionId: String, startingAt blockId: Int) {
        self.viewModel = viewModel
        self.sessionId = sessionId
        self._currentId = State(initialValue: blockId)
    }

    private var blocks: [AssistantBlock] { viewModel.openableBlocks(in: sessionId) }

    private var currentBlock: AssistantBlock? {
        blocks.first { $0.id == currentId }
    }

    private var isSessionCompleted: Bool {
        viewModel.session(id: sessionId)?.isCompleted ?? false
    }

    var body: some View {
        ZStack {
            if let block = currentBlock {
                page(block)
                    // A new identity per block so moving slides the old one
                    // out and the new one in, each with fresh screen state.
                    .id(block.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: slideEdge),
                        removal: .move(edge: slideEdge == .trailing ? .leading : .trailing)
                    ))
            } else {
                Text("This block is no longer available.")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        // Simultaneous so vertical scrolling is untouched; only a clearly
        // horizontal drag changes the block.
        .simultaneousGesture(blockSwipe)
        .safeAreaInset(edge: .top, spacing: 0) {
            if blocks.count > 1 {
                BlockDots(blocks: blocks, currentId: currentId)
                    .padding(.vertical, 8)
            }
        }
        .background(Color("Background").ignoresSafeArea())
        // Watches the session rather than the finish callbacks: a strength
        // block reports finished before its last set's save lands, and the
        // session only reads complete once it has.
        .onChange(of: isSessionCompleted) { wasCompleted, isCompleted in
            if !wasCompleted && isCompleted { leaveCompletedSession() }
        }
    }

    @ViewBuilder
    private func page(_ block: AssistantBlock) -> some View {
        switch block.kind {
        case let .strength(workout):
            StrengthWorkoutView(
                workout: workout,
                onChange: { viewModel.updateStrength($0, sessionId: sessionId) },
                onFinished: { advance(after: block.id) }
            )
        case let .hiit(workout):
            MetconView(
                preloaded: workout,
                pieceId: block.hiitPieceId,
                onCompleted: {
                    viewModel.markHiitCompleted(sessionId: sessionId, blockId: block.id)
                    advance(after: block.id)
                }
            )
        case .other:
            EmptyView()
        }
    }

    // MARK: - Navigation

    /// Swipe left for the next block, right for the previous one. A drag only
    /// counts when it's mostly sideways and long enough to be deliberate.
    private var blockSwipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy), abs(dx) > 60 else { return }
                move(forward: dx < 0)
            }
    }

    private func move(forward: Bool) {
        guard let next = BlockNavigation.neighbor(of: currentId, in: blocks, forward: forward) else {
            // The session is the limit: a light tap says there's nothing further.
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        slideEdge = forward ? .trailing : .leading
        withAnimation(.easeInOut(duration: 0.25)) {
            currentId = next
        }
    }

    /// Moves on from a block that was just finished, unless the athlete has
    /// already moved elsewhere. The last block stays put, and one that
    /// finishes the session leaves it to `leaveCompletedSession`.
    private func advance(after blockId: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.autoAdvanceDelay) {
            guard currentId == blockId,
                  !isLeaving,
                  !BlockNavigation.completesSession(finishing: blockId, in: blocks),
                  BlockNavigation.neighbor(of: blockId, in: blocks, forward: true) != nil
            else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            move(forward: true)
        }
    }

    /// Every block is done: after the same pause as moving on, go back to the
    /// Workout page with this session collapsed, where it shows as completed.
    private func leaveCompletedSession() {
        guard !isLeaving else { return }
        isLeaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.autoAdvanceDelay) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            viewModel.collapse(sessionId: sessionId)
            dismiss()
        }
    }
}

// MARK: - Dots

/// One dot per block: green when done, bright white for the one on screen,
/// neutral grey otherwise. Sits on a dark capsule so the white dot reads in
/// light mode too.
private struct BlockDots: View {
    let blocks: [AssistantBlock]
    let currentId: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(blocks) { block in
                let state = BlockDotState(isCurrent: block.id == currentId, isCompleted: block.isCompleted)
                Circle()
                    .fill(color(for: state))
                    .frame(width: state == .current ? 9 : 7, height: state == .current ? 9 : 7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.black.opacity(0.35)))
        .animation(.easeInOut(duration: 0.2), value: currentId)
        .animation(.easeInOut(duration: 0.2), value: blocks.map(\.isCompleted))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func color(for state: BlockDotState) -> Color {
        switch state {
        case .current: return .white
        case .completed: return Color("Success")
        case .upcoming: return Color.gray.opacity(0.6)
        }
    }

    private var accessibilityText: String {
        let position = (blocks.firstIndex { $0.id == currentId } ?? 0) + 1
        let done = blocks.filter(\.isCompleted).count
        return "Block \(position) of \(blocks.count), \(done) completed"
    }
}

#Preview {
    let viewModel = AssistantViewModel.preview()
    return NavigationStack {
        BlockPagerView(viewModel: viewModel, sessionId: viewModel.daySessions[0].id, startingAt: 0)
    }
}
