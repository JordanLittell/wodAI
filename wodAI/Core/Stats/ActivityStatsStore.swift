//
//  ActivityStatsStore.swift
//  wodAI
//
//  Loads the Activity screen's charts for a week, and the week before for
//  comparison, with one `ActivityStats` request per week (every stat,
//  aliased). Caches each week, so flipping back to one already seen is
//  instant and stepping back a week reuses the overlay's data.
//

import Foundation
import Apollo
import WodAiAPI

@MainActor
final class ActivityStatsStore: ObservableObject {
    /// The selected week's charts; nil until its first load finishes.
    @Published private(set) var stats: ActivityStats?
    /// The week before the selected one, drawn behind it for comparison; nil
    /// until loaded, or when it failed to load.
    @Published private(set) var previousStats: ActivityStats?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client: ApolloClient?
    /// Keyed by the week's first instant.
    private var cache: [Date: ActivityStats] = [:]
    /// The week the user is looking at now; a response for any other week is
    /// stale and dropped.
    private var selectedWeekStart: Date?

    init(client: ApolloClient = Network.shared.client) {
        self.client = client
    }

    /// For previews: shows `stats` and never touches the network.
    init(preview stats: ActivityStats?, previous: ActivityStats? = nil) {
        self.client = nil
        self.stats = stats
        self.previousStats = previous
    }

    /// `force` refetches even a past week, e.g. after a workout in it was
    /// edited. The week before is loaded alongside, for the charts' overlay.
    func load(week: ActivityWeek, now: Date = Date(), force: Bool = false) async {
        guard let client else { return }
        selectedWeekStart = week.start
        errorMessage = nil

        let previousWeek = week.shifted(by: -1)
        stats = cache[week.start]
        previousStats = cache[previousWeek.start]

        // Each lands as soon as it arrives; nil means it stayed cached.
        async let current = fetchIfNeeded(week, now: now, force: force, client: client)
        async let previous = fetchIfNeeded(previousWeek, now: now, force: force, client: client)
        isLoading = true
        let (currentResult, previousResult) = await (current, previous)
        guard selectedWeekStart == week.start else { return }
        isLoading = false

        if case let .success(loaded) = previousResult {
            previousStats = loaded
        }
        switch currentResult {
        case let .success(loaded):
            stats = loaded
        case let .failure(error):
            // Keep showing cached charts if there are any; only an empty card
            // needs the error.
            if stats == nil {
                errorMessage = error.localizedDescription
            }
        case nil:
            break
        }
    }

    /// Nil when the cached week can be used as is, or the week hasn't started.
    private func fetchIfNeeded(
        _ week: ActivityWeek,
        now: Date,
        force: Bool,
        client: ApolloClient
    ) async -> Result<ActivityStats, Error>? {
        // A past week can't change; the current one can, so it refetches
        // behind its cached charts.
        if cache[week.start] != nil, !force, !week.isCurrentOrFuture(relativeTo: now) { return nil }
        guard week.start <= now else { return nil }

        let end = min(week.end.addingTimeInterval(-1), now)
        let timeZone = week.calendar.timeZone
        let formatter = ISO8601DateFormatter()
        let query = ActivityStatsQuery(
            start: formatter.string(from: week.start),
            end: formatter.string(from: end),
            timezone: .some(timeZone.identifier)
        )

        switch await Self.fetch(query, client: client) {
        case let .success(data):
            let loaded = ActivityStats(
                volume: StatChart(fragment: data.volume.fragments.statFields, timeZone: timeZone),
                intensity: StatChart(fragment: data.intensity.fragments.statFields, timeZone: timeZone),
                trainingLoad: StatChart(fragment: data.trainingLoad.fragments.statFields, timeZone: timeZone)
            )
            cache[week.start] = loaded
            return .success(loaded)
        case let .failure(error):
            return .failure(error)
        }
    }

    private static func fetch(
        _ query: ActivityStatsQuery,
        client: ApolloClient
    ) async -> Result<ActivityStatsQuery.Data, Error> {
        await withCheckedContinuation { continuation in
            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "ActivityStats")
                        continuation.resume(returning: .failure(NSError(
                            domain: "ActivityStats",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Unable to load your stats."]
                        )))
                    } else if let data = graphQLResult.data {
                        continuation.resume(returning: .success(data))
                    } else {
                        continuation.resume(returning: .failure(NSError(
                            domain: "ActivityStats",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Unable to load your stats."]
                        )))
                    }
                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": "ActivityStats"])
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
