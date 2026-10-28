//
//  TrainingMemoryTests.swift
//  wodAITests
//
//  Your training: where a focus block stands, and the view model's edits
//  and removals against a fake API.
//

import Foundation
import Testing
@testable import wodAI

struct TrainingMemoryItemTests {
    private let snatch = TrainingMemoryItem(id: "f", kind: .focus, text: "Snatch", startsOn: "2026-10-19", endsOn: "2026-11-16")

    private func day(_ value: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let parts = value.split(separator: "-").map { Int($0)! }
        // Mid-afternoon local time: the athlete's calendar day, whatever the zone.
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 15))!
    }

    @Test func countsTheBlockInWholeWeeks() {
        #expect(snatch.totalWeeks == 4)
        #expect(TrainingMemoryItem(id: "h", kind: .habit, text: "Warmup").totalWeeks == nil)
    }

    @Test func numbersTheWeeksFromTheFirstDay() {
        #expect(snatch.stage(on: day("2026-10-19")) == .week(1, of: 4))
        #expect(snatch.stage(on: day("2026-10-25")) == .week(1, of: 4))
        #expect(snatch.stage(on: day("2026-10-28")) == .week(2, of: 4))
        #expect(snatch.stageLine(on: day("2026-10-28")) == "Week 2 of 4")
    }

    @Test func theLastWeekIsTheTestWeek() {
        #expect(snatch.stage(on: day("2026-11-09")) == .testWeek(of: 4))
        #expect(snatch.stageLine(on: day("2026-11-15")) == "Week 4 of 4 · de-load and test")
    }

    @Test func aOneWeekBlockHasNoTestWeek() {
        let short = TrainingMemoryItem(id: "f", kind: .focus, text: "Squat", startsOn: "2026-10-26", endsOn: "2026-11-02")
        #expect(short.stage(on: day("2026-10-28")) == .week(1, of: 1))
    }

    @Test func isFinishedFromItsEndDay() {
        #expect(snatch.stage(on: day("2026-11-16")) == .finished)
        #expect(snatch.stageLine(on: day("2026-11-20"))?.hasPrefix("Block finished") == true)
    }

    @Test func aHabitHasNoStage() {
        #expect(TrainingMemoryItem(id: "h", kind: .habit, text: "Warmup").stageLine(on: day("2026-10-28")) == nil)
    }
}

struct TrainingMemoryListTests {
    @Test func replacesAndRemovesByID() {
        var habit = TrainingMemory.sample.habits[0]
        habit.text = "Mobility every session"
        let edited = TrainingMemory.sample.replacing(habit)
        #expect(edited.habits.map(\.text) == ["Mobility every session"])
        #expect(edited.focus == TrainingMemory.sample.focus)

        let removed = TrainingMemory.sample.removing(id: "f").removing(id: "a")
        #expect(removed.focus == nil && removed.avoid.isEmpty && removed.habits.count == 1)
        #expect(removed.removing(id: "h").isEmpty)
    }
}

@MainActor
struct TrainingMemoryViewModelTests {
    /// Records calls; `fail` makes every call throw the server's message.
    final class FakeAPI {
        var memory = TrainingMemory.sample
        var updates: [(id: String, text: String?, weeks: Int?)] = []
        var removals: [String] = []
        var fail: String?
        var alreadyGone = false

        var api: TrainingMemoryAPI {
            TrainingMemoryAPI(
                load: { [unowned self] in
                    if let fail { throw TrainingMemoryAPI.APIError.server(fail) }
                    return memory
                },
                update: { [unowned self] id, text, weeks in
                    if let fail { throw TrainingMemoryAPI.APIError.server(fail) }
                    updates.append((id, text, weeks))
                    var item = memory.item(id: id)!
                    if let text { item.text = text }
                    if let weeks { item.endsOn = "end+\(weeks)w" }
                    return item
                },
                remove: { [unowned self] id in
                    if let fail { throw TrainingMemoryAPI.APIError.server(fail) }
                    removals.append(id)
                    return !alreadyGone
                }
            )
        }
    }

    private func loaded(_ fake: FakeAPI, events: @escaping (AnalyticsEvent) -> Void = { _ in }) async -> TrainingMemoryViewModel {
        let viewModel = TrainingMemoryViewModel(api: fake.api, track: events)
        await viewModel.load()
        return viewModel
    }

    @Test func loadsWhatTheCoachKeepsTo() async {
        let viewModel = await loaded(FakeAPI())
        #expect(viewModel.hasLoaded)
        #expect(viewModel.memory == .sample)
        #expect(viewModel.loadError == nil)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let fake = FakeAPI()
        fake.fail = "Server down"
        let viewModel = await loaded(fake)
        #expect(!viewModel.hasLoaded)
        #expect(viewModel.loadError == "Server down")
    }

    @Test func aFailedReloadKeepsWhatIsShown() async {
        let fake = FakeAPI()
        let viewModel = await loaded(fake)
        fake.fail = "Server down"
        await viewModel.load()
        #expect(viewModel.memory == .sample)
        #expect(viewModel.loadError == nil)
    }

    @Test func sendsOnlyTheNewWording() async {
        let fake = FakeAPI()
        var events: [AnalyticsEvent] = []
        let viewModel = await loaded(fake) { events.append($0) }
        let habit = viewModel.memory.habits[0]
        #expect(await viewModel.save(habit, text: "  Mobility every session ", weeks: nil))
        #expect(fake.updates.map(\.text) == ["Mobility every session"])
        #expect(fake.updates.map(\.weeks) == [nil])
        #expect(viewModel.memory.habits[0].text == "Mobility every session")
        #expect(events == [.memoryEdited(kind: "habit", changedLength: false)])
    }

    @Test func sendsANewBlockLengthForAFocus() async {
        let fake = FakeAPI()
        var events: [AnalyticsEvent] = []
        let viewModel = await loaded(fake) { events.append($0) }
        let focus = viewModel.memory.focus!
        #expect(await viewModel.save(focus, text: focus.text, weeks: 6))
        #expect(fake.updates.count == 1 && fake.updates[0].text == nil && fake.updates[0].weeks == 6)
        #expect(viewModel.memory.focus?.endsOn == "end+6w")
        #expect(events == [.memoryEdited(kind: "focus", changedLength: true)])
    }

    @Test func savingNothingNewSendsNothing() async {
        let fake = FakeAPI()
        let viewModel = await loaded(fake)
        let focus = viewModel.memory.focus!
        #expect(await viewModel.save(focus, text: "Snatch", weeks: 4))
        #expect(fake.updates.isEmpty)
    }

    @Test func refusesEmptyOrTooLongText() async {
        let fake = FakeAPI()
        let viewModel = await loaded(fake)
        let habit = viewModel.memory.habits[0]
        #expect(await viewModel.save(habit, text: "   ", weeks: nil) == false)
        #expect(viewModel.actionError != nil)
        viewModel.actionError = nil
        #expect(await viewModel.save(habit, text: String(repeating: "a", count: 121), weeks: nil) == false)
        #expect(viewModel.actionError != nil)
        #expect(fake.updates.isEmpty)
    }

    @Test func aFailedSaveKeepsTheItemAndSaysWhy() async {
        let fake = FakeAPI()
        let viewModel = await loaded(fake)
        fake.fail = "That item is no longer on Your training"
        let habit = viewModel.memory.habits[0]
        #expect(await viewModel.save(habit, text: "New", weeks: nil) == false)
        #expect(viewModel.memory == .sample)
        #expect(viewModel.actionError == "That item is no longer on Your training")
        #expect(viewModel.busyId == nil)
    }

    @Test func removesAnItem() async {
        let fake = FakeAPI()
        var events: [AnalyticsEvent] = []
        let viewModel = await loaded(fake) { events.append($0) }
        #expect(await viewModel.remove(viewModel.memory.avoid[0]))
        #expect(fake.removals == ["a"])
        #expect(viewModel.memory.avoid.isEmpty)
        #expect(events == [.memoryRemoved(kind: "avoid")])
    }

    @Test func anItemAlreadyGoneLeavesTheListWithoutAnEvent() async {
        let fake = FakeAPI()
        fake.alreadyGone = true
        var events: [AnalyticsEvent] = []
        let viewModel = await loaded(fake) { events.append($0) }
        #expect(await viewModel.remove(viewModel.memory.focus!))
        #expect(viewModel.memory.focus == nil)
        #expect(events.isEmpty)
    }

    @Test func aFailedRemovalKeepsTheItem() async {
        let fake = FakeAPI()
        let viewModel = await loaded(fake)
        fake.fail = "Offline"
        #expect(await viewModel.remove(viewModel.memory.focus!) == false)
        #expect(viewModel.memory.focus != nil)
        #expect(viewModel.actionError == "Offline")
    }

    @Test func eventNamesAndProperties() {
        #expect(AnalyticsEvent.memoryEdited(kind: "focus", changedLength: true).name == "memory_edited")
        #expect(AnalyticsEvent.memoryEdited(kind: "focus", changedLength: true).properties == ["kind": "focus", "changed_length": true])
        #expect(AnalyticsEvent.memoryRemoved(kind: "habit").name == "memory_removed")
        #expect(AnalyticsEvent.memoryRemoved(kind: "habit").properties == ["kind": "habit"])
    }
}
