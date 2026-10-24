//
//  AssistantTurnStream.swift
//  wodAI
//
//  One trainer turn over the backend's `assistantTurn` subscription. The app
//  holds the conversation and sends it whole each turn; the reply streams
//  back as text deltas, then optional suggestions or an action, then the
//  complete text. A GenerationFailed ends the stream with its message.
//
//  Two layers, as in WorkoutGenerationStream: `AssistantTurnRequest` and
//  `AssistantTurnEvent` are Apollo-free so the view model is testable with a
//  fake runner; `AssistantTurnStream` maps them to and from Apollo.
//

import Foundation
import Apollo
import WodAiAPI

/// What a turn sends: the transcript (errors left out), the option the
/// athlete started from, and the zone that decides what "today" is.
struct AssistantTurnRequest: Equatable {
    struct Message: Equatable {
        enum Role: Equatable { case athlete, trainer }
        let role: Role
        let text: String
    }

    let flow: String?
    let messages: [Message]
    let timezone: String

    init(transcript: ChatTranscript, timezone: String = TimeZone.current.identifier) {
        flow = transcript.flow
        messages = transcript.turnMessages.map {
            Message(role: $0.author == .athlete ? .athlete : .trainer, text: $0.text)
        }
        self.timezone = timezone
    }

    var input: AssistantTurnInput {
        AssistantTurnInput(
            flow: flow.map { .some($0) } ?? .none,
            messages: messages.map {
                AssistantMessageInput(role: .case($0.role == .athlete ? .athlete : .trainer), text: $0.text)
            },
            timezone: timezone
        )
    }
}

/// Something the trainer asks the app to run once the turn ends (the
/// backend's `AssistantAction`). The chat doesn't run it: the Workout page
/// does, through its existing flows.
struct AssistantTurnAction: Equatable {
    enum Kind: Equatable {
        case generateSession
        case planWeek
        case openWhiteboardScanner
        /// One this version of the app doesn't know; dropped.
        case unsupported(String)

        init(serverValue: String) {
            switch serverValue {
            case "GENERATE_SESSION": self = .generateSession
            case "PLAN_WEEK": self = .planWeek
            case "OPEN_WHITEBOARD_SCANNER": self = .openWhiteboardScanner
            default: self = .unsupported(serverValue)
            }
        }
    }

    let kind: Kind
    var request: String? = nil
    /// "YYYY-MM-DD", for a session.
    var scheduledDate: String? = nil
    /// "YYYY-MM-DD" days, for a week plan.
    var dates: [String] = []
    /// The sessions a week plan replaces. Nil and empty differ: nil lets the
    /// server replace the default ones, [] replaces none. Pass it through as is.
    var replaceWorkoutIds: [String]? = nil

    var isSupported: Bool {
        if case .unsupported = kind { return false }
        return true
    }
}

/// One step of a trainer turn, in the order the server sends them.
enum AssistantTurnEvent: Equatable {
    case text(String)
    case suggestions([ChatSuggestion])
    case action(AssistantTurnAction)
    /// The whole reply as the server saw it; the stream ends here.
    case complete(String)
}

typealias AssistantTurnRunner = (AssistantTurnRequest) -> AsyncThrowingStream<AssistantTurnEvent, Error>

struct AssistantTurnStream {
    var client: ApolloClient = Network.shared.client
    /// The first delta can take a few seconds while the model starts; after
    /// that they come well under a second apart.
    var stallTimeout: TimeInterval = 45

    /// Ends after `complete`, on a failure (GenerationFailed arrives as
    /// `WorkoutGenerationError.server` with the server's message, written for
    /// the athlete), or when the server goes quiet.
    func events(for request: AssistantTurnRequest) -> AsyncThrowingStream<AssistantTurnEvent, Error> {
        subscriptionStream(
            AssistantTurnSubscription(input: request.input),
            client: client,
            operation: "AssistantTurn",
            fallbackMessage: AssistantChatViewModel.genericFailure,
            stallTimeout: stallTimeout
        ) { data in
            Self.step(from: data.assistantTurn)
        }
    }

    // MARK: - Mapping

    static func step(from event: AssistantTurnSubscription.Data.AssistantTurn) -> SubscriptionStep<AssistantTurnEvent> {
        if let delta = event.asAssistantTextDelta {
            return .event(.text(delta.text))
        }
        if let suggestions = event.asAssistantSuggestions {
            return .event(.suggestions(suggestions.suggestions.map {
                ChatSuggestion(id: $0.id, label: $0.label, action: .init(serverValue: $0.action.rawValue, payload: $0.payload), payload: $0.payload)
            }))
        }
        if let action = event.asAssistantAction {
            return .event(.action(AssistantTurnAction(
                kind: .init(serverValue: action.kind.rawValue),
                request: action.request,
                scheduledDate: action.scheduledDate,
                dates: action.dates ?? [],
                replaceWorkoutIds: action.replaceWorkoutIds
            )))
        }
        if let complete = event.asAssistantTurnComplete {
            return .last(.complete(complete.text))
        }
        if let failed = event.asGenerationFailed {
            return .failed(failed.message)
        }
        return .skip
    }
}
