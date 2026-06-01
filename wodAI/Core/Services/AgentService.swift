//
//  AgentService.swift
//  wodAI
//
//  Service for handling agent messaging and streaming responses
//

import Foundation
import Apollo
import ApolloWebSocket
import WodAiAPI
import Combine

// MARK: - Agent Service Errors
enum AgentServiceError: LocalizedError {
    case notConnected
    case subscriptionFailed(String)
    case mutationFailed(String)
    case noWorkoutId
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WebSocket is not connected"
        case .subscriptionFailed(let message):
            return "Subscription failed: \(message)"
        case .mutationFailed(let message):
            return "Failed to send message: \(message)"
        case .noWorkoutId:
            return "No workout ID provided"
        }
    }
}

// MARK: - Agent Service
class AgentService: ObservableObject {
    static let shared = AgentService()
    
    // MARK: - Published State
    @Published private(set) var isStreaming = false
    @Published private(set) var currentConversationId: String?
    
    // MARK: - Private Properties
    private var activeSubscription: Apollo.Cancellable?
    private let networkClient: ApolloClient
    
    // MARK: - Initialization
    private init() {
        self.networkClient = Network.shared.client
    }
    
    // For testing/dependency injection
    init(client: ApolloClient) {
        self.networkClient = client
    }
    
    // MARK: - Public Methods
    
    /// Send a message to the agent and return the conversation/message IDs
    func sendMessage(wodId: String, message: String) async throws -> (conversationId: String, messageId: String) {
        let mutation = SendAgentMessageMutation(wodId: wodId, message: message)
        
        return try await withCheckedThrowingContinuation { continuation in
            networkClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let errorMessage = errors.map { $0.localizedDescription }.joined(separator: ", ")
                        continuation.resume(throwing: AgentServiceError.mutationFailed(errorMessage))
                        return
                    }
                    
                    if let data = graphQLResult.data {
                        continuation.resume(returning: (
                            conversationId: data.sendAgentMessage.conversationId,
                            messageId: data.sendAgentMessage.messageId
                        ))
                    } else {
                        continuation.resume(throwing: AgentServiceError.mutationFailed("No data returned"))
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Subscribe to streaming agent responses
    /// - Parameters:
    ///   - wodId: The workout ID to subscribe to
    ///   - onChunk: Called with each text chunk as it streams in
    ///   - onComplete: Called when streaming is complete
    ///   - onError: Called if an error occurs
    func subscribeToResponse(
        wodId: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,  // Returns conversationId
        onError: @escaping (Error) -> Void
    ) {
        // Cancel any existing subscription
        cancelSubscription()
        
        DispatchQueue.main.async {
            self.isStreaming = true
        }
        
        let subscription = AgentResponseSubscription(wodId: wodId)
        
        activeSubscription = networkClient.subscribe(subscription: subscription) { [weak self] result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    let errorMessage = errors.map { $0.localizedDescription }.joined(separator: ", ")
                    DispatchQueue.main.async {
                        self?.isStreaming = false
                    }
                    onError(AgentServiceError.subscriptionFailed(errorMessage))
                    return
                }
                
                if let data = graphQLResult.data {
                    let response = data.agentResponse
                    
                    // Store conversation ID
                    DispatchQueue.main.async {
                        self?.currentConversationId = response.conversationId
                    }
                    
                    // Stream text chunk if not empty
                    if !response.text.isEmpty {
                        onChunk(response.text)
                    }
                    
                    // Check if complete
                    if response.isComplete {
                        DispatchQueue.main.async {
                            self?.isStreaming = false
                        }
                        onComplete(response.conversationId)
                        self?.cancelSubscription()
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isStreaming = false
                }
                onError(error)
            }
        }
    }
    
    /// Cancel the active subscription
    func cancelSubscription() {
        activeSubscription?.cancel()
        activeSubscription = nil
        DispatchQueue.main.async {
            self.isStreaming = false
        }
    }
    
    /// Approve a workout modification from the agent
    func approveWorkoutModification(wodId: String, conversationId: String) async throws -> ApproveWorkoutModificationMutation.Data.ApproveWorkoutModification {
        let mutation = ApproveWorkoutModificationMutation(wodId: wodId, conversationId: conversationId)
        
        return try await withCheckedThrowingContinuation { continuation in
            networkClient.perform(mutation: mutation) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let errorMessage = errors.map { $0.localizedDescription }.joined(separator: ", ")
                        continuation.resume(throwing: AgentServiceError.mutationFailed(errorMessage))
                        return
                    }
                    
                    if let data = graphQLResult.data {
                        continuation.resume(returning: data.approveWorkoutModification)
                    } else {
                        continuation.resume(throwing: AgentServiceError.mutationFailed("No data returned"))
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get conversation history for a workout
    func getConversation(wodId: String) async throws -> GetConversationQuery.Data.GetConversation? {
        let query = GetConversationQuery(wodId: wodId)
        
        return try await withCheckedThrowingContinuation { continuation in
            networkClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let errorMessage = errors.map { $0.localizedDescription }.joined(separator: ", ")
                        continuation.resume(throwing: AgentServiceError.mutationFailed(errorMessage))
                        return
                    }
                    
                    continuation.resume(returning: graphQLResult.data?.getConversation)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
