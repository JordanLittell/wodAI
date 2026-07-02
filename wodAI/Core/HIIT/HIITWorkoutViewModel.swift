//
//  HIITWorkoutViewModel.swift
//  wodAI

import Foundation
import SwiftUI
import Combine
import WodAiAPI

struct HIITWorkoutTag: Identifiable, Hashable {
    let id: Int
    let name: String
}

struct HIITWorkoutItem: Identifiable, Hashable {
    let id: Int
    let format: String?
    let displayText: String
    let stimulus: String
    let constraintType: String
    let constraintMagnitude: Int
    let timeCap: Int?
    let timingScheme: WodTimerConfig?
    let tags: [HIITWorkoutTag]

    static func == (lhs: HIITWorkoutItem, rhs: HIITWorkoutItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HIITTagItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let category: String?
    let count: Int
}

enum WorkoutExecutionState {
    case idle
    case running(startTime: Date, priorElapsed: TimeInterval)
    case paused(elapsed: TimeInterval)
}

class HIITWorkoutViewModel: ObservableObject {
    static let shared = HIITWorkoutViewModel()

    @Published var currentWorkout: HIITWorkoutItem?
    @Published var isFavorited: Bool = false
    @Published var isFavoriteLoading: Bool = false

    /// Current user's rating for the workout: 1 = liked, -1 = disliked, 0 = none.
    @Published var likeScore: Int = 0
    @Published var isLikeLoading: Bool = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var executionState: WorkoutExecutionState = .idle
    @Published var showConfetti = false

    /// User-editable time cap (seconds) for For-Time workouts, seeded from the
    /// workout's `timeCap`. `nil` means no cap (count up).
    @Published var editableTimeCap: Int?

    @Published var selectedTags: [HIITTagItem] = []
    @Published var availableTags: [HIITTagItem] = []
    @Published var isLoadingTags = false

    private let network = Network.shared
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupTagSubscription()
    }

    init(preloaded: HIITWorkoutItem) {
        self.currentWorkout = preloaded
        self.editableTimeCap = preloaded.timeCap
        self.isFavorited = true
        setupTagSubscription()
        fetchLikeScore(workoutId: preloaded.id)
    }

    private func setupTagSubscription() {
        $selectedTags
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, !self.isExecuting, !self.isPaused else { return }
                self.nextWorkout()
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed state

    var isExecuting: Bool {
        if case .running = executionState { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = executionState { return true }
        return false
    }

    var elapsedSeconds: TimeInterval {
        switch executionState {
        case .idle: return 0
        case .running(let start, let prior): return prior + Date().timeIntervalSince(start)
        case .paused(let elapsed): return elapsed
        }
    }

    /// A For-Time workout, whose cap is user-editable before starting.
    var isForTime: Bool {
        currentWorkout?.format?.lowercased().contains("for time") ?? false
    }

    /// The timing configuration driving the engine: the editable-cap config for
    /// For-Time workouts, the backend `timingScheme` otherwise, or a defensive
    /// fallback when the workout has no scheme.
    var activeConfig: WodTimerConfig {
        guard let workout = currentWorkout else { return .fallback(timeCap: nil) }
        if isForTime {
            return .forTime(timeCap: editableTimeCap)
        }
        if let scheme = workout.timingScheme {
            return scheme
        }
        return .fallback(timeCap: workout.timeCap)
    }

    var readout: TimerReadout {
        activeConfig.readout(atElapsed: elapsedSeconds)
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
                            timeCap: first.timeCap,
                            timingScheme: first.timingScheme.map { WodTimerConfig(fragment: $0) },
                            tags: (first.tags ?? []).map { HIITWorkoutTag(id: $0.id, name: $0.name) }
                        )
                        self.editableTimeCap = first.timeCap
                        self.fetchIsSaved(workoutId: first.id)
                        self.fetchLikeScore(workoutId: first.id)
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
                            timeCap: workout.timeCap,
                            timingScheme: workout.timingScheme.map { WodTimerConfig(fragment: $0) },
                            tags: (workout.tags ?? []).map { HIITWorkoutTag(id: $0.id, name: $0.name) }
                        )
                        self.editableTimeCap = workout.timeCap
                        self.fetchIsSaved(workoutId: workout.id)
                        self.fetchLikeScore(workoutId: workout.id)
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

    // MARK: - Like / Dislike

    func fetchLikeScore(workoutId: Int) {
        network.client.fetch(
            query: HiitWorkoutLikeQuery(workoutId: workoutId),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                if case .success(let graphQLResult) = result {
                    self?.likeScore = graphQLResult.data?.hiitWorkoutLike ?? 0
                }
            }
        }
    }

    func toggleLike() {
        setLikeScore(likeScore == 1 ? 0 : 1)
    }

    func toggleDislike() {
        setLikeScore(likeScore == -1 ? 0 : -1)
    }

    private func setLikeScore(_ newScore: Int) {
        guard let id = currentWorkout?.id, !isLikeLoading else { return }
        let previousScore = likeScore
        likeScore = newScore
        isLikeLoading = true

        network.client.perform(
            mutation: LikeHiitWorkoutMutation(workoutId: id, score: newScore)
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLikeLoading = false

                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "LikeHiitWorkout")
                        self.likeScore = previousScore
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "LikeHiitWorkout"])
                    self.likeScore = previousScore
                }
            }
        }
    }

    // MARK: - Execution control

    func startExecution() {
        executionState = .running(startTime: Date(), priorElapsed: 0)
        startTimer()
    }

    func pauseExecution() {
        let elapsed = elapsedSeconds
        timerCancellable?.cancel()
        executionState = .paused(elapsed: elapsed)
    }

    func resumeExecution() {
        let prior = elapsedSeconds
        executionState = .running(startTime: Date(), priorElapsed: prior)
        startTimer()
    }

    func exitExecution() {
        timerCancellable?.cancel()
        executionState = .idle
    }

    func finishExecution() {
        timerCancellable?.cancel()
        executionState = .idle
        guard let id = currentWorkout?.id else { return }
        Task { await completeWorkout(id: id) }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.readout.isComplete {
                    self.finishExecution()
                    return
                }
                self.objectWillChange.send()
            }
    }

    @MainActor
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
            timeCap: nil,
            timingScheme: nil,
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
