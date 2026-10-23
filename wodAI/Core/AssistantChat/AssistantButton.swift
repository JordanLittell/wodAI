//
//  AssistantButton.swift
//  wodAI
//
//  The round button that opens the trainer chat, floating over the Workout
//  page where the + menu used to be. It's never disabled: when something is
//  still loading or streaming in, the chat says so.
//

import SwiftUI

struct AssistantButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.brandPrimary))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
        .accessibilityLabel("Open assistant")
        .accessibilityIdentifier("assistantButton")
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color("Background").ignoresSafeArea()
        AssistantButton {}
            .padding(20)
    }
}
