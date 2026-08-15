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

enum WorkoutExecutionState {
    case idle
    case countingDown(endTime: Date)   // pre-roll "get ready" before the clock
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

    /// Set when a workout is finished — drives presentation of the completion
    /// screen. Cleared once the result is submitted (or skipped) and the feed
    /// advances to the next workout.
    @Published var completionDraft: WorkoutCompletionDraft?

    /// Set when submitting a completion fails. The completion screen stays up
    /// and shows this so the user can retry — the result is theirs and must not
    /// be silently discarded.
    @Published var completionError: String?
    /// True while the completion mutation is in flight (disables Done/Skip).
    @Published var isSubmittingCompletion = false

    /// User-editable time cap (seconds) for For-Time workouts, seeded from the
    /// workout's `timeCap`. `nil` means no cap (count up).
    @Published var editableTimeCap: Int?

    // MARK: - Filters
    // One selected value per dimension (Format / Duration / Intensity / Body).
    @Published var filterSelection = FilterSelection()
    /// Each dimension's options with live result counts, refreshed whenever the
    /// selection changes. A dimension missing from this map has no usable
    /// options and its dropdown is hidden.
    @Published var filterOptions: [FilterDimension: [ResolvedFilterOption]] = [:]
    @Published var isLoadingFilters = false

    /// Backend tag name -> id, loaded once from the tag catalog. Lets
    /// `WorkoutFilters` name its options in terms of the vocabulary instead of
    /// hard-coding database ids in the client.
    private var tagIdsByName: [String: Int] = [:]

    /// Length of the pre-workout "get ready" countdown, in seconds.
    static let getReadySeconds: TimeInterval = 10

    private let network = Network.shared
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let countdownFeedback = CountdownFeedback()
    private var lastCountdownTick: Int?

    init() {
        setupFilterSubscription()
    }

    init(preloaded: HIITWorkoutItem) {
        self.currentWorkout = preloaded
        self.editableTimeCap = preloaded.timeCap
        self.isFavorited = true
        setupFilterSubscription()
        fetchLikeScore(workoutId: preloaded.id)
    }

    /// Changing any dropdown fetches a matching workout and re-counts every
    /// dimension's options. Debounced only enough to coalesce a burst (e.g.
    /// "Clear all" clearing several at once) into a single round of requests.
    private func setupFilterSubscription() {
        $filterSelection
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshFilterOptions()
                guard !self.isExecuting, !self.isPaused, !self.isCountingDown else { return }
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

    var isCountingDown: Bool {
        if case .countingDown = executionState { return true }
        return false
    }

    /// Whole seconds left in the get-ready countdown, or `nil` when not counting.
    var countdownRemaining: Int? {
        guard case .countingDown(let end) = executionState else { return nil }
        return max(0, Int(ceil(end.timeIntervalSinceNow)))
    }

    var elapsedSeconds: TimeInterval {
        switch executionState {
        case .idle: return 0
        case .countingDown: return 0
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
        nextWorkout()
    }

    func nextWorkout() {
        let skippedId = currentWorkout?.id
        isLoading = true
        error = nil

        let selectedTagIds = filterSelection.tagIds
        let tagIds: GraphQLNullable<[Int]> = selectedTagIds.isEmpty ? .none : .some(selectedTagIds)

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
                            timingScheme: workout.timingScheme.flatMap { WodTimerConfig(fragment: $0) },
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

    // MARK: - Filters

    /// Loads the tag catalog once, then does a first count pass. Safe to call
    /// on every appearance — it no-ops once the catalog is in hand.
    func loadFilterCatalog() {
        guard tagIdsByName.isEmpty, !isLoadingFilters else { return }
        isLoadingFilters = true

        network.client.fetch(query: AllTagsQuery(), cachePolicy: .fetchIgnoringCacheCompletely) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let graphQLResult):
                    if let tags = graphQLResult.data?.tags {
                        // `Tag.name` is unique server-side; the uniquing closure
                        // is only here so a duplicate can't trap.
                        self.tagIdsByName = Dictionary(
                            tags.map { ($0.name, $0.id) },
                            uniquingKeysWith: { first, _ in first }
                        )
                    }
                    if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "AllTags")
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "AllTags"])
                }
                self.isLoadingFilters = false
                self.refreshFilterOptions()
            }
        }
    }

    /// Select (or clear, with `nil`) one dimension's value. The Combine
    /// subscription picks the change up and refetches.
    func setFilter(_ dimension: FilterDimension, to option: ResolvedFilterOption?) {
        guard filterSelection[dimension] != option else { return }
        filterSelection[dimension] = option
    }

    func clearFilters() {
        guard !filterSelection.isEmpty else { return }
        filterSelection.clear()
    }

    /// Recomputes which options each dimension can currently offer.
    ///
    /// One request per dimension, run concurrently: each dimension is counted
    /// against the *other* dimensions' selections only. Counting a dimension
    /// against its own current value would report 0 for all of its siblings
    /// (no workout is both AMRAP and EMOM) and make switching look impossible.
    ///
    /// Counts are fetched but never surfaced — they decide only what to *omit*.
    /// Showing "Tabata (0)" would advertise the size of the catalog, and the app
    /// should feel generative rather than like a finite list being enumerated.
    func refreshFilterOptions() {
        guard !tagIdsByName.isEmpty else { return }

        let catalog = tagIdsByName
        let contexts = FilterDimension.allCases.map { ($0, filterSelection.tagIds(excluding: $0)) }
        let selected = filterSelection

        Task { @MainActor [weak self] in
            var resolved: [FilterDimension: [ResolvedFilterOption]] = [:]

            await withTaskGroup(of: (FilterDimension, [String: Int]).self) { group in
                for (dimension, context) in contexts {
                    group.addTask { (dimension, await Self.fetchTagCounts(selectedTagIds: context)) }
                }
                for await (dimension, counts) in group {
                    // Two reasons to drop an option: the catalog doesn't carry
                    // the tag yet, or it would yield nothing. Either way the
                    // user never sees a choice that leads to an empty feed.
                    //
                    // The exception is the dimension's own current selection,
                    // which is kept even at zero — dropping it would erase the
                    // active chip's label out from under the user mid-refresh.
                    let activeTagName = selected[dimension]?.option.tagName
                    let options: [ResolvedFilterOption] = dimension.options.compactMap { option in
                        guard let tagId = catalog[option.tagName] else { return nil }
                        let yields = (counts[option.tagName] ?? 0) > 0
                        guard yields || option.tagName == activeTagName else { return nil }
                        return ResolvedFilterOption(option: option, tagId: tagId)
                    }
                    if !options.isEmpty { resolved[dimension] = options }
                }
            }

            self?.filterOptions = resolved
        }
    }

    /// Tag name -> workouts it would yield on top of `selectedTagIds`.
    /// `availableTags` omits any tag that would strand the user on an empty
    /// feed, so a name absent from the result means a count of zero.
    private static func fetchTagCounts(selectedTagIds: [Int]) async -> [String: Int] {
        let argument: GraphQLNullable<[Int]> = selectedTagIds.isEmpty ? .none : .some(selectedTagIds)

        return await withCheckedContinuation { continuation in
            Network.shared.client.fetch(
                query: GetAvailableTagsQuery(selectedTagIds: argument),
                cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "GetAvailableTags")
                    }
                    let tags = graphQLResult.data?.availableTags ?? []
                    continuation.resume(returning: Dictionary(
                        tags.map { ($0.name, $0.count) },
                        uniquingKeysWith: { first, _ in first }
                    ))
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "GetAvailableTags"])
                    continuation.resume(returning: [:])
                }
            }
        }
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
        countdownFeedback.prepare()
        lastCountdownTick = nil
        executionState = .countingDown(endTime: Date().addingTimeInterval(Self.getReadySeconds))
        startCountdownTimer()
    }

    /// Cancel the get-ready countdown and return to idle (e.g. a mis-tap).
    func cancelCountdown() {
        timerCancellable?.cancel()
        countdownFeedback.reset()
        executionState = .idle
    }

    /// Countdown fired: begin the actual workout clock.
    private func beginRunning() {
        timerCancellable?.cancel()
        executionState = .running(startTime: Date(), priorElapsed: 0)
        startTimer()
    }

    private func startCountdownTimer() {
        // Fire the first tick immediately — the publisher's first tick is delayed.
        if let remaining = countdownRemaining {
            lastCountdownTick = remaining
            countdownFeedback.playTick()
        }
        // Fine interval so "go" lands on time and each integer boundary is caught.
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, case .countingDown = self.executionState else { return }
                let remaining = self.countdownRemaining ?? 0
                if remaining <= 0 {
                    self.countdownFeedback.playGo()
                    self.beginRunning()
                    return
                }
                if remaining != self.lastCountdownTick {
                    self.lastCountdownTick = remaining
                    self.countdownFeedback.playTick()
                    self.objectWillChange.send()
                }
            }
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
        // Capture the finished workout + elapsed time BEFORE resetting to idle,
        // so the completion screen can seed the recorded result.
        let captured = elapsedSeconds
        guard let workout = currentWorkout else {
            executionState = .idle
            return
        }
        executionState = .idle

        var draft = WorkoutCompletionDraft(
            id: workout.id,
            workout: workout,
            capturedElapsed: captured
        )
        // Seed the For-Time finish time from the captured elapsed so the editor
        // opens pre-filled; other kinds are seeded by the view.
        if draft.kind == .forTime {
            draft.durationSeconds = max(0, Int(captured.rounded()))
        }
        completionDraft = draft
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

    /// Persist the edited completion result, then advance to the next workout.
    /// Called from the completion screen's Done button. The draft is NOT cleared
    /// up front — the screen stays up until the mutation succeeds, so a failure
    /// can be retried without the user re-entering anything.
    func submitCompletion(_ draft: WorkoutCompletionDraft) {
        Task { await performCompletion(draft) }
    }

    /// Dismiss the completion screen without recording numeric results, sending
    /// only the perceived-effort score if the user set one, then advance.
    func skipCompletion(_ draft: WorkoutCompletionDraft) {
        // Preserve RPE and notes on skip; drop only the numeric result edits.
        var effortOnly = draft
        effortOnly.durationSeconds = nil
        effortOnly.roundsCompleted = nil
        effortOnly.repsCompleted = nil
        Task { await performCompletion(effortOnly) }
    }

    @MainActor
    private func performCompletion(_ draft: WorkoutCompletionDraft) async {
        guard !isSubmittingCompletion else { return }
        isSubmittingCompletion = true
        completionError = nil
        defer { isSubmittingCompletion = false }

        // A blank or whitespace-only note is "no note", not an empty string.
        let trimmedNotes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                Network.shared.client.perform(
                    mutation: CompleteHiitWorkoutMutation(
                        id: draft.id,
                        durationSeconds: draft.durationSeconds.map { .some($0) } ?? .none,
                        roundsCompleted: draft.roundsCompleted.map { .some($0) } ?? .none,
                        repsCompleted: draft.repsCompleted.map { .some($0) } ?? .none,
                        perceivedEffort: draft.perceivedEffort.map { .some($0) } ?? .none,
                        notes: trimmedNotes.isEmpty ? .none : .some(trimmedNotes)
                    )
                ) { result in
                    continuation.resume(with: result)
                }
            }
            if let errors = result.errors, !errors.isEmpty {
                let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                TelemetryService.captureGraphQLErrors(messages: messages, operation: "CompleteHiitWorkout")
                completionError = "We couldn't save your result. Please try again."
                return
            }
            TelemetryService.captureMessage("workout.hiit_completed")
        } catch {
            print("⚠️ Failed to complete workout: \(error)")
            TelemetryService.captureError(error, tags: ["operation": "CompleteHiitWorkout"])
            completionError = "We couldn't save your result. Check your connection and try again."
            return
        }

        // Only past this point is the result safely on the server.
        completionDraft = nil
        nextWorkout()
    }

    /// Abandon an unsaved completion result after a failure. Used by the "Discard"
    /// escape hatch so a persistent server error can't trap the user on the screen.
    func discardCompletion() {
        completionError = nil
        completionDraft = nil
        nextWorkout()
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
        // Seed the filter bar straight from the shipping vocabulary so previews
        // exercise the real labels — and therefore the real chip widths — rather
        // than a copy that can drift. Tag ids are arbitrary; nothing resolves
        // them without a backend.
        var nextTagId = 100
        vm.filterOptions = Dictionary(uniqueKeysWithValues: FilterDimension.allCases.map { dimension in
            let options = dimension.options.map { option -> ResolvedFilterOption in
                nextTagId += 1
                return ResolvedFilterOption(option: option, tagId: nextTagId)
            }
            return (dimension, options)
        })
        return vm
    }
}
