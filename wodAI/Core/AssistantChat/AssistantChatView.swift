//
//  AssistantChatView.swift
//  wodAI
//
//  The trainer chat, laid over the Workout page: the page stays visible and
//  dimmed at the top, so the athlete knows they're still in their week.
//  Swipe the panel down, or tap the dimmed page, to close it.
//

import SwiftUI

struct AssistantChatView: View {
    @ObservedObject var viewModel: AssistantChatViewModel
    let onClose: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onClose)
                    .accessibilityHidden(true)

                // The top of the page stays in view above the panel.
                panel
                    .frame(height: geometry.size.height * 0.88)
                    .offset(y: dragOffset)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task { await viewModel.load() }
        // Closing stops the trainer's reply; reopening can retry it.
        .onDisappear { viewModel.cancelTurn() }
    }

    private var panel: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messages
            if viewModel.canType { inputBar }
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(Color("Background"))
                .shadow(color: .black.opacity(0.2), radius: 12, y: -2)
                // In dark mode the shadow and dimming barely show against the
                // page, so the edge carries the separation.
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                        .stroke(Color("Border"), lineWidth: 1)
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var header: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color("Border"))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            HStack {
                Text("Coach")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color("SecondaryText"))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Close assistant")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .contentShape(Rectangle())
        .gesture(closeDrag)
    }

    /// Pulling the header down past a third of the way, or flicking it, closes.
    private var closeDrag: some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = max(0, value.translation.height) }
            .onEnded { value in
                if value.translation.height > 160 || value.predictedEndTranslation.height > 400 {
                    onClose()
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = 0 }
                }
            }
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.transcript.messages) { message in
                        ChatMessageRow(
                            message: message,
                            tappable: tappable(for: message),
                            onTap: viewModel.tap,
                            onRetry: retry(for: message)
                        )
                        .id(message.id)
                    }
                    if viewModel.transcript.isAwaitingTrainer, viewModel.transcript.messages.last?.author == .athlete {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.transcript.messages.last?.text) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(viewModel.transcript.messages.last?.id, anchor: .bottom)
                }
            }
        }
    }

    /// Only the latest message, when it's an error, offers Try again.
    private func retry(for message: ChatMessage) -> (() -> Void)? {
        guard message.isError, message.id == viewModel.transcript.messages.last?.id else { return nil }
        return { viewModel.retry() }
    }

    /// Only the latest message's suggestions can be tapped.
    private func tappable(for message: ChatMessage) -> [ChatSuggestion] {
        message.id == viewModel.transcript.messages.last?.id ? viewModel.transcript.tappableSuggestions : []
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message your trainer…", text: $viewModel.draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color("Surface")))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("Border"), lineWidth: 1))
            Button(action: viewModel.send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.brandPrimary)
            }
            .disabled(!viewModel.canSendDraft)
            .opacity(viewModel.canSendDraft ? 1 : 0.4)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct ChatMessageRow: View {
    let message: ChatMessage
    /// The suggestions that can still be tapped; empty for older turns.
    let tappable: [ChatSuggestion]
    let onTap: (ChatSuggestion) -> Void
    /// Offered under the latest message when it's an error.
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: message.author == .athlete ? .trailing : .leading, spacing: 8) {
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(message.author == .athlete ? .white : Color("PrimaryText"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.author == .athlete ? Color.brandPrimary : Color("Surface"))
                    )
                    .overlay {
                        if message.isError {
                            RoundedRectangle(cornerRadius: 18).stroke(Color.red.opacity(0.5), lineWidth: 1)
                        }
                    }
            }
            if !message.suggestions.isEmpty {
                SuggestionChips(suggestions: message.suggestions, tappable: tappable, onTap: onTap)
            }
            if message.isError, let onRetry {
                Button(action: onRetry) {
                    Label("Try again", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.brandPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.author == .athlete ? .trailing : .leading)
        .padding(message.author == .athlete ? .leading : .trailing, 40)
    }
}

/// Wraps onto as many lines as it needs. Chips of an answered turn stay
/// visible, dimmed.
private struct SuggestionChips: View {
    let suggestions: [ChatSuggestion]
    let tappable: [ChatSuggestion]
    let onTap: (ChatSuggestion) -> Void

    var body: some View {
        ChipFlowLayout(spacing: 8) {
            ForEach(suggestions) { suggestion in
                let enabled = tappable.contains(suggestion)
                Button { onTap(suggestion) } label: {
                    Text(suggestion.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.brandPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color("Surface")))
                        .overlay(Capsule().stroke(Color.brandPrimary.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.45)
            }
        }
    }
}

/// Lays children left to right, wrapping to a new line when one won't fit.
private struct ChipFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        rows(for: subviews, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, origin) in rows(for: subviews, width: bounds.width).origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> (origins: [CGPoint], size: CGSize) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return (origins, CGSize(width: widest, height: y + rowHeight))
    }
}

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color("SecondaryText"))
                    .frame(width: 7, height: 7)
                    .opacity(phase == index ? 1 : 0.35)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color("Surface")))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(350))
                phase = (phase + 1) % 3
            }
        }
        .accessibilityLabel("Your coach is typing")
    }
}

#Preview {
    let viewModel = AssistantChatViewModel(loadGreeting: {
        ChatGreeting(text: "Hey Jordan, how can I help you today?", suggestions: [
            ChatSuggestion(id: "whiteboard", label: "Import Workout From Whiteboard", action: .openWhiteboardScanner),
            ChatSuggestion(id: "program_week", label: "Program My Week", action: .reply),
            ChatSuggestion(id: "write_today", label: "Write Workout for Today", action: .reply),
        ])
    })
    ZStack {
        Color("Background").ignoresSafeArea()
        AssistantChatView(viewModel: viewModel) {}
    }
}
