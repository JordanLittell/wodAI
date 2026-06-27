//
//  HIITWorkoutViewModel.swift
//  wodAI

import Foundation
import SwiftUI
import Combine
import WodAiAPI

struct HIITWorkoutTag: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
}

// Codable so an in-flight workout can be persisted and restored across an app relaunch.
struct HIITWorkoutItem: Identifiable, Hashable, Codable {
    let id: Int
    let format: String?
    let displayText: String
    let stimulus: String
    let constraintType: String
    let constraintMagnitude: Int
    let tags: [HIITWorkoutTag]
}

struct HIITTagItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let category: String?
    let count: Int
}

@MainActor
class HIITWorkoutViewModel: ObservableObject {
    static let shared = HIITWorkoutViewModel()

    @Published var currentWorkout: HIITWorkoutItem?
    @Published var isFavorited: Bool = false
    @Published var isFavoriteLoading: Bool = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showConfetti = false

    @Published var selectedTags: [HIITTagItem] = []
    @Published var availableTags: [HIITTagItem] = []
    @Published var isLoadingTags = false

    private let network = Network.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupTagSubscription()
        observeSession()
    }

    init(preloaded: HIITWorkoutItem) {
        self.currentWorkout = preloaded
        self.isFavorited = true
        setupTagSubscription()
        observeSession()
    }

    private func setupTagSubscription() {
        $selectedTags
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, !self.isExecuting, !self.isPaused, !self.isCountingDown else { return }
                self.nextWorkout()
            }
            .store(in: &cancellables)
    }

    /// Mirror the shared session engine into this view model so the UI stays live, and run
    /// completion UI when a session ends (whether the user finished on the phone OR the watch).
    private func observeSession() {
        let manager = HIITSessionManager.shared
        manager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        manager.didEndSession
            .receive(on: RunLoop.main)
            .sink { [weak self] end in
                guard let self else { return }
                if end.reason == .finish {
                    Task { await self.completeWorkout(id: end.wodId) }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed execution state (backed by the shared ExecutionEngine)

    private var engine: ExecutionEngine? { HIITSessionManager.shared.engine }

    var isCountingDown: Bool { engine?.isCounting ?? false }
    var countdownRemaining: TimeInterval { engine?.countdownRemaining ?? 0 }
    var isExecuting: Bool { engine?.isRunning ?? false }

    var isPaused: Bool {
        if case .paused = engine?.state { return true }
        return false
    }

    var displaySeconds: TimeInterval { engine?.displaySeconds ?? 0 }

    /// Restore an in-flight session after the app was relaunched. Adopts the persisted
    /// workout so the view shows it instead of loading the default.
    func restoreActiveSession() {
        if let item = HIITSessionManager.shared.restoreActiveSession() {
            currentWorkout = item
        }
    }

    // MARK: - Workout loading

    func loadWorkout() {
        guard currentWorkout == nil else { return }
        guard !isLoading else { return }
        isLoading = true
        error = nil

        network.client.fetch(
            query: HIITWorkoutsQuery(
                page: .init(integerLiteral: 1),
                limit: .init(integerLiteral: 1)
            ),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let graphQLResult):
                    if let first = graphQLResult.data?.hiitWorkouts.data.first {
                        self.currentWorkout = HIITWorkoutItem(
                            id: first.id,
                            format: first.format,
                            displayText: first.displayText,
                            stimulus: first.stimulus,
                            constraintType: first.constraintType,
                            constraintMagnitude: first.constraintMagnitude,
                            tags: (first.tags ?? []).map { HIITWorkoutTag(id: $0.id, name: $0.name) }
                        )
                        self.fetchIsSaved(workoutId: first.id)
                    }
                    if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "HIITWorkouts")
                        self.error = NSError(domain: "HIITWorkout", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Workouts are temporarily unavailable. Please try again."])
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "HIITWorkouts"])
                    self.error = networkError
                }
            }
        }
    }

    func nextWorkout() {
        let skippedId = currentWorkout?.id
        isLoading = true
        error = nil

        let tagIds: GraphQLNullable<[Int]> = selectedTags.isEmpty
            ? .none
            : .some(selectedTags.map { $0.id })

        let mutation = GenerateHiitWorkoutMutation(
            skipWorkoutId: skippedId.map { .some($0) } ?? .none,
            tagIds: tagIds
        )

        network.client.perform(mutation: mutation) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let graphQLResult):
                    if let workout = graphQLResult.data?.generateHiitWorkout {
                        self.currentWorkout = HIITWorkoutItem(
                            id: workout.id,
                            format: workout.format,
                            displayText: workout.displayText,
                            stimulus: workout.stimulus,
                            constraintType: workout.constraintType,
                            constraintMagnitude: workout.constraintMagnitude,
                            tags: (workout.tags ?? []).map { HIITWorkoutTag(id: $0.id, name: $0.name) }
                        )
                        self.fetchIsSaved(workoutId: workout.id)
                    }
                    if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "GenerateHiitWorkout")
                        self.error = NSError(domain: "HIITWorkout", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Unable to generate workout. Please try again."])
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "GenerateHiitWorkout"])
                    self.error = networkError
                }
            }
        }
    }

    // MARK: - Tag management

    func fetchAvailableTags() {
        isLoadingTags = true
        let selectedIds = selectedTags.map { $0.id }
        let selectedTagIds: GraphQLNullable<[Int]> = selectedIds.isEmpty ? .none : .some(selectedIds)

        network.client.fetch(
            query: GetAvailableTagsQuery(selectedTagIds: selectedTagIds),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingTags = false
                if case .success(let graphQLResult) = result,
                   let tags = graphQLResult.data?.availableTags {
                    self.availableTags = tags.map {
                        HIITTagItem(
                            id: $0.id,
                            name: $0.name,
                            description: $0.description,
                            category: $0.category,
                            count: $0.count
                        )
                    }
                }
            }
        }
    }

    func addTag(_ tag: HIITTagItem) {
        guard !selectedTags.contains(where: { $0.id == tag.id }) else { return }
        selectedTags.append(tag)
        availableTags.removeAll { $0.id == tag.id }
    }

    func removeTag(id: Int) {
        selectedTags.removeAll { $0.id == id }
    }

    // MARK: - Save

    func fetchIsSaved(workoutId: Int) {
        network.client.fetch(
            query: IsSavedQuery(workoutId: workoutId),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                if case .success(let graphQLResult) = result,
                   let value = graphQLResult.data?.isSaved {
                    self?.isFavorited = value
                }
            }
        }
    }

    func toggleSaved() {
        guard let id = currentWorkout?.id, !isFavoriteLoading else { return }
        let newValue = !isFavorited
        isFavorited = newValue
        isFavoriteLoading = true

        if newValue {
            network.client.perform(mutation: SaveHiitWorkoutMutation(id: id)) { [weak self] result in
                Task { @MainActor [weak self] in
                    self?.isFavoriteLoading = false
                    if case .failure = result { self?.isFavorited = !newValue }
                }
            }
        } else {
            network.client.perform(mutation: UnsaveHiitWorkoutMutation(id: id)) { [weak self] result in
                Task { @MainActor [weak self] in
                    self?.isFavoriteLoading = false
                    if case .failure = result { self?.isFavorited = !newValue }
                }
            }
        }
    }

    // MARK: - Execution control

    // Execution is driven by the shared HIITSessionManager/ExecutionEngine, which keeps the
    // phone and watch in sync and propagates every action in both directions. Completion UI
    // (CompleteWorkout + confetti) runs via the `didEndSession` subscription in observeSession.

    func startExecution() {
        guard let workout = currentWorkout else { return }
        Task { await HIITSessionManager.shared.start(workout: workout) }
    }

    func pauseExecution() { HIITSessionManager.shared.pause() }

    func resumeExecution() { HIITSessionManager.shared.resume() }

    func exitExecution() { HIITSessionManager.shared.abandon() }

    func finishExecution() { HIITSessionManager.shared.finish() }

    private func completeWorkout(id: Int) async {
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                Network.shared.client.perform(
                    mutation: CompleteHiitWorkoutMutation(id: id)
                ) { result in
                    continuation.resume(with: result)
                }
            }
            if let errors = result.errors, !errors.isEmpty {
                let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                TelemetryService.captureGraphQLErrors(messages: messages, operation: "CompleteHiitWorkout")
            } else {
                TelemetryService.captureMessage("workout.hiit_completed")
            }
            _ = result.data?.completeHiitWorkout
        } catch {
            print("⚠️ Failed to complete workout: \(error)")
            TelemetryService.captureError(error, tags: ["operation": "CompleteHiitWorkout"])
        }
        nextWorkout()
        showConfetti = true
    }

    // MARK: - Preview factory

    static func preview() -> HIITWorkoutViewModel {
        let vm = HIITWorkoutViewModel()
        vm.currentWorkout = HIITWorkoutItem(
            id: 1,
            format: "For Time",
            displayText: "3 Rounds for Time:\n10 Burpee Box Jump-Overs (24/20\")\n15 Kettlebell Swings (53/35 lb)\n20 Wall Balls (20/14 lb)\n\nRest 90s between rounds",
            stimulus: "Cardiovascular Endurance",
            constraintType: "rounds",
            constraintMagnitude: 3,
            tags: [
                HIITWorkoutTag(id: 1, name: "Strength"),
                HIITWorkoutTag(id: 2, name: "Cardio")
            ]
        )
        vm.selectedTags = [
            HIITTagItem(id: 1, name: "Strength", description: "Strength-focused workouts", category: "Type", count: 12)
        ]
        return vm
    }
}
