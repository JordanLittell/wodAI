//
//  ExpandableText.swift
//  wodAI
//
//  Text clamped to a few lines with the last line fading out and a chevron
//  that expands it. For guidance most athletes skim past: it stays out of the
//  way, but the rest is one tap away. Text that already fits shows neither the
//  fade nor the chevron.
//

import SwiftUI

struct ExpandableText: View {
    let text: String
    var lineLimit: Int = 3

    @State private var isExpanded = false
    @State private var clampedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    /// Whether the full text is taller than the clamped version.
    private var isTruncated: Bool { fullHeight > clampedHeight + 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .lineLimit(isExpanded ? nil : lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                    if !isExpanded { clampedHeight = height }
                }
                // The unclamped text, laid out invisibly at the same width, so
                // we know whether clamping actually hid anything.
                .background(alignment: .topLeading) {
                    Text(text)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                            fullHeight = height
                        }
                }
                .mask(fadeMask)

            if isTruncated {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("SecondaryText"))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isTruncated else { return }
            withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isTruncated ? (isExpanded ? "Collapses the text" : "Shows the full text") : "")
        .accessibilityAddTraits(isTruncated ? .isButton : [])
    }

    @ViewBuilder
    private var fadeMask: some View {
        if isExpanded || !isTruncated {
            Rectangle()
        } else {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.6),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    List {
        Section {
            ExpandableText(text: "Rest 2-3 minutes between sets. Build across the working sets so the last triple is heavy but clean — if bar speed drops noticeably, hold the weight rather than adding more. Brace before every rep, keep the chest up out of the hole, and drive the knees out over the toes. Stop the set if your back rounds.")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
        }
        Section {
            ExpandableText(text: "Short guidance fits, so no chevron.")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
        }
    }
}
