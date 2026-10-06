//
//  SessionManagementTests.swift
//  wodAITests
//
//  Coverage for deleting a session (swipe, confirm, optimistic removal) and
//  for "Create with AI" streaming a session onto the selected day.
//

import Testing
import Foundation
@testable import wodAI

@MainActor
struct SessionManagementTests {
    private let hiit = HIITWorkoutItem(
        id: 7, format: "AMRAP 12", displayText: "12 Cal Row", stimulus: "Steady.",
        constraintType: "time", constraintMagnitude: 720, timeCap: 720, timingScheme: nil, tags: []
    )

    private func session(_ id: String, completedHiit: Bool = false, loggedSet: Bool = false) -> AssistantSession {
        var metcon = AssistantBlock(id: 1, label: "Metcon", letter: "B", kind: .hiit(hiit))
        metcon.hiitCompleted = completedHiit
        let set = StrengthComponent(
            order: 0, reps: 5, weight: 225, rpe: nil, exercise: ExerciseName(name: "Back Squat"),
            completed: loggedSet ? CompletedSet(weightUsed: 225, reps: 5) : nil
        )
        let squat = AssistantBlock(id: 0, label: "Squat", letter: "A", kind: .strength(
            StrengthWorkout(id: 0, name: "Squat", instructions: "", components: [set])
        ))
        return AssistantSession(
            id: id, name: id, description: "", stimulus: nil, coaching: nil, scheduledDate: nil, blocks: [squat, metcon]
        )
    }

    private func viewModel(_ sessions: [AssistantSession]) -> AssistantViewModel {
        let week = AssistantWeek()
        return AssistantViewModel(week: week, sessions: sessions.isEmpty ? [:] : [week.today: sessions])
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    // MARK: - Delete

    @Test func deletingRemovesTheSessionAtOnceAndTellsTheServer() async {
        let viewModel = viewModel([session("a"), session("b")])
        var deleted: [String] = []
        viewModel.deleteWorkout = { deleted.append($0) }

        viewModel.deleteSession(id: "a")
        #expect(viewModel.daySessions.map(\.id) == ["b"])
        await waitUntil { !deleted.isEmpty }
        #expect(deleted == ["a"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func deletingADaysLastSessionClearsTheDay() {
        let viewModel = viewModel([session("a")])
        viewModel.deleteWorkout = { _ in }

        viewModel.deleteSession(id: "a")
        #expect(!viewModel.hasSession(on: viewModel.selectedDay))
    }

    @Test func aRefusedDeleteBringsTheSessionBackWhereItWas() async {
        let viewModel = viewModel([session("a"), session("b"), session("c")])
        viewModel.deleteWorkout = { _ in throw WorkoutGenerationError.server("nope") }

        viewModel.deleteSession(id: "b")
        #expect(viewModel.daySessions.map(\.id) == ["a", "c"])
        await waitUntil { viewModel.daySessions.count == 3 }
        #expect(viewModel.daySessions.map(\.id) == ["a", "b", "c"])
        #expect(viewModel.errorMessage == "Couldn't delete that session. Please try again.")
    }

    @Test func onlyOneSessionShowsDeleteAndChangingDaysHidesIt() {
        let viewModel = viewModel([session("a"), session("b")])
        viewModel.reveal("a")
        viewModel.reveal("b")
        #expect(viewModel.revealedSessionId == "b")

        viewModel.goForward() || viewModel.goBack()
        #expect(viewModel.revealedSessionId == nil)
    }

    @Test func theConfirmationWarnsOnlyWhenWorkIsLogged() {
        let warning = "Sets you logged in it will be deleted too. Results you saved for its metcons stay in your history."
        #expect(SessionDeletion.message(for: session("a")) == "This can't be undone.")
        #expect(SessionDeletion.message(for: session("a", loggedSet: true)) == warning)
        #expect(SessionDeletion.message(for: session("a", completedHiit: true)) == warning)
    }

    @Test func theDaySwipeWaitsOutASectionSwipe() {
        let now = Date(timeIntervalSince1970: 1_000)
        var guardState = DaySwipeGuard()
        #expect(guardState.allowsDaySwipe(at: now))

        guardState.lastSectionSwipeAt = now
        #expect(!guardState.allowsDaySwipe(at: now.addingTimeInterval(0.1)))
        #expect(guardState.allowsDaySwipe(at: now.addingTimeInterval(DaySwipeGuard.quietPeriod + 0.01)))
    }

    // MARK: - Create with AI

    @Test func createWithAIStreamsAnAthletesSessionOntoTheSelectedDay() async {
        let viewModel = viewModel([session("programmed")])
        let (stream, continuation) = AsyncThrowingStream<GenerationEvent, Error>.makeStream()
        var sent: (request: String, date: String)?
        viewModel.createEvents = { request, date in
            sent = (request, date)
            return stream
        }

        viewModel.createSession(request: "  bodyweight in my room  ")
        #expect(sent?.request == "bodyweight in my room")
        #expect(sent?.date == viewModel.week.calendarDate(for: viewModel.selectedDay))
        let pending = viewModel.daySessions[1]
        #expect(pending.name == "Creating your session…")
        #expect(pending.source == .created)
        #expect(pending.isPending)
        // A session still streaming in can't show Delete.
        viewModel.reveal(pending.id)
        #expect(viewModel.revealedSessionId == nil)

        continuation.yield(.complete(session("saved")))
        continuation.finish()
        await waitUntil { !viewModel.isAddingSession }

        #expect(viewModel.daySessions.map(\.id) == ["programmed", "saved"])
        #expect(viewModel.daySessions[1].source == .created)
    }

    @Test func aFailedCreateKeepsTheRequestForTryAgain() async {
        let viewModel = viewModel([])
        let (stream, continuation) = AsyncThrowingStream<GenerationEvent, Error>.makeStream()
        viewModel.createEvents = { _, _ in stream }

        viewModel.createSession(request: "upper body pump")
        continuation.finish(throwing: WorkoutGenerationError.server("Unable to generate workout at this time."))
        await waitUntil { !viewModel.isAddingSession }

        #expect(viewModel.addError == "Unable to generate workout at this time.")
        #expect(viewModel.lastFailedAdd == .created(request: "upper body pump"))
        viewModel.dismissAddError()
        #expect(viewModel.lastFailedAdd == nil)
    }

    @Test func aBlankRequestDoesNothing() {
        let viewModel = viewModel([])
        var called = false
        viewModel.createEvents = { _, _ in
            called = true
            return AsyncThrowingStream { $0.finish() }
        }
        viewModel.createSession(request: "   ")
        #expect(!called)
        #expect(!viewModel.isAddingSession)
    }

    @Test func draftMetconsFromARequestDrawAsCards() throws {
        let data = try WorkoutGenerationSubscription.Data.WorkoutGeneration(data: [
            "__typename": "GenerationDraftHiitBlock",
            "order": 0,
            "name": "Wake-Up Ladder",
            "format": "AMRAP 12",
            "displayText": "AMRAP 12\n10 Air Squats",
            "stimulus": "Steady.",
        ])
        guard case let .hiitBlock(order, name, workout) = WorkoutGenerationStream.event(from: data) else {
            Issue.record("expected a HIIT block")
            return
        }
        #expect(order == 0)
        #expect(name == "Wake-Up Ladder")
        #expect(workout.displayText == "AMRAP 12\n10 Air Squats")
    }
}
