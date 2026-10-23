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

    @Test func shiftingCrossesTheYear() {
        let cal = calendar("America/Los_Angeles")
        // Wednesday, Dec 30 2026; the next Sunday-first week starts Jan 3.
        let week = AssistantWeek(containing: date(2026, 12, 30, in: cal), calendar: cal)
        let next = week.shifted(by: 1)
        #expect(ymd(next.first, cal) == [2027, 1, 3])
        #expect(ymd(next.shifted(by: -2).first, cal) == [2026, 12, 20])
    }

    @Test func shiftingAcrossDaylightSavingKeepsWholeDays() {
        let cal = calendar("America/Los_Angeles")
        // Clocks go back on Sunday, Nov 1 2026.
        let week = AssistantWeek(containing: date(2026, 10, 28, in: cal), calendar: cal)
        let next = week.shifted(by: 1)
        #expect(next.days.map { ymd($0, cal)[2] } == [1, 2, 3, 4, 5, 6, 7])
        #expect(next.days.allSatisfy { $0 == cal.startOfDay(for: $0) })
        #expect(next.shifted(by: -1) == week)
    }

    @Test func aShiftedWeekKeepsToday() {
        let cal = calendar("America/Los_Angeles")
        let week = AssistantWeek(containing: date(2026, 10, 1, in: cal), calendar: cal)
        let previous = week.shifted(by: -1)
        #expect(previous.today == week.today)
        #expect(week.isCurrent)
        #expect(!previous.isCurrent)
        #expect(!previous.contains(previous.today))
        #expect(previous.week(containing: week.today) == week)
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
    private func session(_ name: String, on day: Date? = nil, strength: StrengthWorkout? = nil) -> AssistantSession {
        AssistantSession(
            name: name, description: "", stimulus: nil, coaching: nil, scheduledDate: day,
            blocks: strength.map { [AssistantBlock(id: 0, label: "A", letter: "A", kind: .strength($0))] } ?? []
        )
    }

    /// Midweek, so today has days on both sides whichever day the locale's
    /// week starts on.
    static let week = AssistantWeek(containing: ISO8601DateFormatter().date(from: "2026-10-07T12:00:00Z")!)

    /// A view model whose week fetches return `found(week)` and are recorded.
    private func viewModel(
        sessions: [Date: [AssistantSession]] = [:],
        found: @escaping (AssistantWeek) -> [AssistantSession] = { _ in [] }
    ) -> (AssistantViewModel, () -> [Date]) {
        let viewModel = AssistantViewModel(week: Self.week, sessions: sessions)
        var fetched: [Date] = []
        viewModel.weekSessions = { week in
            fetched.append(week.first)
            return found(week)
        }
        return (viewModel, { fetched })
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func dayNavigationCarriesOnIntoTheNextAndPreviousWeek() async {
        let (viewModel, fetched) = viewModel()
        let week = Self.week

        viewModel.select(week.last)
        viewModel.goForward()
        #expect(viewModel.selectedDay == week.shifted(by: 1).first)
        #expect(viewModel.week == week.shifted(by: 1))
        await waitUntil { viewModel.hasLoaded }
        #expect(fetched() == [week.shifted(by: 1).first])

        viewModel.goBack()
        viewModel.goBack()
        #expect(viewModel.selectedDay == week.days[week.days.count - 2])
        #expect(viewModel.week == week)
    }

    @Test func changingWeeksKeepsTheDayOfTheWeek() {
        let (viewModel, _) = viewModel()
        let week = Self.week
        let index = week.index(of: week.today)!

        viewModel.showWeek(offset: -1)
        #expect(viewModel.selectedDay == week.shifted(by: -1).days[index])
        viewModel.showWeek(offset: 3)
        #expect(viewModel.selectedDay == week.shifted(by: 2).days[index])
        #expect(viewModel.week.today == week.today)

        viewModel.showToday()
        #expect(viewModel.selectedDay == week.today)
        #expect(viewModel.week == week)
    }

    @Test func selectingADayInAnotherWeekMovesThere() {
        let (viewModel, _) = viewModel()
        let day = Self.week.shifted(by: -5).days[2]
        viewModel.select(day)
        #expect(viewModel.selectedDay == day)
        #expect(viewModel.week == Self.week.shifted(by: -5))
    }

    @Test func aWeeksSessionsLandOnTheirDays() async {
        let previous = Self.week.shifted(by: -1)
        let (viewModel, _) = viewModel { week in
            week == previous ? [self.session("Last Monday", on: week.days[1])] : []
        }

        viewModel.showWeek(offset: -1)
        #expect(viewModel.isLoading)
        #expect(!viewModel.hasLoaded)
        await waitUntil { viewModel.hasLoaded }

        #expect(!viewModel.isLoading)
        #expect(viewModel.hasSession(on: previous.days[1]))
        viewModel.select(previous.days[1])
        #expect(viewModel.daySessions.map(\.name) == ["Last Monday"])
    }

    @Test func loadingAWeekLeavesTheOthersAlone() async {
        let today = [Self.week.today: [session("Today")]]
        let (viewModel, _) = viewModel(sessions: today)

        viewModel.showWeek(offset: -1)
        await waitUntil { viewModel.hasLoaded }
        viewModel.showToday()

        #expect(viewModel.daySessions.map(\.name) == ["Today"])
    }

    @Test func revisitingAWeekShowsItAtOnceAndRefreshesQuietly() async {
        let (viewModel, fetched) = viewModel { week in [self.session("Old", on: week.days[0])] }

        viewModel.showWeek(offset: -1)
        await waitUntil { viewModel.hasLoaded }
        viewModel.showWeek(offset: 1)
        viewModel.showWeek(offset: -1)

        // Shown from what was loaded, with no spinner, while it refreshes.
        #expect(viewModel.hasLoaded)
        #expect(!viewModel.isLoading)
        #expect(viewModel.hasSession(on: Self.week.shifted(by: -1).days[0]))
        let previous = Self.week.shifted(by: -1).first
        await waitUntil { fetched().filter { $0 == previous }.count == 2 }
        #expect(fetched().filter { $0 == previous }.count == 2)
    }

    @Test func aFailedLoadIsReportedOnlyOnItsOwnWeek() async {
        struct Offline: Error {}
        let viewModel = AssistantViewModel(week: Self.week, sessions: [Self.week.today: [session("Today")]])
        viewModel.weekSessions = { _ in throw Offline() }

        viewModel.showWeek(offset: -1)
        await waitUntil { viewModel.errorMessage != nil }
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.hasLoaded)

        viewModel.showToday()
        #expect(viewModel.errorMessage == nil)
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
