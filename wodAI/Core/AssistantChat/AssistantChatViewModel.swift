//
//  AssistantChatViewModel.swift
//  wodAI
//
//  Drives the trainer chat: shows a greeting at once, swaps in the server's
//  (assistantGreeting) when it arrives, and hands tapped client actions
//  (scanner, Create sheet) to the Workout page. Conversation turns
//  (assistantTurn) come with B4; until then there's no text input.
//

import UIKit
import Apollo
import WodAiAPI

/// The server's opening message, Apollo-free.
struct ChatGreeting: Equatable {
    let text: String
    let suggestions: [ChatSuggestion]
}

@MainActor
final class AssistantChatViewModel: ObservableObject {
    @Published private(set) var transcript: ChatTranscript
    @Published var draft = ""

    /// A tapped suggestion the app runs outside the chat (`.openWhiteboardScanner`,
    /// `.openCreateSheet`). The Workout page closes the chat and runs it.
    var onClientAction: (ChatSuggestion) -> Void = { _ in }

    private let loadGreeting: () async throws -> ChatGreeting
    private let defaults: UserDefaults

    /// The last greeting the server sent, so the next chat opens with the
    /// athlete's name before the network answers.
    static let lastGreetingKey = "assistant.lastGreeting"

    init(
        loadGreeting: @escaping () async throws -> ChatGreeting = AssistantChatViewModel.fetchGreeting,
        defaults: UserDefaults = .standard
    ) {
        self.loadGreeting = loadGreeting
        self.defaults = defaults
        var transcript = ChatTranscript.bundled(firstName: nil)
        if let last = defaults.string(forKey: Self.lastGreetingKey) {
            transcript.replaceGreeting(text: last, suggestions: transcript.messages[0].suggestions)
        }
        self.transcript = transcript
    }

    /// Text input arrives with conversation turns (B4).
    var canType: Bool { false }

    func load() async {
        do {
            let greeting = try await loadGreeting()
            defaults.set(greeting.text, forKey: Self.lastGreetingKey)
            transcript.replaceGreeting(text: greeting.text, suggestions: greeting.suggestions)
        } catch {
            // The bundled greeting stays; the error is already reported.
        }
    }

    func tap(_ suggestion: ChatSuggestion) {
        guard let tapped = transcript.tap(suggestion.id) else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        switch tapped.action {
        case .openWhiteboardScanner, .openCreateSheet:
            onClientAction(tapped)
        case .reply, .unsupported:
            break // a turn starts here once B4 lands
        }
    }

    /// Posts a note from the trainer, e.g. why a tapped option can't run yet.
    func say(_ text: String) {
        transcript.appendTrainerNote(text)
    }

    // MARK: Network

    nonisolated static func fetchGreeting() async throws -> ChatGreeting {
        let data: AssistantGreetingQuery.Data = try await withCheckedThrowingContinuation { continuation in
            Network.shared.client.fetch(query: AssistantGreetingQuery(), cachePolicy: .fetchIgnoringCacheCompletely) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "AssistantGreeting")
                        continuation.resume(throwing: GreetingError.server(messages))
                    } else if let data = graphQLResult.data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: GreetingError.server("No data"))
                    }
                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": "AssistantGreeting"])
                    continuation.resume(throwing: error)
                }
            }
        }
        let greeting = data.assistantGreeting
        return ChatGreeting(
            text: greeting.text,
            suggestions: greeting.suggestions.map {
                ChatSuggestion(id: $0.id, label: $0.label, action: .init(serverValue: $0.action.rawValue), payload: $0.payload)
            }
        )
    }

    enum GreetingError: Error {
        case server(String)
    }
}
