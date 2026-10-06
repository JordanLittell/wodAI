//
//  AssistantWeekTests.swift
//  wodAITests
//

import Testing
import Foundation
@testable import wodAI

struct AssistantWeekTests {
    private func calendar(_ zone: String, firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func ymd(_ date: Date, _ calendar: Calendar) -> [Int] {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return [parts.year!, parts.month!, parts.day!]
    }

    @Test(arguments: ["America/Los_Angeles", "Asia/Tokyo", "UTC"])
    func serverDateIsTheSameCalendarDayEverywhere(zone: String) {
        let cal = calendar(zone)
        let week = AssistantWeek(containing: date(2026, 10, 1, in: cal), calendar: cal)
        let day = week.localDay(fromServer: "2026-10-01T00:00:00.000Z")
        #expect(day.map { ymd($0, cal) } == [2026, 10, 1])
        #expect(day == cal.startOfDay(for: date(2026, 10, 1, in: cal)))
    }

    @Test func serverArgumentIsNoonUTCOfTheLocalDay() {
        let cal = calendar("America/Los_Angeles")
        // 11 pm on Oct 1 in LA is already Oct 2 in UTC; the argument must
        // still say Oct 1.
        let week = AssistantWeek(containing: date(2026, 10, 1, in: cal), calendar: cal)
        #expect(week.serverArgument(for: date(2026, 10, 1, hour: 23, in: cal)) == "2026-10-01T12:00:00.000Z")
    }

    @Test func weekStartsOnTheCalendarsFirstWeekday() {
        let sundayFirst = calendar("America/Los_Angeles", firstWeekday: 1)
        let mondayFirst = calendar("America/Los_Angeles", firstWeekday: 2)
        // Thursday, Oct 1 2026.
        let sunWeek = AssistantWeek(containing: date(2026, 10, 1, in: sundayFirst), calendar: sundayFirst)
        let monWeek = AssistantWeek(containing: date(2026, 10, 1, in: mondayFirst), calendar: mondayFirst)

        #expect(sunWeek.days.count == 7)
        #expect(ymd(sunWeek.first, sundayFirst) == [2026, 9, 27])
        #expect(ymd(sunWeek.last, sundayFirst) == [2026, 10, 3])
        #expect(ymd(monWeek.first, mondayFirst) == [2026, 9, 28])
        #expect(ymd(monWeek.last, mondayFirst) == [2026, 10, 4])
    }

    @Test func navigationStopsAtTheWeekEdges() {
        let cal = calendar("America/Los_Angeles")
        let week = AssistantWeek(containing: date(2026, 10, 1, in: cal), calendar: cal)
        #expect(week.day(after: week.last) == nil)
        #expect(week.day(before: week.first) == nil)
        #expect(week.day(after: week.first) == week.days[1])
        #expect(!week.contains(date(2026, 10, 4, in: cal)))
    }

    @Test func todayIsInTheWeek() {
        let cal = calendar("America/Los_Angeles")
        let week = AssistantWeek(containing: date(2026, 10, 1, hour: 18, in: cal), calendar: cal)
        #expect(week.today == cal.startOfDay(for: date(2026, 10, 1, in: cal)))
        #expect(week.days.contains(week.today))
    }
}

@MainActor
struct AssistantViewModelWeekTests {
    private func session(_ name: String, strength: StrengthWorkout? = nil) -> AssistantSession {
        AssistantSession(
            name: name, description: "", stimulus: nil, coaching: nil, scheduledDate: nil,
            blocks: strength.map { [AssistantBlock(id: 0, label: "A", letter: "A", kind: .strength($0))] } ?? []
        )
    }

    @Test func forwardAndBackAreClampedToTheWeek() {
        let viewModel = AssistantViewModel(week: AssistantWeek())
        let week = viewModel.week

        while viewModel.goForward() {}
        #expect(viewModel.selectedDay == week.last)
        #expect(!viewModel.canGoForward)
        #expect(!viewModel.goForward())

        while viewModel.goBack() {}
        #expect(viewModel.selectedDay == week.first)
        #expect(!viewModel.canGoBack)
    }

    @Test func eachDayShowsItsOwnSession() {
        let week = AssistantWeek()
        let viewModel = AssistantViewModel(week: week, sessions: [week.first: [session("Day one")]])

        viewModel.select(week.first)
        #expect(viewModel.daySessions.map(\.name) == ["Day one"])
        viewModel.goForward()
        #expect(viewModel.daySessions.isEmpty)
        #expect(viewModel.hasSession(on: week.first))
    }

    @Test func onlyAFullyLoggedStrengthBlockIsCompleted() {
        let squat = ExerciseName(name: "Back Squat")
        let done = StrengthComponent(order: 0, reps: 5, weight: 225, rpe: nil, exercise: squat,
                                     completed: CompletedSet(weightUsed: 225, reps: 5))
        let open = StrengthComponent(order: 1, reps: 5, weight: 225, rpe: nil, exercise: squat)
        func block(_ components: [StrengthComponent]) -> AssistantBlock {
            AssistantBlock(id: 0, label: "A", letter: "A", kind: .strength(
                StrengthWorkout(id: 0, name: "Squat", instructions: "", components: components)
            ))
        }

        #expect(block([done, done]).isCompleted)
        #expect(!block([done, open]).isCompleted)
        #expect(!AssistantBlock(id: 1, label: "B", letter: "B", kind: .other).isCompleted)
    }

    @Test func loggedSetsSurviveSwipingAwayAndBack() {
        let week = AssistantWeek()
        let squat = StrengthComponent(order: 0, reps: 5, weight: 225, rpe: nil, exercise: ExerciseName(name: "Back Squat"), id: 7)
        let block = StrengthWorkout(id: 0, name: "Squat", instructions: "", components: [squat], serverId: 3)
        let day = session("Day one", strength: block)
        let viewModel = AssistantViewModel(week: week, sessions: [week.first: [day]])
        viewModel.select(week.first)

        var logged = block
        logged.components[0].completed = CompletedSet(weightUsed: 230, reps: 5)
        viewModel.updateStrength(logged, sessionId: day.id)
        viewModel.goForward()
        viewModel.goBack()

        #expect(viewModel.strengthWorkout(sessionId: day.id, id: 0)?.components[0].completed == CompletedSet(weightUsed: 230, reps: 5))
    }
}
