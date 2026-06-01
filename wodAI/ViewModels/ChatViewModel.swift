//
//  ChatViewModel.swift
//  wodAI
//
//  ViewModel for chat interface with streaming agent responses
//

import SwiftUI
import Combine
import WodAiAPI

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var text: String
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.isStreaming == rhs.isStreaming
    }
}

// MARK: - Chat View Model
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var isStreaming: Bool = false
    @Published var errorMessage: String?
    @Published var hasModificationToApprove: Bool = false
    
    // MARK: - Private Properties
    private let agentService: AgentService
    private var cancellables = Set<AnyCancellable>()
    private var currentConversationId: String?
    private var streamingMessageId: UUID?
    
    // MARK: - Initialization
    init(agentService: AgentService = .shared) {
        self.agentService = agentService
        // Observe streaming state from service
        agentService.$isStreaming
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streaming in
                self?.isStreaming = streaming
            }
            .store(in: &cancellables)
        
        // Load existing conversation if workout exists
        if self.messages.count < 1 {
            loadConversationHistory()
        }
    }
    
    // MARK: - Public Methods
    
    func addWelcomeMessage() {
        guard messages.isEmpty else { return }
        
        let welcomeText: String = "Hi! I can help you modify workouts.\n\nI can:\n• Adjust intensity or duration\n• Swap exercises for available equipment\n• Scale movements for your fitness level\n• Explain proper technique\n• Change the workout structure\n\nWhat would you like to change?"
    
        let welcomeMessage = ChatMessage(text: welcomeText, isUser: false)
        messages.append(welcomeMessage)
    }
    
    func sendMessage() {
        let trimmedMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        guard !isLoading && !isStreaming else { return }
        
        // Add user message
        let userMessage = ChatMessage(text: trimmedMessage, isUser: true)
        messages.append(userMessage)
        
        // Clear input
        let messageToSend = trimmedMessage
        currentMessage = ""
        errorMessage = nil
        
        let workoutId = "234"
        
        // Send to backend
        isLoading = true
        
        Task { @MainActor in
            do {
                // 1. Send the message
                let response = try await agentService.sendMessage(wodId: workoutId, message: messageToSend)
                self.currentConversationId = response.conversationId
                
                // 2. Create placeholder message for streaming response
                let streamingMessage = ChatMessage(
                    text: "",
                    isUser: false,
                    isStreaming: true
                )
                self.streamingMessageId = streamingMessage.id
                self.messages.append(streamingMessage)
                self.isLoading = false
                
                // 3. Subscribe to streaming response
                self.subscribeToAgentResponse(wodId: workoutId)
                
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }
    
    func stopStreaming() {
        agentService.cancelSubscription()
        
        // Mark streaming message as complete
        if let streamingId = streamingMessageId,
           let index = messages.firstIndex(where: { $0.id == streamingId }) {
            messages[index].isStreaming = false
        }
        streamingMessageId = nil
    }
    
    func clearChat() {
        stopStreaming()
        messages.removeAll()
        currentConversationId = nil
        hasModificationToApprove = false
        addWelcomeMessage()
    }
    
    func approveModification() {
        guard let conversationId = currentConversationId else {
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                let updatedWorkout = try await agentService.approveWorkoutModification(
                    wodId: "234",
                    conversationId: conversationId
                )
                
                self.isLoading = false
                self.hasModificationToApprove = false
                
                // Add confirmation message
                let confirmMessage = ChatMessage(
                    text: "✅ Your workout has been updated! The changes have been applied to **\(updatedWorkout.name)**.",
                    isUser: false
                )
                self.messages.append(confirmMessage)
                
                // Post notification so other views can refresh
                NotificationCenter.default.post(name: .workoutUpdated, object: updatedWorkout)
                
            } catch {
                self.isLoading = false
                self.handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func subscribeToAgentResponse(wodId: String) {
        agentService.subscribeToResponse(
            wodId: wodId,
            onChunk: { [weak self] chunk in
                DispatchQueue.main.async {
                    self?.appendChunkToStreamingMessage(chunk)
                }
            },
            onComplete: { [weak self] conversationId in
                DispatchQueue.main.async {
                    self?.finishStreamingMessage()
                    self?.currentConversationId = conversationId
                    // Check if the response suggests a modification
                    self?.checkForModificationSuggestion()
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.finishStreamingMessage()
                    self?.handleError(error)
                }
            }
        )
    }
    
    private func appendChunkToStreamingMessage(_ chunk: String) {
        guard let streamingId = streamingMessageId,
              let index = messages.firstIndex(where: { $0.id == streamingId }) else {
            return
        }
        
        messages[index].text += chunk
    }
    
    private func finishStreamingMessage() {
        guard let streamingId = streamingMessageId,
              let index = messages.firstIndex(where: { $0.id == streamingId }) else {
            return
        }
        
        messages[index].isStreaming = false
        streamingMessageId = nil
    }
    
    private func checkForModificationSuggestion() {
        // Check if the last AI message suggests a workout modification
        guard let lastMessage = messages.last,
              !lastMessage.isUser else { return }
        
        let text = lastMessage.text.lowercased()
        let modificationKeywords = [
            "modified", "updated", "changed", "adjusted",
            "here's the new", "here is the updated",
            "i've made", "i have made",
            "apply these changes", "approve"
        ]
        
        hasModificationToApprove = modificationKeywords.contains { text.contains($0) }
    }
    
    private func loadConversationHistory() {
    
        Task { @MainActor in
            do {
                if let conversation = try await agentService.getConversation(wodId: "234") {
                    self.currentConversationId = conversation.id
                    
                    // Convert stored messages to ChatMessage
                    let loadedMessages: [ChatMessage] = conversation.messages.map { msg in
                        ChatMessage(
                            text: msg.content,
                            isUser: msg.role == .user,
                            timestamp: parseDate(msg.createdAt) ?? Date()
                        )
                    }
                    
                    if !loadedMessages.isEmpty {
                        self.messages = loadedMessages
                    }
                }
            } catch {
                // Silently fail - we'll just start fresh
                print("Failed to load conversation history: \(error)")
            }
        }
    }
    
    private func parseDate(_ dateTime: WodAiAPI.DateTime) -> Date? {
        // DateTime is a custom scalar - handle conversion
        // This depends on how your DateTime scalar is configured
        return nil // Placeholder - implement based on your DateTime format
    }
    
    private func handleError(_ error: Error) {
        let errorText: String
        if let agentError = error as? AgentServiceError {
            errorText = agentError.localizedDescription
        } else {
            errorText = "I'm having trouble connecting right now. Please try again in a moment."
        }
        
        errorMessage = errorText
        
        let errorChatMessage = ChatMessage(
            text: "⚠️ \(errorText)",
            isUser: false
        )
        messages.append(errorChatMessage)
    }
    
    private func handleLocalResponse(for message: String) {
        // Fallback for when no workout is provided
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            
            let response = ChatMessage(
                text: "To modify a workout, please open a specific workout first and tap the chat icon. I'll be able to help you customize it to your needs!",
                isUser: false
            )
            self?.messages.append(response)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let workoutUpdated = Notification.Name("workoutUpdated")
}
