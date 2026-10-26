//
//  AssistantActionsTests.swift
//  wodAITests
//
//  Program My Week's day picker and the actions the coach hands to the
//  Workout page: writing today's session (B5) and re-planning picked days (C4).
//

import Foundation
import Testing
@testable import wodAI

struct DayPickerTests {
    @Test func aPickDaysSuggestionCarriesItsDates() {
        let payload = #"{"dates":["2026-10-23","2026-10-24"]}"#
        let action = ChatSuggestion.Action(serverValue: "PICK_DAYS", payload: payload)
        #expect(action == .pickDays(["2026-10-23", "2026-10-24"]))
        #expect(ChatSuggestion(id: "pick-days", label: "Pick days", action: action).pickableDates == ["2026-10-23", "2026-10-24"])
    }

    @Test func aPickerWithNothingToPickIsHidden() {
        for payload in [nil, "", "not json", #"{"dates":[]}"#] as [String?] {
            let suggestion = ChatSuggestion(id: "p", label: "Pick days", action: .init(serverValue: "PICK_DAYS", payload: payload))
            #expect(!suggestion.isSupported)
        }
    }

    @Test func pickedDaysGoBackReadableAndExact() {
        let message = ChatTranscript.pickedDaysMessage(["2026-10-28", "2026-10-26"])
        #expect(message.hasPrefix("Plan these days: "))
        #expect(message.hasSuffix("(2026-10-26, 2026-10-28)"))
        // Readable days come first, in date order.
        #expect(message.contains(ChatTranscript.dayLabel("2026-10-26") + ", " + ChatTranscript.dayLabel("2026-10-28")))
        #expect(ChatTranscript.dayOfMonth("2026-10-26") == "26")
    }

    @MainActor @Test func pickingDaysSendsThemAsTheAthletesReply() async {
        let picker = ChatSuggestion(id: "pick-days", label: "Pick days", action: .pickDays(["2026-10-26", "2026-10-27"]))
        var requests: [AssistantTurnRequest] = []
        let viewModel = AssistantChatViewModel(
            loadGreeting: { ChatGreeting(text: "Which days?", suggestions: [picker]) },
            runTurn: { request in
                requests.append(request)
                return AsyncThrowingStream { $0.finish() }
            },
            defaults: UserDefaults(suiteName: "AssistantActionsTests-\(UUID().uuidString)")!
        )
        await viewModel.load()

        viewModel.tap(picker) // the picker answers through pickDays, not a tap
        #expect(requests.isEmpty)

        viewModel.pickDays(["2026-10-27"])
        #expect(requests.count == 1)
        #expect(requests[0].messages.last?.text == ChatTranscript.pickedDaysMessage(["2026-10-27"]))
        viewModel.pickDays(["2026-10-26"]) // answered already
        #expect(requests.count == 1)
    }
}

struct ActionMappingTests {
    @Test func replaceWorkoutIdsKeepsNoneApartFromTheDefault() {
        // nil: the server replaces the default sessions; []: none.
        #expect(AssistantTurnAction(kind: .planWeek, dates: ["2026-10-26"]).replaceWorkoutIds == nil)
        #expect(AssistantTurnAction(kind: .planWeek, dates: ["2026-10-26"], replaceWorkoutIds: []).replaceWorkoutIds == [])
    }
}

@MainActor
struct WorkoutPageActionTests {
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func aWorkoutTheCoachWritesGoesOnToday() {
        let week = AssistantWeek()
        let viewModel = AssistantViewModel(week: week, sessions: [:])
        viewModel.showWeek(offset: 1)
        var sent: (request: String, date: String)?
        viewModel.createEvents = { request, date in
            sent = (request, date)
            return AsyncThrowingStream { _ in }
        }

        viewModel.createSessionToday(request: "20 min EMOM, dumbbells")

        #expect(viewModel.selectedDay == week.today)
        #expect(sent?.request == "20 min EMOM, dumbbells")
        #expect(sent?.date == week.calendarDate(for: week.today))
    }

    @Test func aReplanSendsThePickAndOnlyPickedEmptyDaysShowAsBuilding() async {
        let week = AssistantWeek()
        let viewModel = AssistantViewModel(week: week, sessions: [:])
        var sent: (dates: [String], request: String?, replace: [String]?)?
        viewModel.replanWeek = { dates, request, replace in sent = (dates, request, replace) }
        viewModel.planStatus = { PlanStatus(state: .running) }
        viewModel.planPollInterval = .seconds(60)
        let today = week.calendarDate(for: week.today)

        viewModel.replan(dates: [today], request: "Upper body", replaceWorkoutIds: nil)
        await waitUntil { sent != nil }

        #expect(sent?.dates == [today])
        #expect(sent?.request == "Upper body")
        #expect(sent?.replace == nil)
        #expect(viewModel.planningNotice == .planning)
        #expect(viewModel.isGenerating(week.today))
        if let other = week.days.first(where: { $0 > week.today }) {
            #expect(!viewModel.isGenerating(other))
        }
    }

    @Test func aReplanTheServerRefusesSaysSo() async {
        struct Refused: Error {}
        let week = AssistantWeek()
        let viewModel = AssistantViewModel(week: week, sessions: [:])
        viewModel.replanWeek = { _, _, _ in throw Refused() }

        viewModel.replan(dates: [week.calendarDate(for: week.today)], request: nil, replaceWorkoutIds: [])
        await waitUntil { viewModel.planningNotice != .planning }

        guard case .failed = viewModel.planningNotice else {
            Issue.record("expected a failure notice, got \(String(describing: viewModel.planningNotice))")
            return
        }
    }
}
