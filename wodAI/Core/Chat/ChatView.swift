//
//  ChatView.swift
//  wodAI
//
//  Chat interface with streaming agent responses
//

import SwiftUI

struct ChatView: View {
    let workout: Workout

    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool

    init() {
        _viewModel = StateObject(wrappedValue: ChatViewModel())
    }
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                chatHeader
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isLoading) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Modification Approval Banner
                if viewModel.hasModificationToApprove {
                    modificationApprovalBanner
                }
                
                chatInputArea
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.addWelcomeMessage()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            } else if viewModel.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        }
    }
    
    // MARK: - Header
    private var chatHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color("PrimaryText"))
                    .font(.system(size: 20, weight: .medium))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("WodAI Assistant")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("PrimaryText"))
                
                if viewModel.isStreaming {
                    Text("typing...")
                        .font(.system(size: 12))
                        .foregroundColor(Color("BrandPrimary"))
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.clearChat() }) {
                Image(systemName: "trash")
                    .foregroundColor(Color("SecondaryText"))
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color("Surface"))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color("Border"))
                .opacity(0.3),
            alignment: .bottom
        )
    }
    
    // MARK: - Modification Approval Banner
    private var modificationApprovalBanner: some View {
        VStack(spacing: 12) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color("Border"))
                .opacity(0.3)
            
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color("BrandPrimary"))
                
                Text("Apply changes to your workout?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Button(action: { viewModel.approveModification() }) {
                    Text("Apply")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("BrandPrimary"))
                        .cornerRadius(16)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color("Surface"))
    }
    
    // MARK: - Input Area
    private var chatInputArea: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color("Border"))
                .opacity(0.3)
            
            HStack(spacing: 12) {
                // Input Field
                HStack(spacing: 8) {
                    TextField("Ask about your workout...", text: $viewModel.currentMessage)
                        .font(.system(size: 16))
                        .foregroundColor(Color("PrimaryText"))
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            if !viewModel.currentMessage.isEmpty && !viewModel.isStreaming {
                                viewModel.sendMessage()
                            }
                        }
                    
                    if !viewModel.currentMessage.isEmpty {
                        Button(action: { viewModel.currentMessage = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color("SecondaryText"))
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color("InteractiveSurface"))
                .cornerRadius(24)
                
                // Send/Stop Button
                if viewModel.isStreaming {
                    Button(action: { viewModel.stopStreaming() }) {
                        ZStack {
                            Circle()
                                .fill(Color("Warning"))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "stop.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                } else {
                    Button(action: { viewModel.sendMessage() }) {
                        ZStack {
                            Circle()
                                .fill(sendButtonColor)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "arrow.up")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .disabled(viewModel.currentMessage.isEmpty || viewModel.isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color("Surface"))
            .animation(.easeInOut(duration: 0.2), value: viewModel.isStreaming)
        }
    }
    
    private var sendButtonColor: Color {
        if viewModel.currentMessage.isEmpty || viewModel.isLoading {
            return Color("Neutral")
        }
        return Color("BrandPrimary")
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(message.text)
                        .font(.system(size: 16))
                        .foregroundColor(message.isUser ? .white : Color("PrimaryText"))
                    
                    if message.isStreaming {
                        StreamingCursor()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .cornerRadius(20)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(Color("TertiaryText"))
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.isUser {
            LinearGradient(
                gradient: Gradient(colors: [Color("BrandPrimary"), Color("BrandSecondary")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color("Surface2")
        }
    }
}

// MARK: - Streaming Cursor
struct StreamingCursor: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(Color("BrandPrimary"))
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color("SecondaryText"))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationAmount)
                        .opacity(1 - animationAmount)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color("Surface2"))
            .cornerRadius(20)
            
            Spacer()
        }
        .onAppear {
            animationAmount = 0.7
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("BrandPrimary"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("InteractiveSurface"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("BrandPrimary").opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview
//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView()
//    }
//}
