//
//  SkillsViewModel.swift
//  wodAI
//
//  Skills: the user declares which movements they can't perform. Excluded
//  movements are filtered out of HIIT generation server-side, so all this
//  screen does is load the catalog and toggle exclusion state.
//

import Foundation
import SwiftUI
import WodAiAPI

/// A movement in the catalog, annotated with whether the user currently
/// excludes it. Mirrors `MovementsQuery.Data.Movement`.
struct Movement: Identifiable, Equatable {
    let id: Int
    let name: String
    let muscleGroups: String
    /// 1-10 intrinsic complexity (10 = hardest); nil when unscored. Drives the
    /// list ordering (client-side, descending).
    let skillScore: Int?
    var excluded: Bool

    /// "chest, triceps" -> "Chest · Triceps" for the row subtitle.
    var muscleGroupsDisplay: String {
        muscleGroups
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

@MainActor
final class SkillsViewModel: ObservableObject {
    @Published private(set) var movements: [Movement] = []
    @Published var searchText: String = ""
    @Published private(set) var isLoading = false
    /// Ids with an in-flight toggle mutation — drives per-row spinners.
    @Published private(set) var togglingIds: Set<Int> = []
    /// Set when the initial load fails; drives the full-screen retry card.
    @Published private(set) var error: Error?
    /// Set when a single toggle fails after we've optimistically flipped it;
    /// the flip is rolled back and this drives a transient alert.
    @Published var toggleErrorMessage: String?

    private let network = Network.shared

    // MARK: - Derived, search-filtered sections

    private func matchesSearch(_ m: Movement) -> Bool {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        return q.isEmpty || m.name.range(of: q, options: .caseInsensitive) != nil
    }

    /// Descending by skill score (most complex first); unscored movements sort
    /// last, ties broken alphabetically for a stable order.
    private func byComplexityDescending(_ a: Movement, _ b: Movement) -> Bool {
        let sa = a.skillScore ?? Int.min
        let sb = b.skillScore ?? Int.min
        if sa != sb { return sa > sb }
        return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }

    /// Movements the user can perform (shown in the main list).
    var available: [Movement] {
        movements.filter { !$0.excluded && matchesSearch($0) }.sorted(by: byComplexityDescending)
    }

    /// Movements the user has excluded (shown in their own section).
    var excluded: [Movement] {
        movements.filter { $0.excluded && matchesSearch($0) }.sorted(by: byComplexityDescending)
    }

    var hasToggleError: Bool {
        get { toggleErrorMessage != nil }
        set { if !newValue { toggleErrorMessage = nil } }
    }

    // MARK: - Load

    func load() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        // Always hit the network: the mutation result is not normalized into
        // the cached query (SchemaConfiguration.cacheKeyInfo returns nil), so
        // serving cache here would show stale excluded flags after toggling on
        // a previous visit. Matches GymProfileManager's policy.
        network.client.fetch(
            query: MovementsQuery(search: .none),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.movements {
                        // Order is applied client-side (see `available`/`excluded`),
                        // so we don't depend on server sort here.
                        self.movements = data.map {
                            Movement(id: $0.id, name: $0.name, muscleGroups: $0.muscleGroups,
                                     skillScore: $0.skillScore, excluded: $0.excluded)
                        }
                    }
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "Movements")
                        // Only surface as a blocking error if we have nothing to show.
                        if self.movements.isEmpty {
                            self.error = NSError(domain: "SkillsViewModel", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Unable to load movements."])
                        }
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "Movements"])
                    self.error = networkError
                }
            }
        }
    }

    // MARK: - Toggle exclusion

    /// Optimistically flip a movement's excluded state, then persist. On
    /// failure the flip is rolled back and a transient message is shown, so the
    /// UI never drifts from the server's truth.
    func setExcluded(_ movement: Movement, excluded: Bool) {
        guard !togglingIds.contains(movement.id) else { return }
        guard let idx = movements.firstIndex(where: { $0.id == movement.id }) else { return }

        let previous = movements[idx].excluded
        movements[idx].excluded = excluded
        togglingIds.insert(movement.id)

        network.client.perform(
            mutation: SetMovementExcludedMutation(exerciseId: movement.id, excluded: excluded)
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.togglingIds.remove(movement.id)
                guard let i = self.movements.firstIndex(where: { $0.id == movement.id }) else { return }

                switch result {
                case .success(let graphQLResult):
                    if let updated = graphQLResult.data?.setMovementExcluded {
                        // Reconcile with the server's authoritative value.
                        self.movements[i].excluded = updated.excluded
                    } else {
                        self.movements[i].excluded = previous // roll back
                        let messages = graphQLResult.errors?.compactMap { $0.message }.joined(separator: "; ") ?? ""
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "SetMovementExcluded")
                        self.toggleErrorMessage = graphQLResult.errors?.first?.message
                            ?? "Couldn't update \"\(movement.name)\". Please try again."
                    }
                case .failure(let networkError):
                    self.movements[i].excluded = previous // roll back
                    TelemetryService.captureError(networkError, tags: ["operation": "SetMovementExcluded"])
                    self.toggleErrorMessage = "Couldn't update \"\(movement.name)\". You may be offline."
                }
            }
        }
    }
}
