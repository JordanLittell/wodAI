//
//  WhiteboardImportTests.swift
//  wodAITests
//
//  Coverage for importing a workout from a whiteboard: the on-device check
//  that decides when to take the photo, mapping the server's events, and
//  streaming the import into a day that already has a session.
//

import Testing
import Foundation
import WodAiAPI
@testable import wodAI

struct WhiteboardHeuristicTests {
    @Test func aTypicalBoardLooksLikeAWorkout() {
        #expect(WhiteboardHeuristic.looksLikeWorkout(lines: ["FRAN", "21-15-9", "Thrusters 95/65", "Pull-ups"]))
        #expect(WhiteboardHeuristic.looksLikeWorkout(lines: ["AMRAP 12", "12 Cal Row", "9 Burpees", "6 KB Swings 53/35"]))
        #expect(WhiteboardHeuristic.looksLikeWorkout(lines: ["Back Squat", "5x5 @ 75%", "Then 3 rounds", "400m run"]))
    }

    @Test func oneBlockOfTextIsSplitIntoLines() {
        #expect(WhiteboardHeuristic.looksLikeWorkout(lines: ["EMOM 10\n10 Wall Balls\n5 Burpees"]))
    }

    @Test func signageAndHoursDoNot() {
        #expect(!WhiteboardHeuristic.looksLikeWorkout(lines: ["EXIT", "Push door", "Fire extinguisher inside"]))
        #expect(!WhiteboardHeuristic.looksLikeWorkout(lines: ["Open 6am-9pm", "Mon-Fri", "Sat 8-12"]))
    }

    @Test func tooLittleTextDoesNot() {
        #expect(!WhiteboardHeuristic.looksLikeWorkout(lines: []))
        #expect(!WhiteboardHeuristic.looksLikeWorkout(lines: ["21-15-9 Thrusters"]))
        #expect(!WhiteboardHeuristic.looksLikeWorkout(lines: ["Thrusters", "Pull-ups", "21"]))
    }

    @Test func theGateWaitsForAnUnbrokenHold() {
        var gate = WhiteboardStabilityGate(holdDuration: 1)
        let start = Date(timeIntervalSince1970: 1_000)

        gate.update(passes: true, at: start)
        #expect(!gate.isSatisfied(at: start.addingTimeInterval(0.5)))
        #expect(gate.isSatisfied(at: start.addingTimeInterval(1)))

        // A failing read restarts the hold.
        gate.update(passes: false, at: start.addingTimeInterval(1.1))
        #expect(!gate.isSatisfied(at: start.addingTimeInterval(1.2)))
        gate.update(passes: true, at: start.addingTimeInterval(1.3))
        #expect(!gate.isSatisfied(at: start.addingTimeInterval(2.0)))
        #expect(gate.isSatisfied(at: start.addingTimeInterval(2.3)))
    }
}

struct WhiteboardEventMappingTests {
    @Test func aDraftHiitBlockDrawsAsAMetconCard() throws {
        let data = try WhiteboardImportSubscription.Data.WhiteboardImport(data: [
            "__typename": "GenerationDraftHiitBlock",
            "order": 1,
            "name": "Fran",
            "format": "For Time",
            "displayText": "21-15-9\nThrusters\nPull-ups",
            "stimulus": "Fast.",
        ])
        guard case let .hiitBlock(order, name, workout) = WorkoutGenerationStream.event(from: data) else {
            Issue.record("expected a HIIT block")
            return
        }
        #expect(order == 1)
        #expect(name == "Fran")
        #expect(workout.format == "For Time")
        #expect(workout.displayText == "21-15-9\nThrusters\nPull-ups")
    }

    @Test func theProgressStampsTheDayItWasGiven() {
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        var progress = GenerationProgress(scheduledDate: day)
        progress.apply(.session(name: "Tuesday", description: "", stimulus: ""))
        #expect(progress.session?.scheduledDate == day)

        // A restart (socket reconnect) keeps the day.
        progress.apply(.session(name: "Tuesday", description: "", stimulus: ""))
        #expect(progress.session?.scheduledDate == day)
    }
}

@MainActor
struct WhiteboardImportViewModelTests {
    private func session(_ id: String, name: String, completed: Bool = false) -> AssistantSession {
        var block = AssistantBlock(id: 0, label: "Metcon", letter: "A", kind: .hiit(hiit))
        block.hiitCompleted = completed
        return AssistantSession(
            id: id, name: name, description: "", stimulus: nil, coaching: nil, scheduledDate: nil, blocks: [block]
        )
    }

    private let hiit = HIITWorkoutItem(
        id: 7, format: "AMRAP 12", displayText: "12 Cal Row", stimulus: "Steady.",
        constraintType: "time", constraintMagnitude: 720, timeCap: 720, timingScheme: nil, tags: []
    )

    private let capture = WhiteboardCapture(jpeg: Data([0xFF, 0xD8]), recognizedText: " AMRAP 12 ")

    /// A view model whose whiteboard import is fed by the returned continuation.
    private func viewModel(
        sessions: [AssistantSession]
    ) -> (AssistantViewModel, AsyncThrowingStream<GenerationEvent, Error>.Continuation, () -> WhiteboardImportInput?) {
        let week = AssistantWeek()
        let viewModel = AssistantViewModel(week: week, sessions: sessions.isEmpty ? [:] : [week.today: sessions])
        let (stream, continuation) = AsyncThrowingStream<GenerationEvent, Error>.makeStream()
        var sent: WhiteboardImportInput?
        viewModel.whiteboardEvents = { input in
            sent = input
            return stream
        }
        return (viewModel, continuation, { sent })
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    // MARK: - Several sessions on one day

    @Test func withSeveralSessionsOnlyTheFirstUnfinishedOneStartsOpen() {
        let (viewModel, _, _) = viewModel(sessions: [
            session("a", name: "Done", completed: true),
            session("b", name: "Next"),
            session("c", name: "Later"),
        ])
        #expect(viewModel.daySessions.map { viewModel.isExpanded($0) } == [false, true, false])

        viewModel.toggleExpanded(viewModel.daySessions[0])
        viewModel.toggleExpanded(viewModel.daySessions[1])
        #expect(viewModel.daySessions.map { viewModel.isExpanded($0) } == [true, false, false])
    }

    @Test func aDaysOnlySessionStartsOpen() {
        let (viewModel, _, _) = viewModel(sessions: [session("a", name: "Only", completed: true)])
        #expect(viewModel.isExpanded(viewModel.daySessions[0]))
    }

    @Test func savingAResultTouchesOnlyItsSession() {
        let (viewModel, _, _) = viewModel(sessions: [session("a", name: "A"), session("b", name: "B")])
        viewModel.markHiitCompleted(sessionId: "b", blockId: 0)
        #expect(viewModel.session(id: "a")?.isCompleted == false)
        #expect(viewModel.session(id: "b")?.isCompleted == true)
    }

    // MARK: - Import

    @Test func anImportStreamsInBesideTheDaysSessionAndBecomesTheSavedOne() async {
        let (viewModel, continuation, sent) = viewModel(sessions: [session("programmed", name: "Programmed")])

        viewModel.importWhiteboard(capture)
        #expect(viewModel.isImporting)
        #expect(sent()?.recognizedText == .some("AMRAP 12"))
        #expect(sent()?.scheduledDate == viewModel.week.calendarDate(for: viewModel.selectedDay))

        // A placeholder appears at once, open, with the other session closed.
        let pending = viewModel.daySessions[1]
        #expect(pending.isPending)
        #expect(pending.source == .whiteboard)
        #expect(viewModel.focusedSessionId == pending.id)
        #expect(viewModel.daySessions.map { viewModel.isExpanded($0) } == [false, true])

        continuation.yield(.session(name: "Tuesday", description: "", stimulus: ""))
        continuation.yield(.hiitBlock(order: 0, name: "Fran", workout: hiit))
        await waitUntil { viewModel.daySessions.last?.blocks.count == 1 }
        #expect(viewModel.daySessions.last?.name == "Tuesday")
        #expect(viewModel.daySessions.last?.isPending == true)
        // Still streaming, so nothing can be opened yet.
        #expect(viewModel.openableBlocks(in: pending.id).isEmpty)

        continuation.yield(.complete(session("saved", name: "Tuesday")))
        continuation.finish()
        await waitUntil { !viewModel.isImporting }

        #expect(viewModel.daySessions.map(\.id) == ["programmed", "saved"])
        let saved = viewModel.daySessions[1]
        #expect(!saved.isPending)
        #expect(saved.source == .whiteboard)
        #expect(viewModel.isExpanded(saved))
        #expect(viewModel.focusedSessionId == "saved")
        #expect(viewModel.openableBlocks(in: "saved").count == 1)
        #expect(viewModel.importError == nil)
    }

    @Test func aFailedImportLeavesTheDayAsItWas() async {
        let (viewModel, continuation, _) = viewModel(sessions: [session("programmed", name: "Programmed")])

        viewModel.importWhiteboard(capture)
        continuation.yield(.session(name: "Tuesday", description: "", stimulus: ""))
        continuation.finish(throwing: WorkoutGenerationError.server("That doesn't look like a workout."))
        await waitUntil { !viewModel.isImporting }

        #expect(viewModel.daySessions.map(\.id) == ["programmed"])
        #expect(viewModel.importError == "That doesn't look like a workout.")
        #expect(viewModel.focusedSessionId == nil)
    }

    @Test func anImportOnAnEmptyDayLeavesItEmptyWhenCancelled() async {
        let (viewModel, _, _) = viewModel(sessions: [])

        viewModel.importWhiteboard(capture)
        #expect(viewModel.hasSession(on: viewModel.selectedDay))
        viewModel.cancelImport()
        await waitUntil { !viewModel.isImporting }

        #expect(!viewModel.hasSession(on: viewModel.selectedDay))
        // Cancelling isn't an error to show.
        #expect(viewModel.importError == nil)
    }
}
