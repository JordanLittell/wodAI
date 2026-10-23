//
//  AssistantTurnTests.swift
//  wodAITests
//
//  Coverage for conversation turns in the trainer chat: mapping the server's
//  assistantTurn events, what a turn sends, and the view model streaming a
//  reply with a fake runner in place of the network.
//

import Foundation
import Testing
import WodAiAPI
@testable import wodAI

struct AssistantTurnMappingTests {
    private func step(_ json: [String: AnyHashable]) throws -> SubscriptionStep<AssistantTurnEvent> {
        AssistantTurnStream.step(from: try AssistantTurnSubscription.Data.AssistantTurn(data: json))
    }

    private func event(_ json: [String: AnyHashable]) throws -> AssistantTurnEvent? {
        switch try step(json) {
        case let .event(event), let .last(event): return event
        case .failed, .skip: return nil
        }
    }

    @Test func textDeltasAndCompletion() throws {
        #expect(try event(["__typename": "AssistantTextDelta", "text": "How long "]) == .text("How long "))
        guard case let .last(complete) = try step(["__typename": "AssistantTurnComplete", "text": "How long do you have?"]) else {
            Issue.record("complete should end the stream")
            return
        }
        #expect(complete == .complete("How long do you have?"))
    }

    @Test func suggestionsKeepTheirActions() throws {
        let mapped = try event([
            "__typename": "AssistantSuggestions",
            "suggestions": [
                ["__typename": "AssistantSuggestion", "id": "reply-1", "label": "20 min", "action": "REPLY", "payload": NSNull()],
                ["__typename": "AssistantSuggestion", "id": "x", "label": "Pick days", "action": "PICK_DAYS", "payload": "{}"],
            ] as [[String: AnyHashable]],
        ])
        guard case let .suggestions(suggestions) = mapped else {
            Issue.record("expected suggestions")
            return
        }
        #expect(suggestions.map(\.id) == ["reply-1", "x"])
        #expect(suggestions[0].action == .reply)
        #expect(suggestions[1].action == .unsupported("PICK_DAYS"))
        #expect(suggestions[1].payload == "{}")
    }

    @Test func actionsCarryWhatThePageNeeds() throws {
        let mapped = try event([
            "__typename": "AssistantAction",
            "kind": "GENERATE_SESSION",
            "request": "20 min EMOM, dumbbells",
            "scheduledDate": "2026-10-23",
            "dates": NSNull(),
            "replaceWorkoutIds": ["w1"],
        ])
        #expect(mapped == .action(AssistantTurnAction(
            kind: .generateSession, request: "20 min EMOM, dumbbells", scheduledDate: "2026-10-23", dates: [], replaceWorkoutIds: ["w1"]
        )))
        #expect(AssistantTurnAction.Kind(serverValue: "PLAN_WEEK") == .planWeek)
        #expect(AssistantTurnAction.Kind(serverValue: "OPEN_WHITEBOARD_SCANNER") == .openWhiteboardScanner)
        #expect(!AssistantTurnAction(kind: .init(serverValue: "LOG_RUN")).isSupported)
    }

    @Test func aFailureEndsTheStreamWithTheServersMessage() throws {
        guard case let .failed(message) = try step(["__typename": "GenerationFailed", "message": "Start a new chat to keep going."]) else {
            Issue.record("expected a failure")
            return
        }
        #expect(message == "Start a new chat to keep going.")
    }

    @Test func theRequestCarriesTheTranscriptFlowAndTimezone() {
        var chat = ChatTranscript(greeting: "Hey Jordan, how can I help you today?", suggestions: [
            ChatSuggestion(id: "write_today", label: "Write Workout for Today", action: .reply),
        ])
        chat.tap("write_today")
        chat.appendTrainerText("How long do you have?")
        chat.finishTrainerReply()
        chat.send("20 min")
        chat.appendTrainerText("Partial")
        chat.failTrainerReply("I couldn't answer just now. Please try again.")
        let retried = chat.retry()
        #expect(retried)

        let request = AssistantTurnRequest(transcript: chat, timezone: "America/Denver")
        #expect(request.flow == "write_today")
        #expect(request.timezone == "America/Denver")
        // The greeting goes too; the error and the partial reply don't.
        #expect(request.messages == [
            .init(role: .trainer, text: "Hey Jordan, how can I help you today?"),
            .init(role: .athlete, text: "Write Workout for Today"),
            .init(role: .trainer, text: "How long do you have?"),
            .init(role: .athlete, text: "20 min"),
        ])

        let input = request.input
        #expect(input.flow == .some("write_today"))
        #expect(input.timezone == "America/Denver")
        #expect(input.messages.map(\.role) == [.case(.trainer), .case(.athlete), .case(.trainer), .case(.athlete)])
        #expect(input.messages.last?.text == "20 min")
    }

    @Test func theCompleteTextReplacesWhatStreamed() {
        var chat = ChatTranscript(greeting: "Hi", suggestions: [])
        chat.send("hello")
        chat.appendTrainerText("Hey hey")
        chat.appendTrainerText("Hey hey") // a delta repeated on a reconnect
        chat.finishTrainerReply(text: "Hey hey, what are we training?")
        #expect(chat.messages.last?.text == "Hey hey, what are we training?")
        #expect(!chat.isAwaitingTrainer)
    }
}

/// Stands in for the network: hands out a stream per turn and lets the test
/// feed it.
private final class FakeTurns: @unchecked Sendable {
    typealias Continuation = AsyncThrowingStream<AssistantTurnEvent, Error>.Continuation
    private let lock = NSLock()
    private var _requests: [AssistantTurnRequest] = []
    private var _continuations: [Continuation] = []
    private var _terminated = 0

    var requests: [AssistantTurnRequest] { lock.withLock { _requests } }
    var current: Continuation? { lock.withLock { _continuations.last } }
    /// How many turn streams have ended, by finishing or being cancelled.
    var terminated: Int { lock.withLock { _terminated } }

    func run(_ request: AssistantTurnRequest) -> AsyncThrowingStream<AssistantTurnEvent, Error> {
        let (stream, continuation) = AsyncThrowingStream<AssistantTurnEvent, Error>.makeStream()
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            self.lock.withLock { self._terminated += 1 }
        }
        lock.withLock {
            _requests.append(request)
            _continuations.append(continuation)
        }
        return stream
    }
}

@MainActor
struct AssistantTurnViewModelTests {
    private let today = ChatSuggestion(id: "write_today", label: "Write Workout for Today", action: .reply)

    private func viewModel(_ turns: FakeTurns) async -> AssistantChatViewModel {
        let viewModel = AssistantChatViewModel(
            loadGreeting: { [today] in ChatGreeting(text: "Hey Jordan, how can I help you today?", suggestions: [today]) },
            runTurn: turns.run,
            defaults: UserDefaults(suiteName: "AssistantTurnTests-\(UUID().uuidString)")!
        )
        await viewModel.load()
        return viewModel
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func aReplyChipStreamsTheTrainersAnswer() async {
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        #expect(viewModel.canType)

        viewModel.tap(today)
        #expect(turns.requests.count == 1)
        #expect(turns.requests[0].flow == "write_today")
        #expect(turns.requests[0].messages.map(\.text) == ["Hey Jordan, how can I help you today?", "Write Workout for Today"])
        #expect(turns.requests[0].timezone == TimeZone.current.identifier)

        turns.current?.yield(.text("How long "))
        turns.current?.yield(.text("do you have?"))
        await waitUntil { viewModel.transcript.messages.last?.text == "How long do you have?" }
        #expect(viewModel.transcript.isAwaitingTrainer)

        turns.current?.yield(.suggestions([
            ChatSuggestion(id: "reply-1", label: "20 min", action: .reply),
            ChatSuggestion(id: "reply-2", label: "45 min", action: .reply),
        ]))
        turns.current?.yield(.complete("How long do you have?"))
        turns.current?.finish()
        await waitUntil { !viewModel.transcript.isAwaitingTrainer }

        #expect(viewModel.transcript.messages.count == 3)
        #expect(viewModel.transcript.tappableSuggestions.map(\.label) == ["20 min", "45 min"])

        // Tapping one of the trainer's replies runs the next turn.
        viewModel.tap(ChatSuggestion(id: "reply-1", label: "20 min", action: .reply))
        #expect(turns.requests.count == 2)
        #expect(turns.requests[1].messages.last == .init(role: .athlete, text: "20 min"))
        #expect(turns.requests[1].flow == "write_today")
    }

    @Test func typedTextIsSentAndTheDraftCleared() async {
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        viewModel.draft = "   "
        #expect(!viewModel.canSendDraft)
        viewModel.send()
        #expect(turns.requests.isEmpty)

        viewModel.draft = " Can you do a 20 min EMOM? "
        #expect(viewModel.canSendDraft)
        viewModel.send()
        #expect(viewModel.draft.isEmpty)
        #expect(turns.requests.count == 1)
        #expect(turns.requests[0].flow == nil)
        #expect(turns.requests[0].messages.last == .init(role: .athlete, text: "Can you do a 20 min EMOM?"))
    }

    @Test func nothingElseCanBeSentWhileTheTrainerAnswers() async {
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        viewModel.draft = "hello"
        viewModel.send()

        viewModel.draft = "hello again"
        #expect(!viewModel.canSendDraft)
        viewModel.send()
        viewModel.tap(today)

        #expect(turns.requests.count == 1)
        #expect(viewModel.draft == "hello again") // kept for when the reply lands
    }

    @Test func aFailedTurnShowsTheMessageAndRetrySendsItAgain() async {
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        viewModel.tap(today)
        turns.current?.yield(.text("Sure, how"))
        turns.current?.finish(throwing: WorkoutGenerationError.server("This conversation is getting long."))
        await waitUntil { !viewModel.transcript.isAwaitingTrainer }

        #expect(viewModel.transcript.messages.last?.isError == true)
        #expect(viewModel.transcript.messages.last?.text == "This conversation is getting long.")

        viewModel.retry()
        #expect(turns.requests.count == 2)
        #expect(turns.requests[1] == turns.requests[0])
        #expect(viewModel.transcript.isAwaitingTrainer)

        turns.current?.yield(.text("Sure, how long?"))
        turns.current?.yield(.complete("Sure, how long?"))
        turns.current?.finish()
        await waitUntil { !viewModel.transcript.isAwaitingTrainer }
        #expect(viewModel.transcript.messages.map(\.text) == [
            "Hey Jordan, how can I help you today?", "Write Workout for Today", "Sure, how long?",
        ])
    }

    @Test func aTransportErrorShowsTheGenericMessage() async {
        struct Offline: Error {}
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        viewModel.tap(today)
        turns.current?.finish(throwing: Offline())
        await waitUntil { !viewModel.transcript.isAwaitingTrainer }
        #expect(viewModel.transcript.messages.last?.text == AssistantChatViewModel.genericFailure)
    }

    @Test func closingCancelsTheTurnAndLeavesARetry() async {
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        viewModel.tap(today)
        turns.current?.yield(.text("Sure"))
        await waitUntil { viewModel.transcript.messages.last?.text == "Sure" }

        viewModel.cancelTurn()
        await waitUntil { turns.terminated == 1 }

        #expect(turns.terminated == 1) // unsubscribed
        #expect(!viewModel.transcript.isAwaitingTrainer)
        #expect(viewModel.transcript.messages.last?.isError == true)
        // A late event from the cancelled turn changes nothing.
        turns.current?.yield(.text(" thing"))
        try? await Task.sleep(for: .milliseconds(20))
        #expect(viewModel.transcript.messages.last?.text == AssistantChatViewModel.interruptedReply)

        viewModel.retry()
        #expect(turns.requests.count == 2)
    }

    @Test func goingAwayCancelsTheTurn() async {
        let turns = FakeTurns()
        var viewModel: AssistantChatViewModel? = await viewModel(turns)
        viewModel?.tap(today)
        viewModel = nil
        await waitUntil { turns.terminated == 1 }
        #expect(turns.terminated == 1)
    }

    @Test func anActionIsHandedToThePageOnceTheTurnCompletes() async {
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        var handed: [AssistantTurnAction] = []
        viewModel.onAction = { handed.append($0) }
        viewModel.tap(today)

        let action = AssistantTurnAction(kind: .generateSession, request: "20 min EMOM", scheduledDate: "2026-10-23")
        turns.current?.yield(.action(action))
        await waitUntil { viewModel.transcript.messages.last?.author == .trainer }
        #expect(handed.isEmpty)
        // The trainer said nothing, so the chat says what's happening.
        #expect(viewModel.transcript.messages.last?.text == AssistantChatViewModel.note(for: .generateSession))

        turns.current?.yield(.complete(""))
        turns.current?.finish()
        await waitUntil { !handed.isEmpty }
        #expect(handed == [action])
        #expect(viewModel.transcript.messages.last?.text == AssistantChatViewModel.note(for: .generateSession))
    }

    @Test func aFailedTurnRunsNoActionAndUnknownOnesAreDropped() async {
        let turns = FakeTurns()
        let viewModel = await viewModel(turns)
        var handed: [AssistantTurnAction] = []
        viewModel.onAction = { handed.append($0) }

        viewModel.tap(today)
        turns.current?.yield(.text("Planning now."))
        turns.current?.yield(.action(AssistantTurnAction(kind: .planWeek)))
        turns.current?.finish(throwing: WorkoutGenerationError.stalled)
        await waitUntil { !viewModel.transcript.isAwaitingTrainer }
        #expect(handed.isEmpty)

        viewModel.retry()
        turns.current?.yield(.text("Done."))
        turns.current?.yield(.action(AssistantTurnAction(kind: .unsupported("LOG_RUN"))))
        turns.current?.yield(.complete("Done."))
        turns.current?.finish()
        await waitUntil { !viewModel.transcript.isAwaitingTrainer }
        try? await Task.sleep(for: .milliseconds(20))
        #expect(handed.isEmpty)
        #expect(viewModel.transcript.messages.last?.text == "Done.")
    }
}
