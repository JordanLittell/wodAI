//
//  HIITPrescriptionCard.swift
//  wodAI
//
//  The WOD card drawn from the piece's movement lines instead of its
//  whiteboard text: format header, then one row per line (amount, movement,
//  load). A compound piece lists each part under its own header with the rest
//  between. When `swapping` is set, tapping a movement's name opens a searchable
//  list of what it can be swapped for (MovementSwapSheet).
//

import SwiftUI

struct HIITPrescriptionCard<Accessory: View>: View {
    let format: String?
    let lines: [HIITLine]
    let parts: [HIITPartHeader]
    var borderColor: Color = Color("Border")
    var borderWidth: CGFloat = 1
    /// Makes each movement name a swap menu; nil shows plain names.
    var swapping: HIITLineSwapping? = nil
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                if let format {
                    Text(format)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryText"))
                }
                Spacer()
                accessory()
            }

            if parts.isEmpty {
                rows(lines, repScheme: isRepScheme(format))
            } else {
                ForEach(Array(parts.sorted { $0.order < $1.order }.enumerated()), id: \.element.id) { index, part in
                    VStack(alignment: .leading, spacing: 8) {
                        if let header = part.format {
                            Text(header)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color("PrimaryText"))
                        }
                        rows(lines.filter { $0.partId == part.id }, repScheme: isRepScheme(part.format))
                        if index < parts.count - 1, let rest = part.restAfterSeconds, rest > 0 {
                            Text("Rest \(rest / 60):\(String(format: "%02d", rest % 60))")
                                .font(.footnote)
                                .foregroundColor(Color("SecondaryText"))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }

    private func rows(_ lines: [HIITLine], repScheme: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(lines.sorted { $0.line < $1.line }) { line in
                row(line, repScheme: repScheme)
            }
        }
    }

    private func row(_ line: HIITLine, repScheme: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let amount = line.amountText(repScheme: repScheme) {
                Text(amount)
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .foregroundColor(Color("PrimaryText"))
            }
            name(line, repScheme: repScheme)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let load = line.loadText {
                Text(load)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
        }
    }

    @ViewBuilder
    private func name(_ line: HIITLine, repScheme: Bool) -> some View {
        if let swapping {
            Button {
                swapping.open(line)
            } label: {
                HStack(spacing: 4) {
                    Text(line.name)
                        .font(.body)
                        .foregroundColor(Color("PrimaryText"))
                        .multilineTextAlignment(.leading)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color("BrandPrimary"))
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(line.name)
            .accessibilityHint("Swap this movement")
        } else {
            Text(line.name)
                .font(.body)
                .foregroundColor(Color("PrimaryText"))
        }
    }
}

/// What a card needs to make its movement names swappable.
struct HIITLineSwapping {
    /// Opens the searchable swap list for this line (MovementSwapSheet).
    let open: (HIITLine) -> Void
}
