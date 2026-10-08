//
//  ActivityStatsStore.swift
//  wodAI
//
//  Loads the Activity screen's charts for a week with one `ActivityStats`
//  request (every stat, aliased), and caches each week so flipping back
//  to one already seen is instant.
//

import Foundation
import Apollo
import WodAiAPI

@MainActor
final class ActivityStatsStore: ObservableObject {
    /// The selected week's charts; nil until its first load finishes.
    @Published private(set) var stats: ActivityStats?
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
    init(preview stats: ActivityStats?) {
        self.client = nil
        self.stats = stats
    }

    /// `force` refetches even a past week, e.g. after a workout in it was
    /// edited.
    func load(week: ActivityWeek, now: Date = Date(), force: Bool = false) async {
        guard let client else { return }
        selectedWeekStart = week.start
        errorMessage = nil

        let cached = cache[week.start]
        stats = cached
        // A past week can't change; the current one can, so it refetches
        // behind its cached charts.
        if cached != nil, !force, !week.isCurrentOrFuture(relativeTo: now) { return }
        guard week.start <= now else { return }

        isLoading = true
        let end = min(week.end.addingTimeInterval(-1), now)
        let timeZone = week.calendar.timeZone
        let formatter = ISO8601DateFormatter()
        let query = ActivityStatsQuery(
            start: formatter.string(from: week.start),
            end: formatter.string(from: end),
            timezone: .some(timeZone.identifier)
        )

        let result = await Self.fetch(query, client: client)
        guard selectedWeekStart == week.start else { return }
        isLoading = false

        switch result {
        case let .success(data):
            let loaded = ActivityStats(
                muscleLoad: StatChart(fragment: data.muscleLoad.fragments.statFields, timeZone: timeZone),
                volume: StatChart(fragment: data.volume.fragments.statFields, timeZone: timeZone),
                intensity: StatChart(fragment: data.intensity.fragments.statFields, timeZone: timeZone),
                trainingLoad: StatChart(fragment: data.trainingLoad.fragments.statFields, timeZone: timeZone)
            )
            cache[week.start] = loaded
            stats = loaded
        case let .failure(error):
            // Keep showing cached charts if there are any; only an empty card
            // needs the error.
            if stats == nil {
                errorMessage = error.localizedDescription
            }
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
