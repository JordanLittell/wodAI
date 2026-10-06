//
//  OnboardingViewModel.swift
//  wodAI
//
//  Drives onboarding: holds each step's answers and hands the step order to
//  OnboardingFlow.
//
//  Moving on never waits for the network. Each answer is saved in the
//  background, one save at a time in the order they were made, so a slow save
//  can't land after a newer one; Finish waits for every save (retrying any
//  that failed) before marking the athlete as onboarded. That also starts
//  planning their first week on the server; the last screen waits, polling,
//  until today's session is saved, then hands off to the app.
//
//  Every action names the step it belongs to and is ignored unless that step
//  is on screen, so a tap that lands on a screen as it slides away can't
//  answer it twice or skip the next one.
//

import Foundation
import SwiftUI
import WodAiAPI

/// How long the athlete has trained. Also sets the coarse fitness level the
/// rest of the app still reads; the skill questions refine it.
enum OnboardingExperience: CaseIterable {
    case new, underTwo, twoToFive, fivePlus

    var title: String {
        switch self {
        case .new: return "Just starting out"
        case .underTwo: return "Less than 2 years"
        case .twoToFive: return "2 to 5 years"
        case .fivePlus: return "More than 5 years"
        }
    }

    var icon: String {
        switch self {
        case .new: return "leaf"
        case .underTwo: return "chart.line.uptrend.xyaxis"
        case .twoToFive: return "figure.strengthtraining.traditional"
        case .fivePlus: return "medal"
        }
    }

    var trainingYears: Int {
        switch self {
        case .new: return 0
        case .underTwo: return 1
        case .twoToFive: return 3
        case .fivePlus: return 6
        }
    }

    var fitnessLevel: WodAiAPI.FitnessLevel {
        switch self {
        case .new, .underTwo: return .beginner
        case .twoToFive: return .intermediate
        case .fivePlus: return .advanced
        }
    }
}

struct OnboardingGoal: Identifiable {
    let goal: TrainingGoal
    let title: String
    let subtitle: String
    let icon: String
    var id: TrainingGoal { goal }

    static let all: [OnboardingGoal] = [
        .init(goal: .generalFitness, title: "General fitness", subtitle: "Feel good and move well", icon: "figure.mixed.cardio"),
        .init(goal: .buildStrength, title: "Get stronger", subtitle: "Lift heavier", icon: "dumbbell"),
        .init(goal: .buildEngine, title: "Build my engine", subtitle: "Go longer, recover faster", icon: "heart"),
        .init(goal: .loseFat, title: "Lose fat", subtitle: "Train hard, burn more", icon: "flame"),
        .init(goal: .skillDevelopment, title: "Learn new skills", subtitle: "Muscle-ups, handstands, lifts", icon: "figure.gymnastics"),
        .init(goal: .compete, title: "Compete", subtitle: "Get ready for competition", icon: "trophy"),
        .init(goal: .returnFromBreak, title: "Get back into it", subtitle: "Returning after time off", icon: "arrow.counterclockwise"),
    ]
}

/// Parses a typed one-rep max in lbs; nil when empty or not a sensible weight.
func parseOneRepMax(_ text: String) -> Double? {
    guard let value = Double(text.replacingOccurrences(of: ",", with: ".")), value > 0, value < 2000 else { return nil }
    return value
}

enum OnboardingSex: CaseIterable {
    case male, female, other, preferNotToSay

    var title: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }

    var api: WodAiAPI.Gender {
        switch self {
        case .male: return .male
        case .female: return .female
        case .other: return .other
        case .preferNotToSay: return .preferNotToSay
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Phase { case loading, failed, ready, planning }

    static let daysPerWeekOptions = Array(1...7)
    static let sessionLengthOptions = [30, 45, 60, 90]

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var flow = OnboardingFlow(ladderRungCounts: [])
    @Published private(set) var content = OnboardingContent(ladders: [], gymPresets: [], lifts: [])
    /// Whether the last move went forward, so the transition slides the right way.
    @Published private(set) var movingForward = true
    /// True while Finish waits for the saves; nothing else blocks on the network.
    @Published private(set) var isFinishing = false
    @Published var errorMessage: String?
    /// What the planning screen shows once onboarding is finished.
    @Published private(set) var planWait: PlanWait = .waiting(slow: false)

    // Answers
    @Published private(set) var goal: TrainingGoal?
    @Published private(set) var experience: OnboardingExperience?
    @Published var daysPerWeek = 4
    @Published var sessionLength = 60
    @Published private(set) var gymPreset: OnboardingGymPreset?
    @Published var equipmentIds: Set<Int> = []
    /// Typed one-rep maxes in lbs, by exercise id.
    @Published var oneRepMaxes: [Int: String] = [:]
    @Published var sex: OnboardingSex?
    @Published var age = ""
    @Published var heightFeet = ""
    @Published var heightInches = ""
    @Published var bodyWeight = ""

    private let api: OnboardingAPI
    private let onFinished: () -> Void
    /// The athlete's local date, "YYYY-MM-DD": the day planning must reach.
    private let today: String
    private let timezone: String
    private let clock: () -> Date
    private let pollInterval: Duration
    private var waitStarted = Date()
    /// Only touched on the main actor, except to cancel it in `deinit`.
    nonisolated(unsafe) private var pollTask: Task<Void, Never>?
    private var savedGymId: Int?
    /// Benchmark ids saved so far, by exercise id, so clearing a lift deletes it.
    private var savedBenchmarks: [Int: Int] = [:]

    // Background saves
    private var lastSave: Task<Void, Never>?
    /// The newest save of each thing (the goal, ladder "pulling", ...), so a
    /// retry sends what the athlete answered last.
    private var latestSave: [String: () async throws -> Void] = [:]
    private var saveGeneration: [String: Int] = [:]
    private var failedSaves: Set<String> = []

    init(
        api: OnboardingAPI = ApolloOnboardingAPI(),
        onFinished: @escaping () -> Void = { AuthState.shared.completeProvisioning() },
        today: String? = nil,
        timezone: String = TimeZone.current.identifier,
        clock: @escaping () -> Date = Date.init,
        pollInterval: Duration = .seconds(3)
    ) {
        self.api = api
        self.onFinished = onFinished
        let week = AssistantWeek()
        self.today = today ?? week.calendarDate(for: week.today)
        self.timezone = timezone
        self.clock = clock
        self.pollInterval = pollInterval
    }

    deinit {
        pollTask?.cancel()
    }

    // MARK: - Loading

    func load() async {
        phase = .loading
        do {
            // Already onboarded on the server: they left while their week was
            // being planned, so pick the wait back up.
            if try await api.isProvisioned() {
                if (try? await api.planStatus()) == nil {
                    _ = try? await api.startPlan(timezone: timezone)
                }
                startWaiting()
                return
            }
            content = try await api.loadContent()
            flow = OnboardingFlow(ladderRungCounts: content.ladders.map(\.rungs.count))
            phase = .ready
        } catch {
            phase = .failed
        }
    }

    // MARK: - Navigation

    func back() {
        guard !isFinishing else { return }
        errorMessage = nil
        move(forward: false) { $0.back() }
    }

    private func move(forward: Bool, _ change: (inout OnboardingFlow) -> Void) {
        movingForward = forward
        withAnimation(.snappy(duration: 0.35)) { change(&flow) }
    }

    private func advance() { move(forward: true) { $0.advance() } }

    // MARK: - Background saves

    /// Queues `work` behind every earlier save. `key` names what it saves; a
    /// newer save of the same key supersedes this one for retries.
    private func save(_ key: String, _ work: @escaping () async throws -> Void) {
        let generation = (saveGeneration[key] ?? 0) + 1
        saveGeneration[key] = generation
        latestSave[key] = work
        let previous = lastSave
        lastSave = Task { [weak self] in
            await previous?.value
            do {
                try await work()
                if self?.saveGeneration[key] == generation { self?.failedSaves.remove(key) }
            } catch {
                if self?.saveGeneration[key] == generation { self?.failedSaves.insert(key) }
            }
        }
    }

    /// Waits for every queued save, then retries the ones that failed.
    private func flushSaves() async throws {
        await lastSave?.value
        for key in failedSaves.sorted() {
            guard let work = latestSave[key] else { continue }
            try await work()
            failedSaves.remove(key)
        }
    }

    // MARK: - Steps

    func choose(_ goal: TrainingGoal) {
        guard flow.current == .goal else { return }
        self.goal = goal
        save("goal") { [api] in try await api.updateProfile(UpdateUserInput(primaryGoal: .some(.case(goal)))) }
        advance()
    }

    func choose(_ experience: OnboardingExperience) {
        guard flow.current == .experience else { return }
        self.experience = experience
        let input = UpdateUserInput(
            fitnessLevel: .some(.case(experience.fitnessLevel)),
            trainingYears: .some(experience.trainingYears)
        )
        save("experience") { [api] in try await api.updateProfile(input) }
        advance()
    }

    func saveSchedule() {
        guard flow.current == .schedule else { return }
        let input = UpdateUserInput(activeDaysPerWeek: .some(daysPerWeek), sessionLengthMinutes: .some(sessionLength))
        save("schedule") { [api] in try await api.updateProfile(input) }
        advance()
    }

    /// Picking a preset fills the equipment checklist; switching presets refills it.
    func choose(_ preset: OnboardingGymPreset) {
        guard flow.current == .gym else { return }
        if gymPreset != preset {
            gymPreset = preset
            equipmentIds = Set(preset.equipment.map(\.id))
        }
        advance()
    }

    /// Every piece of equipment any preset offers, so the checklist can add
    /// what a preset left out. Sorted by name.
    var allEquipment: [OnboardingEquipment] {
        Array(Set(content.gymPresets.flatMap(\.equipment))).sorted { $0.name < $1.name }
    }

    func toggleEquipment(_ id: Int) {
        if equipmentIds.contains(id) { equipmentIds.remove(id) } else { equipmentIds.insert(id) }
    }

    func saveEquipment() {
        guard flow.current == .equipment else { return }
        let name = gymPreset?.name ?? "My gym"
        let ids = Array(equipmentIds).sorted()
        // Reads savedGymId when it runs: the queue guarantees an earlier create
        // has finished, so going back and changing the list updates that gym.
        save("gym") { [weak self, api] in
            guard let self else { return }
            self.savedGymId = try await api.saveGym(id: self.savedGymId, name: name, equipmentIds: ids)
        }
        advance()
    }

    /// The ladder and question a skill step shows.
    func question(at step: OnboardingStep) -> (ladder: OnboardingLadder, rung: OnboardingRung)? {
        guard case let .skill(ladder, rung) = step else { return nil }
        return (content.ladders[ladder], content.ladders[ladder].rungs[rung])
    }

    /// Answers `step`'s question; once that settles its ladder, saves the level.
    func answer(_ yes: Bool, to step: OnboardingStep) {
        guard flow.current == step, case .skill = step else { return }
        var next = flow
        if let result = next.answerSkill(yes) {
            let ladder = content.ladders[result.ladder]
            let level = result.level.map { ladder.rungs[$0].key }
            save("skill:\(ladder.id)") { [api] in try await api.setSkillLevel(ladder: ladder.id, level: level) }
        }
        move(forward: true) { $0 = next }
    }

    func skipLadder(at step: OnboardingStep) {
        guard flow.current == step, case .skill = step else { return }
        move(forward: true) { $0.skipLadder() }
    }

    var oneRepMaxesAreValid: Bool {
        oneRepMaxes.values.allSatisfy { $0.isEmpty || parseOneRepMax($0) != nil }
    }

    var hasOneRepMaxes: Bool {
        oneRepMaxes.values.contains { parseOneRepMax($0) != nil }
    }

    func saveLifts() {
        guard flow.current == .lifts else { return }
        let entries = oneRepMaxes.mapValues(parseOneRepMax)
        save("lifts") { [weak self, api] in
            guard let self else { return }
            for (exerciseId, weight) in entries {
                if let weight {
                    self.savedBenchmarks[exerciseId] = try await api.setBenchmark(exerciseId: exerciseId, weight: weight, reps: 1)
                } else if let id = self.savedBenchmarks[exerciseId] {
                    try await api.deleteBenchmark(id: id)
                    self.savedBenchmarks[exerciseId] = nil
                }
            }
        }
        advance()
    }

    // MARK: - About you

    private var ageValue: Int? { Int(age).flatMap { (13...100).contains($0) ? $0 : nil } }
    private var weightValue: Int? { Int(bodyWeight).flatMap { (50...600).contains($0) ? $0 : nil } }
    private var heightValue: Int? {
        guard let feet = Int(heightFeet), (3...8).contains(feet) else { return nil }
        let inches = heightInches.isEmpty ? 0 : (Int(heightInches) ?? -1)
        guard (0...11).contains(inches) else { return nil }
        return feet * 12 + inches
    }

    /// Every field is optional, but one that's filled in must make sense.
    var aboutYouIsValid: Bool {
        (age.isEmpty || ageValue != nil)
            && (bodyWeight.isEmpty || weightValue != nil)
            && ((heightFeet.isEmpty && heightInches.isEmpty) || heightValue != nil)
    }

    func finish() {
        guard flow.current == .aboutYou, !isFinishing else { return }
        var input = UpdateUserInput()
        if let sex { input.gender = .some(.case(sex.api)) }
        if let ageValue { input.age = .some(ageValue) }
        if let heightValue { input.height = .some(heightValue) }
        if let weightValue { input.weight = .some(weightValue) }
        save("aboutYou") { [api] in try await api.updateProfile(input) }

        isFinishing = true
        errorMessage = nil
        Task {
            do {
                try await flushSaves()
                try await api.complete(timezone: timezone)
                isFinishing = false
                startWaiting()
            } catch {
                isFinishing = false
                errorMessage = "Couldn't save your answers. Check your connection and try again."
            }
        }
    }

    // MARK: - Planning their week

    private func startWaiting() {
        phase = .planning
        waitStarted = clock()
        planWait = .waiting(slow: false)
        poll()
    }

    private func poll() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let interval = await self?.checkPlan() else { return }
                try? await Task.sleep(for: interval)
            }
        }
    }

    /// Reads the run once; returns how long to wait before the next check, or
    /// nil when there's nothing left to wait for.
    private func checkPlan() async -> Duration? {
        // A failed read (a network blip) just means another look later.
        let status = try? await api.planStatus()
        guard !Task.isCancelled else { return nil }
        planWait = PlanWait.from(status, today: today, waited: clock().timeIntervalSince(waitStarted))
        switch planWait {
        case .ready:
            onFinished()
            return nil
        case .failed:
            return nil
        case .waiting:
            return pollInterval
        }
    }

    /// Starts planning again after a failure.
    func retryPlan() {
        guard phase == .planning, case .failed = planWait else { return }
        waitStarted = clock()
        planWait = .waiting(slow: false)
        Task {
            do {
                _ = try await api.startPlan(timezone: timezone)
                poll()
            } catch {
                planWait = .failed("Couldn't reach us. Check your connection and try again.")
            }
        }
    }

    /// Goes into the app without waiting; the server keeps planning.
    func continueToApp() {
        guard phase == .planning else { return }
        pollTask?.cancel()
        onFinished()
    }
}
