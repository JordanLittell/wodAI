//
//  OnboardingViewModelTests.swift
//  wodAITests
//
//  Navigation never waits on the network, taps from a screen that's already
//  gone are ignored, and Finish waits for (and retries) every save.
//

import Foundation
import Testing
import WodAiAPI
@testable import wodAI

/// Records calls; each can be slowed down or made to fail.
private actor FakeOnboardingAPI: OnboardingAPI {
    var calls: [String] = []
    var gymIdsSeen: [Int?] = []
    var profileDelay: Duration = .zero
    var gymDelays: [Duration] = []
    var skillFailuresLeft = 0
    var provisioned = false
    /// Answers to planStatus in turn; the last one repeats.
    var planStatuses: [PlanStatus?] = [PlanStatus(state: .done)]
    var loadedContent = false

    func setProvisioned(_ value: Bool) { provisioned = value }
    func setPlanStatuses(_ statuses: [PlanStatus?]) { planStatuses = statuses }

    func setProfileDelay(_ d: Duration) { profileDelay = d }
    func setGymDelays(_ d: [Duration]) { gymDelays = d }
    func setSkillFailures(_ n: Int) { skillFailuresLeft = n }

    func loadContent() async throws -> OnboardingContent {
        loadedContent = true
        let rungs = [OnboardingRung(key: "hard", question: "Hard?"), OnboardingRung(key: "easy", question: "Easy?")]
        return OnboardingContent(
            ladders: [OnboardingLadder(id: "pulling", domain: "Gymnastics", name: "Pull-ups", rungs: rungs)],
            gymPresets: [OnboardingGymPreset(id: "home_gym", name: "Home", equipment: [OnboardingEquipment(id: 1, name: "Barbell")])],
            lifts: [OnboardingLift(id: 12, name: "Back Squat")]
        )
    }

    func updateProfile(_ input: UpdateUserInput) async throws {
        try await Task.sleep(for: profileDelay)
        calls.append("profile")
    }

    func saveGym(id: Int?, name: String, equipmentIds: [Int]) async throws -> Int {
        if !gymDelays.isEmpty { try await Task.sleep(for: gymDelays.removeFirst()) }
        gymIdsSeen.append(id)
        calls.append("gym")
        return 10
    }

    func setSkillLevel(ladder: String, level: String?) async throws {
        calls.append("skill:\(level ?? "none")")
        if skillFailuresLeft > 0 {
            skillFailuresLeft -= 1
            throw OnboardingError.server("offline")
        }
    }

    func setBenchmark(exerciseId: Int, weight: Double, reps: Int) async throws -> Int {
        calls.append("benchmark:\(exerciseId):\(Int(weight))x\(reps)")
        return 1
    }

    func deleteBenchmark(id: Int) async throws { calls.append("deleteBenchmark") }
    func complete(timezone: String) async throws { calls.append("complete:\(timezone)") }

    func planStatus() async throws -> PlanStatus? {
        planStatuses.count > 1 ? planStatuses.removeFirst() : planStatuses.first ?? nil
    }

    func startPlan(timezone: String) async throws -> PlanStatus {
        calls.append("startPlan")
        return PlanStatus(state: .running)
    }

    func isProvisioned() async throws -> Bool { provisioned }
}

@MainActor
struct OnboardingViewModelTests {
    private static let today = "2026-10-05"

    private func ready(_ api: FakeOnboardingAPI, onFinished: @escaping () -> Void = {}) async -> OnboardingViewModel {
        let vm = OnboardingViewModel(api: api, onFinished: onFinished, today: Self.today, timezone: "America/Denver", pollInterval: .milliseconds(5))
        await vm.load()
        return vm
    }

    /// Walks a fresh athlete to the last step.
    private func walkToAboutYou(_ vm: OnboardingViewModel) {
        vm.choose(.buildStrength)
        vm.choose(.twoToFive)
        vm.saveSchedule()
        vm.choose(vm.content.gymPresets[0])
        vm.saveEquipment()
        vm.skipLadder(at: .skill(ladder: 0, rung: 0))
        vm.saveLifts()
    }

    private func waitUntil(_ condition: () async -> Bool) async throws {
        for _ in 0..<300 where !(await condition()) {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test func choosingMovesOnWithoutWaitingForTheSave() async {
        let api = FakeOnboardingAPI()
        await api.setProfileDelay(.seconds(5))
        let vm = await ready(api)

        vm.choose(.buildStrength)
        #expect(vm.flow.current == .experience)
    }

    @Test func aSecondTapOnAScreenThatIsSlidingAwayIsIgnored() async {
        let vm = await ready(FakeOnboardingAPI())
        vm.choose(.buildStrength)

        // The double tap from the bug report: the second lands on the
        // experience screen after it has already moved on.
        vm.choose(.twoToFive)
        vm.choose(.fivePlus)
        #expect(vm.flow.current == .schedule)
        #expect(vm.experience == .twoToFive)

        vm.choose(.loseFat) // a stale goal tap
        #expect(vm.flow.current == .schedule)
        #expect(vm.goal == .buildStrength)
    }

    @Test func scheduleOnlyMovesOnFromContinue() async {
        let vm = await ready(FakeOnboardingAPI())
        vm.choose(.buildStrength)
        vm.choose(.twoToFive)

        vm.daysPerWeek = 5
        vm.sessionLength = 45
        #expect(vm.flow.current == .schedule)

        vm.saveSchedule()
        #expect(vm.flow.current == .gym)
    }

    @Test func anAnswerToAnEarlierQuestionIsIgnored() async {
        let vm = await ready(FakeOnboardingAPI())
        vm.choose(.buildStrength)
        vm.choose(.twoToFive)
        vm.saveSchedule()
        vm.choose(vm.content.gymPresets[0])
        vm.saveEquipment()

        let first = OnboardingStep.skill(ladder: 0, rung: 0)
        vm.answer(false, to: first)
        #expect(vm.flow.current == .skill(ladder: 0, rung: 1))
        vm.answer(true, to: first)
        #expect(vm.flow.current == .skill(ladder: 0, rung: 1))
    }

    @Test func savesRunInTheOrderTheyWereMade() async throws {
        let api = FakeOnboardingAPI()
        // The first gym save (a create) is slow; the second must still wait
        // for it and update the gym it created.
        await api.setGymDelays([.milliseconds(200), .zero])
        let vm = await ready(api)
        vm.choose(.buildStrength)
        vm.choose(.twoToFive)
        vm.saveSchedule()
        vm.choose(vm.content.gymPresets[0])
        vm.saveEquipment()
        vm.back()
        vm.toggleEquipment(1)
        vm.saveEquipment()

        try await waitUntil { await api.gymIdsSeen.count == 2 }
        #expect(await api.gymIdsSeen == [nil, 10])
    }

    @Test func finishRetriesFailedSavesThenCompletes() async throws {
        let api = FakeOnboardingAPI()
        await api.setSkillFailures(1)
        var finished = false
        let vm = await ready(api) { finished = true }
        vm.choose(.buildStrength)
        vm.choose(.twoToFive)
        vm.saveSchedule()
        vm.choose(vm.content.gymPresets[0])
        vm.saveEquipment()
        vm.answer(true, to: .skill(ladder: 0, rung: 0))
        vm.oneRepMaxes[12] = "225"
        vm.saveLifts()
        vm.finish()

        try await waitUntil { finished }
        #expect(finished)
        let calls = await api.calls
        #expect(calls.filter { $0 == "skill:hard" }.count == 2) // failed once, retried at Finish
        #expect(calls.contains("benchmark:12:225x1")) // lifts are always 1-rep maxes
        #expect(calls.last == "complete:America/Denver") // starts planning on the server
    }

    // MARK: - Planning their week

    @Test func waitsForTodaysSessionBeforeHandingOff() async throws {
        let api = FakeOnboardingAPI()
        await api.setPlanStatuses([
            PlanStatus(state: .running),
            PlanStatus(state: .running, plannedDates: ["2026-10-06"]),
            PlanStatus(state: .running, plannedDates: ["2026-10-06", Self.today]),
        ])
        var finished = false
        let vm = await ready(api) { finished = true }
        walkToAboutYou(vm)
        vm.finish()

        try await waitUntil { vm.phase == .planning }
        #expect(!finished)
        try await waitUntil { finished }
        #expect(finished)
        #expect(vm.planWait == .ready)
    }

    @Test func aFinishedRunWithoutTodayStillHandsOff() async throws {
        let api = FakeOnboardingAPI()
        await api.setPlanStatuses([PlanStatus(state: .done, plannedDates: ["2026-10-06"])])
        var finished = false
        let vm = await ready(api) { finished = true }
        walkToAboutYou(vm)
        vm.finish()

        try await waitUntil { finished }
        #expect(finished)
    }

    @Test func aFailedRunCanBeRetried() async throws {
        let api = FakeOnboardingAPI()
        await api.setPlanStatuses([PlanStatus(state: .failed, message: "No luck.")])
        var finished = false
        let vm = await ready(api) { finished = true }
        walkToAboutYou(vm)
        vm.finish()

        try await waitUntil { vm.planWait == .failed("No luck.") }
        #expect(vm.planWait == .failed("No luck."))
        #expect(!finished)

        await api.setPlanStatuses([PlanStatus(state: .running, plannedDates: [Self.today])])
        vm.retryPlan()
        try await waitUntil { finished }
        #expect(finished)
        #expect(await api.calls.contains("startPlan"))
    }

    @Test func anAthleteWhoLeftDuringPlanningResumesWaiting() async throws {
        let api = FakeOnboardingAPI()
        await api.setProvisioned(true)
        await api.setPlanStatuses([PlanStatus(state: .running), PlanStatus(state: .running, plannedDates: [Self.today])])
        var finished = false
        let vm = await ready(api) { finished = true }

        #expect(vm.phase == .planning)
        #expect(await api.loadedContent == false) // straight back to the wait, not step one
        try await waitUntil { finished }
        #expect(finished)
    }

    @Test func theWaitTurnsSlowAfterAWhile() {
        let running = PlanStatus(state: .running)
        #expect(PlanWait.from(running, today: Self.today, waited: 10) == .waiting(slow: false))
        #expect(PlanWait.from(running, today: Self.today, waited: PlanWait.slowAfter + 1) == .waiting(slow: true))
        #expect(PlanWait.from(nil, today: Self.today, waited: 10) == .waiting(slow: false))
        // Today being planned wins even if the run later failed.
        #expect(PlanWait.from(PlanStatus(state: .failed, plannedDates: [Self.today]), today: Self.today, waited: 0) == .ready)
    }
}

@MainActor
struct AssistantPlanningNoticeTests {
    @Test func showsWhilePlanningAndClearsWhenDone() async throws {
        var statuses: [PlanStatus?] = [PlanStatus(state: .running), PlanStatus(state: .done)]
        let vm = AssistantViewModel(week: AssistantWeek())
        vm.planPollInterval = .milliseconds(5)
        vm.planStatus = { statuses.count > 1 ? statuses.removeFirst() : statuses[0] }

        vm.watchPlanning()
        for _ in 0..<100 where vm.planningNotice != .planning { try await Task.sleep(for: .milliseconds(5)) }
        #expect(vm.planningNotice == .planning)
        for _ in 0..<100 where vm.planningNotice != nil { try await Task.sleep(for: .milliseconds(5)) }
        #expect(vm.planningNotice == nil)
    }

    @Test func saysNothingAboutAnOldFailedRun() async throws {
        let vm = AssistantViewModel(week: AssistantWeek())
        vm.planStatus = { PlanStatus(state: .failed, message: "Old news.") }
        vm.watchPlanning()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.planningNotice == nil)
    }
}
