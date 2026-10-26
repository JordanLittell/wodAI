//
//  AssistantButton.swift
//  wodAI
//
//  The pill that opens the trainer chat, floating over the Workout page
//  where the + menu used to be. It's never disabled: when something is
//  still loading or streaming in, the chat says so.
//

import SwiftUI

struct AssistantButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // The same mark as a programmed session's chip.
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                Text("Coach")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(Capsule().fill(Color.brandPrimary))
            // A hairline keeps the edge crisp against dark pages.
            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 10, y: 4)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Open assistant")
        .accessibilityIdentifier("assistantButton")
    }
}

/// Shrinks a little while pressed.
private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color("Background").ignoresSafeArea()
        AssistantButton {}
            .padding(20)
    }
}
