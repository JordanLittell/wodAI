//
//  SessionSectionView.swift
//  wodAI
//
//  One session on the Assistant page as a section that opens and closes.
//  The header names the session, says where it came from, and counts done
//  blocks; closed, a single line lists the blocks so a day with several
//  sessions stays short. A colored rail down the side tells sessions apart.
//

import SwiftUI

struct SessionSectionView<Blocks: View>: View {
    let session: AssistantSession
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let blocks: () -> Blocks

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if isExpanded {
                if session.isPending && session.blocks.isEmpty {
                    placeholderBlocks
                } else {
                    blocks()
                }
            } else if !session.blocks.isEmpty {
                summary
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }

    /// Whiteboard imports get the secondary brand color so they read as
    /// different from the programmed session at a glance.
    private var accent: Color {
        session.source == .whiteboard ? Color.brandSecondary : Color.brandPrimary
    }

    // MARK: - Header

    private var header: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    sourceChip
                    Spacer(minLength: 8)
                    progress
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("SecondaryText"))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isExpanded ? "Collapses the session" : "Expands the session")
        .accessibilityAddTraits(.isHeader)
    }

    private var sourceChip: some View {
        Label(session.source.label, systemImage: session.source.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundColor(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(accent.opacity(0.12)))
    }

    @ViewBuilder
    private var progress: some View {
        let openable = session.blocks.filter(\.isOpenable)
        if session.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color("Success"))
                .transition(.scale.combined(with: .opacity))
        } else if !session.isPending, !openable.isEmpty {
            Text("\(openable.filter(\.isCompleted).count)/\(openable.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundColor(Color("SecondaryText"))
        }
    }

    // MARK: - Body

    /// The closed section's one line: "A Back Squat · B Metcon".
    private var summary: some View {
        Text(session.blocks.map { "\($0.letter) \($0.label)" }.joined(separator: " · "))
            .font(.subheadline)
            .foregroundColor(Color("SecondaryText"))
            .lineLimit(1)
            .truncationMode(.tail)
    }

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
        let openable = session.blocks.filter(\.isOpenable)
        if session.isPending {
            parts.append("Loading")
        } else if session.isCompleted {
            parts.append("Completed")
        } else if !openable.isEmpty {
            parts.append("\(openable.filter(\.isCompleted).count) of \(openable.count) blocks done")
        }
        return parts.joined(separator: ", ")
    }
}
