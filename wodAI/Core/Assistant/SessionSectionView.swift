//
//  SessionSectionView.swift
//  wodAI
//
//  One session on the Assistant page, always showing its blocks. The header
//  names the session and says where it came from; a red trash button in the
//  top right deletes it. A colored rail down the side tells sessions apart.
//
//  Deleting needs a confirmation, so a stray tap can't remove anything.
//

import SwiftUI

struct SessionSectionView<Blocks: View>: View {
    let session: AssistantSession
    /// Asks to delete; the owner confirms first.
    var onDelete: () -> Void = {}
    @ViewBuilder let blocks: () -> Blocks

    /// A session still streaming in can't be deleted.
    private var canDelete: Bool { !session.isPending }

    var body: some View {
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
        .background(Color("Background"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
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
                optionsMenu
            }
        }
    }

    /// The session's options, behind a three-dot menu. For now only Delete,
    /// which asks the owner to confirm first.
    private var optionsMenu: some View {
        Menu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityIdentifier("deleteSessionButton")
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundColor(Color("SecondaryText"))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Session options")
        .accessibilityIdentifier("sessionOptionsMenu")
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
