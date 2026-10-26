//
//  AssistantChatView.swift
//  wodAI
//
//  The trainer chat, full screen over the Workout page (which hides its
//  navigation bar meanwhile). Close it with ✕ or by swiping the header down.
//

import SwiftUI

struct AssistantChatView: View {
    @ObservedObject var viewModel: AssistantChatViewModel
    let onClose: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messages
            if viewModel.canType { inputBar }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background").ignoresSafeArea())
        .offset(y: dragOffset)
        .transition(.move(edge: .bottom))
        .task { await viewModel.load() }
        // Closing stops the trainer's reply; reopening can retry it.
        .onDisappear { viewModel.cancelTurn() }
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
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.transcript.messages) { message in
                        ChatMessageRow(
                            message: message,
                            tappable: tappable(for: message),
                            onTap: viewModel.tap,
                            onPickDays: viewModel.pickDays,
                            onRetry: retry(for: message)
                        )
                        .id(message.id)
                    }
                    if viewModel.transcript.isAwaitingTrainer, viewModel.transcript.messages.last?.author == .athlete {
                        TypingIndicator()
                    }
                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomId)
                }
                .padding(16)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            // Follows the reply as it streams in, and its options as they
            // arrive. Only a new message animates, so streaming doesn't stutter.
            .onChange(of: bottomKey) { old, new in
                if old.messageCount != new.messageCount {
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(Self.bottomId, anchor: .bottom) }
                } else {
                    proxy.scrollTo(Self.bottomId, anchor: .bottom)
                }
            }
        }
    }

    private static let bottomId = "bottom"

    /// Changes whenever the bottom of the transcript moves.
    private struct BottomKey: Equatable {
        let messageCount: Int
        let lastTextLength: Int
        let lastSuggestionCount: Int
        let awaitingTrainer: Bool
    }

    private var bottomKey: BottomKey {
        let transcript = viewModel.transcript
        return BottomKey(
            messageCount: transcript.messages.count,
            lastTextLength: transcript.messages.last?.text.count ?? 0,
            lastSuggestionCount: transcript.messages.last?.suggestions.count ?? 0,
            awaitingTrainer: transcript.isAwaitingTrainer
        )
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
            TextField("Message your coach…", text: $viewModel.draft, axis: .vertical)
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
    let onPickDays: ([String]) -> Void
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
            let options = message.suggestions.filter { $0.pickableDates == nil }
            if !options.isEmpty {
                SuggestionList(suggestions: options, tappable: tappable, onTap: onTap)
            }
            ForEach(message.suggestions.filter { $0.pickableDates != nil }) { picker in
                DayPicker(dates: picker.pickableDates ?? [], enabled: tappable.contains(picker), onDone: onPickDays)
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

/// The options, lettered A, B, C… and hanging off a rail like a list.
/// Options of an answered turn stay visible, in quiet colors (fading them out
/// left them unreadable in dark mode).
private struct SuggestionList: View {
    let suggestions: [ChatSuggestion]
    let tappable: [ChatSuggestion]
    let onTap: (ChatSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                let enabled = tappable.contains(suggestion)
                HStack(spacing: 0) {
                    RailConnector(isLast: index == suggestions.count - 1)
                        .stroke(Color("Border"), lineWidth: 2)
                        .frame(width: 18)
                        .accessibilityHidden(true)
                    Button { onTap(suggestion) } label: {
                        row(letter: ChatSuggestion.optionLetter(at: index), label: suggestion.label, enabled: enabled)
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                    .accessibilityLabel(suggestion.label)
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private func row(letter: String, label: String, enabled: Bool) -> some View {
        HStack(spacing: 10) {
            Text(letter)
                .font(.subheadline.weight(.bold))
                .foregroundColor(enabled ? .white : Color("SecondaryText"))
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 7).fill(enabled ? Color.brandPrimary : Color("Background")))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color("Border"), lineWidth: enabled ? 0 : 1))
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(enabled ? Color.brandPrimary : Color("SecondaryText"))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color("Surface")))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(enabled ? Color.brandPrimary.opacity(0.6) : Color("Border"), lineWidth: 1))
        .contentShape(Rectangle())
    }
}

/// One option's piece of the rail: the line down the left, and a tick across
/// to the option. The last option's line stops at its tick.
private struct RailConnector: Shape {
    let isLast: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let x = rect.minX + 4
        path.move(to: CGPoint(x: x, y: rect.minY))
        path.addLine(to: CGPoint(x: x, y: isLast ? rect.midY : rect.maxY))
        path.move(to: CGPoint(x: x, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// The days the coach can program, to pick any of (Program My Week). Done
/// sends them as the athlete's reply.
private struct DayPicker: View {
    let dates: [String]
    let enabled: Bool
    let onDone: ([String]) -> Void

    @State private var picked: Set<String> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    let isPicked = picked.contains(date)
                    Button {
                        if isPicked { picked.remove(date) } else { picked.insert(date) }
                    } label: {
                        VStack(spacing: 2) {
                            Text(ChatTranscript.weekdayLabel(date))
                                .font(.caption.weight(.semibold))
                            Text(ChatTranscript.dayOfMonth(date))
                                .font(.body.weight(.semibold).monospacedDigit())
                        }
                        .foregroundColor(isPicked ? .white : Color("PrimaryText"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isPicked ? Color.brandPrimary : Color("Surface"))
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("Border"), lineWidth: isPicked ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(ChatTranscript.dayLabel(date))
                    .accessibilityAddTraits(isPicked ? .isSelected : [])
                }
            }
            Button {
                onDone(dates.filter(picked.contains))
            } label: {
                Text(picked.isEmpty ? "Pick days to plan" : "Plan \(picked.count) day\(picked.count == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(picked.isEmpty ? Color("SecondaryText") : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(picked.isEmpty ? Color("Surface") : Color.brandPrimary))
                    .overlay(Capsule().stroke(Color("Border"), lineWidth: picked.isEmpty ? 1 : 0))
            }
            .buttonStyle(.plain)
            .disabled(picked.isEmpty)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.6)
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
