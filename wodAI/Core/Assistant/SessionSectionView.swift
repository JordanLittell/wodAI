//
//  SessionSectionView.swift
//  wodAI
//
//  One session on the Assistant page, always showing its blocks. The header
//  names the session and says where it came from; a red trash button in the
//  top right deletes it. A colored rail down the side tells sessions apart.
//
//  Swiping the header left also reveals a Delete button. Either way deleting
//  needs a confirmation, so a stray tap or swipe can't remove anything.
//

import SwiftUI

struct SessionSectionView<Blocks: View>: View {
    let session: AssistantSession
    /// Whether the Delete button is showing.
    var isRevealed = false
    /// Shows (true) or hides (false) the Delete button.
    var onReveal: (Bool) -> Void = { _ in }
    /// Asks to delete; the owner confirms first.
    var onDelete: () -> Void = {}
    /// Called throughout a swipe on the header, so the page can tell it
    /// apart from its own swipe between days.
    var onSwipe: () -> Void = {}
    @ViewBuilder let blocks: () -> Blocks

    /// How far the section slides to show the Delete button.
    static var revealWidth: CGFloat { 88 }
    @State private var dragOffset: CGFloat = 0

    /// A session still streaming in can't be deleted.
    private var canDelete: Bool { !session.isPending }

    private var offset: CGFloat {
        let base = isRevealed ? -Self.revealWidth : 0
        // Rubber-bands a little past the button, never to the right.
        return min(0, max(base + dragOffset, -Self.revealWidth * 1.3))
    }

    var body: some View {
        card
            .offset(x: offset)
            // A background, so the button takes the card's height.
            .background(alignment: .trailing) {
                if offset < 0 {
                    deleteButton
                }
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if session.isPending && session.blocks.isEmpty {
                placeholderBlocks
            } else {
                blocks()
            }
        }
        .padding(.vertical, 14)
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // An overlay, so the rail follows the section's height rather than
        // stretching it.
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accent)
                .frame(width: 4)
        }
        // Opaque, so the Delete button behind only shows where the card
        // has slid away.
        .background(Color("Background"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            VStack(spacing: 6) {
                Image(systemName: "trash.fill")
                    .font(.title3)
                Text("Delete")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: Self.revealWidth, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("Error")))
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }

    /// Imports get their own color so they read as different from the
    /// programmed session at a glance.
    private var accent: Color {
        switch session.source {
        case .whiteboard: return Color.brandSecondary
        // The palette's other accents are pinks too close to the
        // whiteboard's; teal reads as distinct in both themes.
        case .created: return Color.teal
        case .generated, .planned, .imported: return Color.brandPrimary
        }
    }

    // MARK: - Swipe to delete

    /// Left on the header reveals Delete; right hides it. A rightward swipe
    /// with nothing revealed is left alone, so it still changes the day.
    private var revealDrag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard canDelete, claims(value) else { return }
                onSwipe()
                dragOffset = value.translation.width
            }
            .onEnded { value in
                guard canDelete, claims(value) else { return }
                onSwipe()
                let shouldReveal = (isRevealed ? -Self.revealWidth : 0) + value.translation.width < -Self.revealWidth / 2
                withAnimation(.spring(duration: 0.3)) {
                    dragOffset = 0
                    onReveal(shouldReveal)
                }
            }
    }

    /// Whether a drag is this section's: mostly sideways, and either leftward
    /// or closing a revealed button.
    private func claims(_ value: DragGesture.Value) -> Bool {
        let dx = value.translation.width
        guard abs(dx) > abs(value.translation.height) else { return false }
        return dx < 0 || isRevealed
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    sourceChip
                    if session.isOptional {
                        optionalChip
                    }
                }

                HStack(spacing: 8) {
                    if session.isPending {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(session.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color("PrimaryText"))
                        .multilineTextAlignment(.leading)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            if session.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("Success"))
                    .frame(height: 32)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityHidden(true)
            }
            if canDelete {
                trashButton
            }
        }
        .contentShape(Rectangle())
        // With Delete showing, a tap puts the section back.
        .onTapGesture {
            if isRevealed {
                withAnimation(.spring(duration: 0.3)) { onReveal(false) }
            }
        }
        .simultaneousGesture(revealDrag)
    }

    /// Asks to delete the session; the owner confirms first.
    private var trashButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.body.weight(.semibold))
                .foregroundColor(Color("Error"))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete session")
        .accessibilityIdentifier("deleteSessionButton")
    }

    private var sourceChip: some View {
        Label(session.source.label, systemImage: session.source.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundColor(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(accent.opacity(0.12)))
    }

    /// Marks a rest day's light activity as skippable.
    private var optionalChip: some View {
        Label("Optional", systemImage: "leaf")
            .font(.caption.weight(.semibold))
            .foregroundColor(Color("SecondaryText"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color("SecondaryText").opacity(0.12)))
    }

    // MARK: - Body

    /// Stands in for blocks until the first one streams in.
    private var placeholderBlocks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Block A - Back Squat 5 × 5")
            Text("21 Thrusters\n21 Pull-ups\n15 Thrusters")
        }
        .font(.body)
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        var parts = [session.name, session.source.label]
        if session.isOptional { parts.append("Optional") }
        if session.isPending {
            parts.append("Loading")
        } else if session.isCompleted {
            parts.append("Completed")
        }
        return parts.joined(separator: ", ")
    }
}

/// Keeps the page's swipe between days from also firing during a swipe on
/// a session header: the day swipe waits until the section has been quiet for
/// `quietPeriod`.
struct DaySwipeGuard {
    static let quietPeriod: TimeInterval = 0.3
    var lastSectionSwipeAt: Date?

    func allowsDaySwipe(at now: Date) -> Bool {
        guard let lastSectionSwipeAt else { return true }
        return now.timeIntervalSince(lastSectionSwipeAt) >= Self.quietPeriod
    }
}
