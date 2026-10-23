//
//  AssistantChatViewModel.swift
//  wodAI
//
//  Drives the trainer chat: shows a greeting at once, swaps in the server's
//  (assistantGreeting) when it arrives, and hands tapped client actions
//  (scanner, Create sheet) to the Workout page. A reply chip or typed text
//  runs a turn (assistantTurn): the reply streams into the transcript, and
//  an action the trainer ends on goes to the page through `onAction`.
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
    /// What the trainer asked the app to run (write a session, plan the
    /// week, open the scanner), handed over once the turn ends. The Workout
    /// page runs it through its existing flows.
    var onAction: (AssistantTurnAction) -> Void = { _ in }

    private let loadGreeting: () async throws -> ChatGreeting
    private let runTurn: AssistantTurnRunner
    private let defaults: UserDefaults
    /// The turn in flight. Nonisolated so `deinit` can cancel it; only
    /// touched on the main actor otherwise.
    nonisolated(unsafe) private var turnTask: Task<Void, Never>?

    /// Shown when a turn fails without a message for the athlete. Mirrors the
    /// backend's.
    static let genericFailure = "I couldn't answer just now. Please try again."
    /// Shown when the chat closes while the trainer is still answering.
    static let interruptedReply = "I didn't get to finish that reply."

    /// The last greeting the server sent, so the next chat opens with the
    /// athlete's name before the network answers.
    static let lastGreetingKey = "assistant.lastGreeting"

    init(
        loadGreeting: @escaping () async throws -> ChatGreeting = AssistantChatViewModel.fetchGreeting,
        runTurn: @escaping AssistantTurnRunner = { AssistantTurnStream().events(for: $0) },
        defaults: UserDefaults = .standard
    ) {
        self.loadGreeting = loadGreeting
        self.runTurn = runTurn
        self.defaults = defaults
        var transcript = ChatTranscript.bundled(firstName: nil)
        if let last = defaults.string(forKey: Self.lastGreetingKey) {
            transcript.replaceGreeting(text: last, suggestions: transcript.messages[0].suggestions)
        }
        self.transcript = transcript
    }

    deinit {
        turnTask?.cancel()
    }

    var canType: Bool { true }

    /// The send button is live when there's text and the trainer isn't
    /// answering.
    var canSendDraft: Bool {
        transcript.canSend && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
        case .reply:
            startTurn()
        case .unsupported:
            break
        }
    }

    func send() {
        guard transcript.send(draft) else { return }
        draft = ""
        startTurn()
    }

    /// Asks again after a failed turn, with the same transcript.
    func retry() {
        guard transcript.retry() else { return }
        startTurn()
    }

    /// Stops the turn in flight (the chat closed). What streamed so far stays,
    /// followed by an error the athlete can retry from.
    func cancelTurn() {
        guard let task = turnTask else { return }
        task.cancel()
        turnTask = nil
        transcript.failTrainerReply(Self.interruptedReply)
    }

    // MARK: Turns

    /// Runs one turn for the transcript as it stands (the athlete's message
    /// is already in it).
    private func startTurn() {
        turnTask?.cancel()
        let events = runTurn(AssistantTurnRequest(transcript: transcript))
        turnTask = Task { [weak self] in
            // The trainer may end on an action; it's handed over only once
            // the turn completes, so a failed turn never runs one.
            var action: AssistantTurnAction?
            do {
                for try await event in events {
                    guard let self, !Task.isCancelled else { return }
                    switch event {
                    case let .text(delta):
                        self.transcript.appendTrainerText(delta)
                    case let .suggestions(suggestions):
                        self.transcript.setTrainerSuggestions(suggestions)
                    case let .action(next) where next.isSupported:
                        action = next
                        if !self.replyHasText { self.transcript.appendTrainerText(Self.note(for: next.kind)) }
                    case .action:
                        break
                    case let .complete(text):
                        self.transcript.finishTrainerReply(text: text)
                    }
                }
                guard let self, !Task.isCancelled else { return }
                // A stream that ends without `complete` still ends the turn.
                self.transcript.finishTrainerReply()
                self.turnTask = nil
                if let action { self.onAction(action) }
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.turnTask = nil
                self.transcript.failTrainerReply(Self.message(for: error))
            }
        }
    }

    /// Whether this turn's reply has any text yet.
    private var replyHasText: Bool {
        guard transcript.isAwaitingTrainer, let last = transcript.messages.last else { return false }
        return last.author == .trainer && !last.text.isEmpty
    }

    /// A line for an action the trainer ended on without saying anything.
    static func note(for kind: AssistantTurnAction.Kind) -> String {
        switch kind {
        case .generateSession: return "On it, writing your workout now."
        case .planWeek: return "On it, planning your week now."
        case .openWhiteboardScanner: return "Opening the scanner."
        case .unsupported: return ""
        }
    }

    /// The server's own message when it sent one (GenerationFailed is
    /// written for the athlete); otherwise a generic one. Transport and
    /// GraphQL errors are already reported by the stream; in-band failures
    /// and stalls are reported here.
    private static func message(for error: Error) -> String {
        switch error {
        case let WorkoutGenerationError.server(message):
            TelemetryService.captureMessage("assistant.turn_failed", level: .warning, tags: ["reason": "server"])
            return message.isEmpty ? genericFailure : message
        case WorkoutGenerationError.stalled:
            TelemetryService.captureMessage("assistant.turn_failed", level: .warning, tags: ["reason": "stalled"])
            return genericFailure
        default:
            return genericFailure
        }
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
