//
//  ChatFloatingButton.swift
//  wodAI
//
//  Created on 2025-11-25.
//

import SwiftUI

struct ChatFloatingButton: View {
    @State private var isShowingChat = false
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            isShowingChat = true
        }) {
            ZStack {
                // Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color("BrandPrimary"), Color("BrandSecondary")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // Icon
                Image(systemName: "message.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                // Pulse animation ring
                Circle()
                    .stroke(Color("BrandPrimary"), lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                    .opacity(isAnimating ? 0.0 : 0.5)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
        }
        .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 8, x: 0, y: 4)
        .fullScreenCover(isPresented: $isShowingChat) {
            NavigationView {
                ChatView()
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Modifier to easily add chat button to any view
struct ChatFloatingButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ChatFloatingButton()
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
    }
}

extension View {
    func withChatButton() -> some View {
        modifier(ChatFloatingButtonModifier())
    }
}
