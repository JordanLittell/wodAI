//
//  OnboardingAPI.swift
//  wodAI
//
//  The backend calls onboarding makes, as async functions over plain models.
//  Every step saves as the athlete advances, so quitting halfway keeps what
//  they've answered; `complete()` only marks them as onboarded.
//

import Foundation
import Apollo
import WodAiAPI

struct OnboardingRung: Hashable {
    let key: String
    let question: String
}

/// One drill-down ladder, hardest rung first.
struct OnboardingLadder: Identifiable, Hashable {
    let id: String
    let domain: String
    let name: String
    let rungs: [OnboardingRung]
}

struct OnboardingEquipment: Identifiable, Hashable {
    let id: Int
    let name: String
}

struct OnboardingGymPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let equipment: [OnboardingEquipment]
}

/// A lift offered on the "your numbers" step.
struct OnboardingLift: Identifiable, Hashable {
    let id: Int // exercise id
    let name: String
}

struct OnboardingContent {
    let ladders: [OnboardingLadder]
    let gymPresets: [OnboardingGymPreset]
    let lifts: [OnboardingLift]
}

/// The latest background planning run, as the planning screen and the
/// Workout page read it.
struct PlanStatus: Equatable {
    enum State: Equatable { case running, done, failed }
    let state: State
    /// The athlete's local "YYYY-MM-DD" dates saved so far.
    let plannedDates: Set<String>
    /// Why it failed, written for the athlete.
    let message: String?

    init(state: State, plannedDates: Set<String> = [], message: String? = nil) {
        self.state = state
        self.plannedDates = plannedDates
        self.message = message
    }

    init(status: GraphQLEnum<JobStatus>, plannedDates: [String], message: String?) {
        switch status {
        case .case(.complete): state = .done
        // A canceled run plans nothing more, the same as a failed one.
        case .case(.failed), .case(.canceled): state = .failed
        default: state = .running
        }
        self.plannedDates = Set(plannedDates)
        self.message = message
    }
}

enum OnboardingError: LocalizedError {
    case server(String)
    var errorDescription: String? {
        switch self {
        case let .server(message): return message
        }
    }
}

protocol OnboardingAPI {
    func loadContent() async throws -> OnboardingContent
    func updateProfile(_ input: UpdateUserInput) async throws
    /// Creates the gym the first time; afterwards updates it. Returns its id.
    func saveGym(id: Int?, name: String, equipmentIds: [Int]) async throws -> Int
    func setSkillLevel(ladder: String, level: String?) async throws
    /// Returns the benchmark's id.
    func setBenchmark(exerciseId: Int, weight: Double, reps: Int) async throws -> Int
    func deleteBenchmark(id: Int) async throws
    /// Marks the athlete onboarded and starts planning their first week on the server.
    func complete(timezone: String) async throws
    /// The latest planning run; nil when there's never been one.
    func planStatus() async throws -> PlanStatus?
    /// Starts planning again (or returns the run in progress).
    func startPlan(timezone: String) async throws -> PlanStatus
    /// Whether the server already has the athlete onboarded (they left during planning).
    func isProvisioned() async throws -> Bool
}

struct ApolloOnboardingAPI: OnboardingAPI {
    /// Catalog names of the lifts the "your numbers" step offers, in order.
    static let liftNames = ["Back Squat", "Deadlift", "Bench Press", "Strict Press", "Clean", "Snatch"]

    private var client: ApolloClient { Network.shared.client }

    func loadContent() async throws -> OnboardingContent {
        async let skills = fetch(OnboardingSkillLaddersQuery(), operation: "OnboardingSkillLadders")
        async let presets = fetch(GymPresetsQuery(), operation: "GymPresets")
        async let movements = fetch(MovementsQuery(search: .none), operation: "Movements")

        let ladders = try await skills.skillAssessment.flatMap { domain in
            domain.ladders.map { ladder in
                OnboardingLadder(
                    id: ladder.key,
                    domain: domain.name,
                    name: ladder.name,
                    rungs: ladder.rungs.map { OnboardingRung(key: $0.key, question: $0.question) }
                )
            }
        }
        let gymPresets = try await presets.gymPresets.map { preset in
            OnboardingGymPreset(
                id: preset.key,
                name: preset.name,
                equipment: preset.equipment.map { OnboardingEquipment(id: $0.id, name: $0.name) }
            )
        }
        let idByName = Dictionary(try await movements.movements.map { ($0.name, $0.id) }, uniquingKeysWith: { a, _ in a })
        let lifts = Self.liftNames.compactMap { name in idByName[name].map { OnboardingLift(id: $0, name: name) } }
        return OnboardingContent(ladders: ladders, gymPresets: gymPresets, lifts: lifts)
    }

    func updateProfile(_ input: UpdateUserInput) async throws {
        _ = try await perform(UpdateUserMutation(input: input), operation: "UpdateUser")
    }

    func saveGym(id: Int?, name: String, equipmentIds: [Int]) async throws -> Int {
        if let id {
            let input = UpdateGymProfileInput(name: .some(name), equipmentIds: .some(equipmentIds))
            return try await perform(UpdateGymProfileMutation(updateGymProfileId: id, input: input), operation: "UpdateGymProfile")
                .updateGymProfile.id
        }
        let input = CreateGymProfileInput(name: name, equipmentIds: equipmentIds)
        return try await perform(CreateGymProfileMutation(input: input), operation: "CreateGymProfile").createGymProfile.id
    }

    func setSkillLevel(ladder: String, level: String?) async throws {
        _ = try await perform(SetSkillLevelMutation(ladder: ladder, level: level.map { .some($0) } ?? .null), operation: "SetSkillLevel")
    }

    func setBenchmark(exerciseId: Int, weight: Double, reps: Int) async throws -> Int {
        try await perform(SetStrengthBenchmarkMutation(exerciseId: exerciseId, weight: weight, reps: reps), operation: "SetStrengthBenchmark")
            .setStrengthBenchmark.id
    }

    func deleteBenchmark(id: Int) async throws {
        _ = try await perform(DeleteStrengthBenchmarkMutation(id: id), operation: "DeleteStrengthBenchmark")
    }

    func complete(timezone: String) async throws {
        _ = try await perform(CompleteOnboardingMutation(timezone: timezone), operation: "CompleteOnboarding")
    }

    func planStatus() async throws -> PlanStatus? {
        try await fetch(WeeklyPlanStatusQuery(), operation: "WeeklyPlanStatus").weeklyPlanStatus.map {
            PlanStatus(status: $0.status, plannedDates: $0.plannedDates, message: $0.message)
        }
    }

    func startPlan(timezone: String) async throws -> PlanStatus {
        let run = try await perform(StartWeeklyPlanMutation(timezone: timezone), operation: "StartWeeklyPlan").startWeeklyPlan
        return PlanStatus(status: run.status, plannedDates: run.plannedDates, message: run.message)
    }

    func isProvisioned() async throws -> Bool {
        try await fetch(IsUserProvisionedQuery(), operation: "IsUserProvisioned").isUserProvisioned
    }

    // MARK: - Apollo

    private func fetch<Query: GraphQLQuery>(_ query: Query, operation: String) async throws -> Query.Data {
        try await withCheckedThrowingContinuation { continuation in
            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                continuation.resume(with: Self.unwrap(result, operation: operation))
            }
        }
    }

    private func perform<Mutation: GraphQLMutation>(_ mutation: Mutation, operation: String) async throws -> Mutation.Data {
        try await withCheckedThrowingContinuation { continuation in
            client.perform(mutation: mutation) { result in
                continuation.resume(with: Self.unwrap(result, operation: operation))
            }
        }
    }

    private static func unwrap<Data>(_ result: Result<GraphQLResult<Data>, Error>, operation: String) -> Result<Data, Error> {
        switch result {
        case let .success(graphQLResult):
            if let errors = graphQLResult.errors, !errors.isEmpty {
                let messages = errors.compactMap(\.message).joined(separator: "; ")
                TelemetryService.captureGraphQLErrors(messages: messages, operation: operation)
                return .failure(OnboardingError.server(errors.first?.message ?? "Something went wrong."))
            }
            guard let data = graphQLResult.data else {
                return .failure(OnboardingError.server("Something went wrong."))
            }
            return .success(data)
        case let .failure(error):
            TelemetryService.captureError(error, tags: ["operation": operation])
            return .failure(error)
        }
    }
}
