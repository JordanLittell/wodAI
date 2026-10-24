//
//  AssistantChatTests.swift
//  wodAITests
//

import Foundation
import Testing
@testable import wodAI

struct AssistantChatTests {
    private let whiteboard = ChatSuggestion(id: "whiteboard", label: "Import Workout From Whiteboard", action: .openWhiteboardScanner)
    private let week = ChatSuggestion(id: "program_week", label: "Program My Week", action: .reply)
    private let today = ChatSuggestion(id: "write_today", label: "Write Workout for Today", action: .reply)

    private func greeted() -> ChatTranscript {
        ChatTranscript(greeting: "Hey Jordan, how can I help you today?", suggestions: [whiteboard, week, today])
    }

    // MARK: Greeting

    @Test func greetsByNameOrWithoutOne() {
        #expect(ChatTranscript.greetingText(firstName: "Jordan") == "Hey Jordan, how can I help you today?")
        for missing in [nil, "", "   "] as [String?] {
            #expect(ChatTranscript.greetingText(firstName: missing) == "Hey, how can I help you today?")
        }
    }

    @Test func bundledGreetingOffersTheServersDefaultOptions() {
        let chat = ChatTranscript.bundled(firstName: nil)
        #expect(chat.tappableSuggestions.map(\.id) == ["whiteboard", "program_week", "write_today"])
        #expect(chat.tappableSuggestions.map(\.action) == [.openWhiteboardScanner, .reply, .reply])
    }

    @Test func serverGreetingReplacesTheBundledOneOnlyBeforeTheAthleteStarts() {
        var chat = ChatTranscript.bundled(firstName: "Jordan")
        chat.replaceGreeting(text: "Hey Jordan!", suggestions: [week])
        #expect(chat.messages.count == 1)
        #expect(chat.messages[0].text == "Hey Jordan!")
        #expect(chat.tappableSuggestions == [week])

        chat.tap("program_week")
        chat.replaceGreeting(text: "Too late", suggestions: [today])
        #expect(chat.messages[0].text == "Hey Jordan!")
    }

    // MARK: Suggestions

    @Test func unknownActionsAreHidden() {
        #expect(ChatSuggestion.Action(serverValue: "REPLY") == .reply)
        #expect(ChatSuggestion.Action(serverValue: "OPEN_WHITEBOARD_SCANNER") == .openWhiteboardScanner)
        #expect(ChatSuggestion.Action(serverValue: "OPEN_CREATE_SHEET") == .openCreateSheet)
        let future = ChatSuggestion(id: "x", label: "Share", action: ChatSuggestion.Action(serverValue: "SHARE_WORKOUT"))
        let chat = ChatTranscript(greeting: "Hi", suggestions: [future, week])
        #expect(chat.tappableSuggestions == [week])
    }

    @Test func tappingAReplyPostsItAndStartsTheFlow() {
        var chat = greeted()
        let tapped = chat.tap("program_week")
        #expect(tapped == week)
        #expect(chat.messages.last?.author == .athlete)
        #expect(chat.messages.last?.text == "Program My Week")
        #expect(chat.flow == "program_week")
        #expect(chat.isAwaitingTrainer)
    }

    @Test func aSecondTapCannotStartASecondFlow() {
        var chat = greeted()
        chat.tap("program_week")
        let other = chat.tap("write_today")
        let again = chat.tap("program_week")
        #expect(other == nil)
        #expect(again == nil)
        #expect(chat.messages.count == 2)
        #expect(chat.messages[0].answered)
    }

    @Test func aClientActionIsReturnedButPostsNothing() {
        var chat = greeted()
        let tapped = chat.tap("whiteboard")
        #expect(tapped?.action == .openWhiteboardScanner)
        #expect(chat.messages.count == 1)
        #expect(!chat.isAwaitingTrainer)
        #expect(chat.tappableSuggestions.isEmpty)
    }

    @Test func typingAnswersTheTurnToo() {
        var chat = greeted()
        let blank = chat.send("   ")
        let typed = chat.send(" Can you do a 20 min EMOM? ")
        #expect(!blank)
        #expect(typed)
        #expect(chat.messages.last?.text == "Can you do a 20 min EMOM?")
        #expect(chat.flow == nil)
        let tapped = chat.tap("write_today")
        let whileAnswering = chat.send("hello?")
        #expect(tapped == nil)
        #expect(!whileAnswering) // the trainer is answering
    }

    // MARK: Trainer turns

    @Test func streamsTheReplyIntoOneMessageWithItsSuggestions() {
        var chat = greeted()
        chat.tap("write_today")
        chat.appendTrainerText("How long ")
        chat.appendTrainerText("do you have?")
        chat.setTrainerSuggestions([ChatSuggestion(id: "reply-1", label: "20 min", action: .reply)])
        chat.finishTrainerReply()

        #expect(chat.messages.count == 3)
        #expect(chat.messages.last?.text == "How long do you have?")
        #expect(chat.tappableSuggestions.map(\.label) == ["20 min"])
        let reply = chat.tap("reply-1")
        #expect(reply != nil)
        #expect(chat.flow == "write_today") // a later reply doesn't change the flow
    }

    // MARK: View model

    private func defaults() -> UserDefaults {
        let suite = "AssistantChatTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @MainActor @Test func opensWithTheLastServerGreetingThenTheNewOne() async {
        let store = defaults()
        store.set("Hey Jordan, how can I help you today?", forKey: AssistantChatViewModel.lastGreetingKey)
        let viewModel = AssistantChatViewModel(
            loadGreeting: { ChatGreeting(text: "Hey Jordan!", suggestions: [week]) },
            defaults: store
        )
        #expect(viewModel.transcript.messages[0].text == "Hey Jordan, how can I help you today?")

        await viewModel.load()

        #expect(viewModel.transcript.messages[0].text == "Hey Jordan!")
        #expect(viewModel.transcript.tappableSuggestions == [week])
        #expect(store.string(forKey: AssistantChatViewModel.lastGreetingKey) == "Hey Jordan!")
    }

    @MainActor @Test func keepsTheBundledGreetingWhenTheServerFails() async {
        struct Offline: Error {}
        let viewModel = AssistantChatViewModel(loadGreeting: { throw Offline() }, defaults: defaults())
        await viewModel.load()
        #expect(viewModel.transcript.messages[0].text == "Hey, how can I help you today?")
        #expect(viewModel.transcript.tappableSuggestions.map(\.id) == ["whiteboard", "program_week", "write_today"])
    }

    @MainActor @Test func handsClientActionsToThePageOnce() async {
        let viewModel = AssistantChatViewModel(
            loadGreeting: { ChatGreeting(text: "Hi", suggestions: [whiteboard, week]) },
            defaults: defaults()
        )
        await viewModel.load()
        var handed: [String] = []
        viewModel.onClientAction = { handed.append($0.id) }

        viewModel.tap(whiteboard)
        viewModel.tap(whiteboard)

        #expect(handed == ["whiteboard"])
    }

    @MainActor @Test func theTrainerCanExplainWhyAnOptionCannotRunYet() async {
        let viewModel = AssistantChatViewModel(
            loadGreeting: { ChatGreeting(text: "Hi", suggestions: [whiteboard]) },
            defaults: defaults()
        )
        await viewModel.load()
        viewModel.onClientAction = { _ in viewModel.say("A session is still coming in.") }

        viewModel.tap(whiteboard)

        #expect(viewModel.transcript.messages.map(\.text) == ["Hi", "A session is still coming in."])
        #expect(viewModel.transcript.messages.last?.author == .trainer)
        #expect(!viewModel.transcript.isAwaitingTrainer)
    }

    @Test func aNoteWaitsForTheTrainersReply() {
        var chat = greeted()
        chat.tap("program_week")
        chat.appendTrainerNote("ignored")
        #expect(chat.messages.count == 2)
    }

    @Test func aFailedTurnCanBeRetriedWithoutTheErrorOrPartialReply() {
        var chat = greeted()
        chat.tap("write_today")
        chat.appendTrainerText("Sure, how")
        chat.failTrainerReply("I couldn't answer just now. Please try again.")
        #expect(chat.messages.last?.isError == true)
        #expect(chat.turnMessages.allSatisfy { !$0.isError })

        let retried = chat.retry()
        #expect(retried)
        #expect(chat.messages.last?.author == .athlete)
        #expect(chat.isAwaitingTrainer)
        let again = chat.retry()
        #expect(!again)
    }
}
