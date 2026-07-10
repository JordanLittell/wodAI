//
//  SwipeToConfirmButton.swift
//  wodAI
//
//  A "slide to confirm" control: the user drags a thumb across the full track to
//  fire the action. Guards a disruptive action (finishing a workout) against
//  accidental taps far more strongly than a tap — a partial swipe springs back.
//

import SwiftUI
import UIKit

struct SwipeToConfirmButton: View {
    let title: String
    var systemImage: String = "checkmark"
    var tint: Color = Color("Success")
    let action: () -> Void

    @State private var offset: CGFloat = 0
    @State private var didCrossThreshold = false

    private let thumbSize: CGFloat = 52
    private let trackHeight: CGFloat = 60
    private let inset: CGFloat = 4
    /// Fraction of the track that must be crossed to confirm.
    private let threshold: CGFloat = 0.9

    var body: some View {
        GeometryReader { geo in
            let maxOffset = max(1, geo.size.width - thumbSize - inset * 2)
            let progress = min(1, offset / maxOffset)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(tint.opacity(0.16))

                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(tint.opacity(0.32))
                    .frame(width: offset + thumbSize)

                HStack(spacing: 4) {
                    Text(title).fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                    Image(systemName: "chevron.right").opacity(0.5)
                }
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
                .opacity(1 - Double(progress))

                Circle()
                    .fill(tint)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Image(systemName: systemImage)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .offset(x: offset + inset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                offset = min(max(0, value.translation.width), maxOffset)
                                let crossed = offset >= maxOffset * threshold
                                if crossed != didCrossThreshold {
                                    didCrossThreshold = crossed
                                    if crossed {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    }
                                }
                            }
                            .onEnded { _ in
                                if offset >= maxOffset * threshold {
                                    confirm(maxOffset)
                                } else {
                                    reset()
                                }
                            }
                    )
            }
        }
        .frame(height: trackHeight)
        .accessibilityElement()
        .accessibilityLabel("Swipe to \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }

    private func confirm(_ maxOffset: CGFloat) {
        withAnimation(.easeOut(duration: 0.15)) { offset = maxOffset }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        action()
    }

    private func reset() {
        didCrossThreshold = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = 0 }
    }
}
