//
//  AssistantAnalyticsTests.swift
//  wodAITests
//
//  The coach chat's product events (PostHog): their names and properties,
//  and when the chat sends them.
//

import Foundation
import Testing
@testable import wodAI

struct AnalyticsEventTests {
    @Test func namesMatchThePRD() {
        let names = [
            AnalyticsEvent.assistantOpened,
            .assistantOptionTapped(option: "whiteboard", flow: nil),
            .assistantTurn(flow: nil, number: 1, isRetry: false),
            .assistantFlowCompleted(flow: nil, action: "plan_week"),
            .assistantFlowFailed(flow: nil, reason: "server"),
            .assistantClosed(flow: nil, stage: "greeting", turns: 0),
        ].map(\.name)
        #expect(names == [
            "assistant_opened", "assistant_option_tapped", "assistant_turn",
            "assistant_flow_completed", "assistant_flow_failed", "assistant_closed",
        ])
    }

    @Test func propertiesCarryIdsAndCountsAndLeaveOutAMissingFlow() {
        #expect(AnalyticsEvent.assistantTurn(flow: "write_today", number: 2, isRetry: true).properties
            == ["flow": "write_today", "turn": 2, "retry": true])
        #expect(AnalyticsEvent.assistantClosed(flow: nil, stage: "chatting", turns: 1).properties
            == ["stage": "chatting", "turns": 1])
        #expect(AnalyticsEvent.assistantOpened.properties.isEmpty)
    }
}

@MainActor
struct AssistantChatTrackingTests {
    private let week = ChatSuggestion(id: "program_week", label: "Program My Week", action: .reply)
    private let whiteboard = ChatSuggestion(id: "whiteboard", label: "Import Workout From Whiteboard", action: .openWhiteboardScanner)

    /// A chat whose turns end however `turn` says, recording what it tracks.
    private func chat(
        turn: @escaping () -> AsyncThrowingStream<AssistantTurnEvent, Error> = { AsyncThrowingStream { $0.finish() } }
    ) async -> (AssistantChatViewModel, () -> [AnalyticsEvent]) {
        var events: [AnalyticsEvent] = []
        let viewModel = AssistantChatViewModel(
            loadGreeting: { [week, whiteboard] in ChatGreeting(text: "Hi", suggestions: [whiteboard, week]) },
            runTurn: { _ in turn() },
            defaults: UserDefaults(suiteName: "AssistantChatTrackingTests-\(UUID().uuidString)")!,
            track: { events.append($0) }
        )
        await viewModel.load()
        return (viewModel, { events })
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func aChatClosedAtTheGreetingSaysSo() async {
        let (viewModel, events) = await chat()
        viewModel.recordOpen()
        viewModel.recordClose()
        viewModel.recordClose() // once only
        #expect(events() == [.assistantOpened, .assistantClosed(flow: nil, stage: "greeting", turns: 0)])
    }

    @Test func aFlowThatHandsOffIsCompleted() async {
        let (viewModel, events) = await chat(turn: {
            AsyncThrowingStream {
                $0.yield(.text("Planning now."))
                $0.yield(.action(AssistantTurnAction(kind: .planWeek, dates: ["2026-10-26"])))
                $0.yield(.complete("Planning now."))
                $0.finish()
            }
        })
        viewModel.onAction = { _ in viewModel.recordHandOff("plan_week") }

        viewModel.tap(week)
        await waitUntil { !viewModel.transcript.isAwaitingTrainer }
        viewModel.recordClose()

        #expect(events() == [
            .assistantOptionTapped(option: "program_week", flow: "program_week"),
            .assistantTurn(flow: "program_week", number: 1, isRetry: false),
            .assistantFlowCompleted(flow: "program_week", action: "plan_week"),
            .assistantClosed(flow: "program_week", stage: "handed_off", turns: 1),
        ])
    }

    @Test func aFailedTurnAndItsRetryAreBothCounted() async {
        let (viewModel, events) = await chat(turn: {
            AsyncThrowingStream { $0.finish(throwing: WorkoutGenerationError.stalled) }
        })

        viewModel.tap(week)
        await waitUntil { viewModel.transcript.messages.last?.isError == true }
        viewModel.retry()
        await waitUntil { viewModel.transcript.messages.last?.isError == true && !viewModel.transcript.isAwaitingTrainer }
        viewModel.recordClose()

        #expect(events().contains(.assistantFlowFailed(flow: "program_week", reason: "stalled")))
        #expect(events().contains(.assistantTurn(flow: "program_week", number: 2, isRetry: true)))
        #expect(events().last == .assistantClosed(flow: "program_week", stage: "error", turns: 2))
    }

    @Test func aClientOptionIsTappedButOnlyCompletedWhenThePageRunsIt() async {
        let (viewModel, events) = await chat()
        viewModel.onClientAction = { _ in viewModel.say("A session is still coming in.") } // the page refused

        viewModel.tap(whiteboard)
        viewModel.recordClose()

        #expect(events() == [
            .assistantOptionTapped(option: "whiteboard", flow: "whiteboard"),
            .assistantClosed(flow: "whiteboard", stage: "chatting", turns: 0),
        ])
    }

    @Test func failuresAreSortedByKind() {
        struct Offline: Error {}
        #expect(AssistantChatViewModel.failureReason(WorkoutGenerationError.server("No")) == "server")
        #expect(AssistantChatViewModel.failureReason(WorkoutGenerationError.stalled) == "stalled")
        #expect(AssistantChatViewModel.failureReason(Offline()) == "network")
    }
}
