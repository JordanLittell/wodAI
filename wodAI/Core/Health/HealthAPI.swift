//
//  HealthAPI.swift
//  wodAI
//
//  The server side of Apple Health, behind a protocol so HealthSync and
//  onboarding are tested without Apollo.
//

import Foundation
import Apollo
import ApolloAPI
import WodAiAPI

/// The athlete's last import, for the Apple Health screen.
struct HealthConnectionInfo: Equatable {
    let syncedAt: Date?
    let suggestedLevel: OnboardingLevel?
    let currentLevel: OnboardingLevel?
}

/// A session's logged work, to time its Health workout.
struct HealthSessionInfo: Equatable {
    struct HiitResult: Equatable {
        let pieceId: Int
        let completedAt: Date
        let durationSeconds: Int?
    }

    let id: String
    let name: String
    let completedAt: Date?
    let setTimes: [Date]
    let hiitResults: [HiitResult]
}

protocol HealthAPI {
    /// Saves the summary; returns the suggested starting level, or nil when
    /// Health had nothing to go on.
    func importSnapshot(_ snapshot: HealthSnapshot) async throws -> HealthSuggestion?
    func disconnect() async throws
    /// Nil when the athlete has never connected (or disconnected).
    func connection() async throws -> HealthConnectionInfo?
    func setFitnessLevel(_ level: OnboardingLevel) async throws
    func session(id: String) async throws -> HealthSessionInfo?
}

enum HealthAPIError: LocalizedError {
    case server(String)

    var errorDescription: String? {
        switch self {
        case let .server(message): return message
        }
    }
}

struct ApolloHealthAPI: HealthAPI {
    private var client: ApolloClient { Network.shared.client }
    private let dates = DateParser()

    func importSnapshot(_ snapshot: HealthSnapshot) async throws -> HealthSuggestion? {
        let result = try await perform(ImportHealthSnapshotMutation(input: Self.input(snapshot)), operation: "ImportHealthSnapshot")
            .importHealthSnapshot
        guard let level = result.suggestedFitnessLevel.flatMap({ OnboardingLevel(rawValue: $0.rawValue) }) else { return nil }
        return HealthSuggestion(level: level, reasons: result.reasons)
    }

    func disconnect() async throws {
        _ = try await perform(DisconnectAppleHealthMutation(), operation: "DisconnectAppleHealth")
    }

    func connection() async throws -> HealthConnectionInfo? {
        let data = try await fetch(HealthConnectionQuery(), operation: "HealthConnection")
        guard let connection = data.healthConnection else { return nil }
        return HealthConnectionInfo(
            syncedAt: dates.parseDate(connection.syncedAt),
            suggestedLevel: connection.suggestedFitnessLevel.flatMap { OnboardingLevel(rawValue: $0.rawValue) },
            currentLevel: data.user.flatMap { OnboardingLevel(rawValue: $0.fitnessLevel.rawValue) }
        )
    }

    func setFitnessLevel(_ level: OnboardingLevel) async throws {
        let input = UpdateUserInput(fitnessLevel: .some(GraphQLEnum(rawValue: level.rawValue)))
        _ = try await perform(UpdateUserMutation(input: input), operation: "UpdateUser")
    }

    func session(id: String) async throws -> HealthSessionInfo? {
        guard let workout = try await fetch(HealthSessionQuery(id: id), operation: "HealthSession").workout else { return nil }
        return HealthSessionInfo(
            id: workout.id,
            name: workout.name,
            completedAt: workout.completed ? dates.parseDate(workout.completedAt) : nil,
            setTimes: workout.strengthWorkouts.flatMap(\.components).compactMap { dates.parseDate($0.completedAt) },
            hiitResults: workout.hiitPieces.compactMap { piece in
                guard let completion = piece.completion, let at = dates.parseDate(completion.completedAt) else { return nil }
                return HealthSessionInfo.HiitResult(pieceId: piece.id, completedAt: at, durationSeconds: completion.durationSeconds)
            }
        )
    }

    /// The snapshot as the server takes it: only what's needed to suggest a
    /// level and set heart-rate zones. Body stats go through the profile.
    static func input(_ snapshot: HealthSnapshot) -> HealthSnapshotInput {
        let workouts = snapshot.workouts
        return HealthSnapshotInput(
            vo2Max: optional(snapshot.vo2Max),
            restingHeartRate: optional(snapshot.restingHeartRate.map { Int($0.rounded()) }),
            hrvMs: optional(snapshot.hrvMs),
            dailySteps: optional(snapshot.dailySteps.map { Int($0.rounded()) }),
            maxHeartRate: optional(workouts.maxHeartRate.map { Int($0.rounded()) }),
            workoutsPerWeek: .some(workouts.workoutsPerWeek),
            cardioPerWeek: .some(workouts.cardioPerWeek),
            strengthPerWeek: .some(workouts.strengthPerWeek),
            activeWeeks: .some(workouts.activeWeeks),
            topActivityTypes: .some(workouts.topActivityTypes)
        )
    }

    private static func optional<T>(_ value: T?) -> GraphQLNullable<T> {
        value.map { .some($0) } ?? .null
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
                return .failure(HealthAPIError.server(errors.first?.message ?? "Something went wrong."))
            }
            guard let data = graphQLResult.data else { return .failure(HealthAPIError.server("Something went wrong.")) }
            return .success(data)
        case let .failure(error):
            TelemetryService.captureError(error, tags: ["operation": operation])
            return .failure(error)
        }
    }
}
