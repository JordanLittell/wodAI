//
//  ActivityFeedStore.swift
//  wodAI
//
//  Loads the Stats screen's workout log for a week: completed HIIT results and
//  strength pieces, fetched in parallel and merged into ActivityItems. Caches
//  each week like ActivityStatsStore, so flipping back to one is instant.
//

import Foundation
import Apollo
import WodAiAPI

@MainActor
final class ActivityFeedStore: ObservableObject {
    /// The selected week's items, unordered (ActivityFeed.days sorts them).
    @Published private(set) var items: [ActivityItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client: ApolloClient?
    /// Keyed by the week's first instant.
    private var cache: [Date: [ActivityItem]] = [:]
    /// A response for any other week is stale and dropped.
    private var selectedWeekStart: Date?

    init(client: ApolloClient = Network.shared.client) {
        self.client = client
    }

    /// For previews: shows `items` and never touches the network.
    init(preview items: [ActivityItem]) {
        self.client = nil
        self.items = items
    }

    func load(week: ActivityWeek, now: Date = Date()) async {
        guard let client else { return }
        selectedWeekStart = week.start
        errorMessage = nil

        let cached = cache[week.start]
        items = cached ?? []
        // A past week can't change; the current one refetches behind its cache.
        if cached != nil, !week.isCurrentOrFuture(relativeTo: now) { return }
        guard week.start <= now else { return }

        isLoading = true
        let formatter = ISO8601DateFormatter()
        let start = formatter.string(from: week.start)
        let end = formatter.string(from: week.end.addingTimeInterval(-1))

        async let hiit = Self.fetch(
            CompletedHiitWorkoutsQuery(startDate: .some(start), endDate: .some(end)),
            operation: "CompletedHiitWorkouts",
            client: client
        )
        async let strength = Self.fetch(
            CompletedStrengthWorkoutsQuery(startDate: start, endDate: end),
            operation: "CompletedStrengthWorkouts",
            client: client
        )
        let (hiitResult, strengthResult) = await (hiit, strength)
        guard selectedWeekStart == week.start else { return }
        isLoading = false

        switch (hiitResult, strengthResult) {
        case let (.success(hiitData), .success(strengthData)):
            let loaded = hiitData.completedHiitWorkouts.map { ActivityItem.hiit(Self.entry($0)) }
                + strengthData.completedStrengthWorkouts.map { ActivityItem.strength(Self.entry($0)) }
            cache[week.start] = loaded
            items = loaded
        case let (.failure(error), _), let (_, .failure(error)):
            // Keep showing a cached week if there is one; only an empty list
            // needs the error.
            if items.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Edits

    /// Swaps in an edited item wherever it's shown or cached, so its card
    /// updates without a refetch (a past week never refetches).
    func replace(_ item: ActivityItem) {
        update { $0.map { $0.id == item.id ? item : $0 } }
    }

    func remove(id: String) {
        update { $0.filter { $0.id != id } }
    }

    private func update(_ change: ([ActivityItem]) -> [ActivityItem]) {
        items = change(items)
        for week in cache.keys {
            cache[week] = cache[week].map(change)
        }
    }

    // MARK: - Mapping

    private static func entry(_ item: CompletedHiitWorkoutsQuery.Data.CompletedHiitWorkout) -> CompletedHiitEntry {
        let workout = item.workout
        return CompletedHiitEntry(
            id: item.id,
            completedAt: DateParser().parseDate(item.completedAt) ?? Date(),
            workoutId: workout.id,
            format: workout.format,
            displayText: workout.displayText,
            stimulus: workout.stimulus,
            perceivedEffort: item.perceivedEffort,
            avgHeartRate: item.heartRate.map { Int($0.avg.rounded()) },
            maxHeartRate: item.heartRate.map { Int($0.max.rounded()) },
            trainingLoad: item.trainingLoad,
            heartRate: item.heartRateSeries.map { HeartRatePoint(seconds: $0.seconds, bpm: Int($0.bpm.rounded())) },
            zoneThresholds: item.zoneThresholds,
            durationSeconds: item.durationSeconds,
            roundsCompleted: item.roundsCompleted,
            repsCompleted: item.repsCompleted,
            name: workout.name,
            constraintType: workout.constraintType,
            constraintMagnitude: workout.constraintMagnitude,
            timeCap: workout.timeCap,
            heartRateSummary: item.heartRate.map { HeartRateSummary(fields: $0.fragments.heartRateSummaryFields) }
        )
    }

    private static func entry(_ item: CompletedStrengthWorkoutsQuery.Data.CompletedStrengthWorkout) -> CompletedStrengthEntry {
        let piece = item.strengthWorkout
        let sets = piece.components.map {
            StrengthComponent(
                order: $0.order,
                reps: $0.reps,
                weight: $0.weight,
                rpe: $0.rpe,
                exercise: ExerciseName(
                    name: $0.exercise.name,
                    muscleGroups: ExerciseName.muscleGroups(fromCatalog: $0.exercise.muscleGroups),
                    videoURL: $0.exercise.videoUrl.flatMap(URL.init(string:))
                ),
                id: $0.id,
                completed: CompletedSet(
                    completedAt: $0.completedAt,
                    reps: $0.completedReps,
                    weight: $0.completedWeight,
                    rpe: $0.completedRpe
                )
            )
        }
        let workout = StrengthWorkout(
            id: piece.id,
            name: piece.name ?? "Strength",
            instructions: piece.instructions,
            components: sets,
            serverId: piece.id
        )
        return CompletedStrengthEntry(
            completedAt: DateParser().parseDate(item.completedAt) ?? Date(),
            name: piece.name,
            workout: workout
        )
    }

    // MARK: - Network

    private static func fetch<Query: GraphQLQuery>(
        _ query: Query,
        operation: String,
        client: ApolloClient
    ) async -> Result<Query.Data, Error> {
        await withCheckedContinuation { continuation in
            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: operation)
                        continuation.resume(returning: .failure(Self.error(errors.first?.message)))
                    } else if let data = graphQLResult.data {
                        continuation.resume(returning: .success(data))
                    } else {
                        continuation.resume(returning: .failure(Self.error(nil)))
                    }
                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": operation])
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    private nonisolated static func error(_ message: String?) -> NSError {
        NSError(domain: "Activity", code: 0,
                userInfo: [NSLocalizedDescriptionKey: message ?? "Unable to load your workouts."])
    }
}
