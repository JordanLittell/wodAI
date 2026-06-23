//
//  HIITWorkoutViewModel.swift
//  wodAI
//

import Foundation
import SwiftUI
import Combine
import Apollo
import WodAiAPI

struct HIITWorkoutItem: Identifiable {
    let id: Int
    let displayText: String
    let stimulus: String
    let constraintType: String
    let constraintMagnitude: Int
}

enum WorkoutExecutionState {
    case idle
    case running(startTime: Date, priorElapsed: TimeInterval)
    case paused(elapsed: TimeInterval)
}

class HIITWorkoutViewModel: ObservableObject {
    @Published var currentWorkout: HIITWorkoutItem?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var executionState: WorkoutExecutionState = .idle
    @Published var showConfetti = false

    private var allWorkouts: [HIITWorkoutItem] = []
    private var currentIndex = 0
    private var currentPage = 1
    private var totalPages = 1
    private let pageSize = 20
    private let network = Network.shared
    private var timerCancellable: AnyCancellable?

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

    var isCountDown: Bool { currentWorkout?.constraintType == "minutes" }
    var timerTarget: TimeInterval { TimeInterval(currentWorkout?.constraintMagnitude ?? 0) }

    var displaySeconds: TimeInterval {
        isCountDown ? max(0, timerTarget - elapsedSeconds) : elapsedSeconds
    }

    // MARK: - Workout loading

    func loadWorkout() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        network.client.fetch(
            query: HIITWorkoutsQuery(
                page: .init(integerLiteral: 1),
                limit: .init(integerLiteral: pageSize)
            ),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.hiitWorkouts {
                        self.allWorkouts = data.data.map {
                            HIITWorkoutItem(
                                id: $0.id,
                                displayText: $0.displayText,
                                stimulus: $0.stimulus,
                                constraintType: $0.constraintType,
                                constraintMagnitude: $0.constraintMagnitude
                            )
                        }
                        self.totalPages = data.totalPages
                        self.currentPage = 1
                        self.currentIndex = 0
                        self.currentWorkout = self.allWorkouts.first
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
        guard !allWorkouts.isEmpty else { return }
        currentIndex = (currentIndex + 1) % allWorkouts.count

        if currentIndex == 0 && currentPage < totalPages {
            fetchNextPage()
        } else {
            currentWorkout = allWorkouts[currentIndex]
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
                self?.objectWillChange.send()
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

    // MARK: - Pagination

    private func fetchNextPage() {
        let nextPage = currentPage + 1
        network.client.fetch(
            query: HIITWorkoutsQuery(
                page: .init(integerLiteral: nextPage),
                limit: .init(integerLiteral: pageSize)
            ),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .success(let graphQLResult) = result,
                   let data = graphQLResult.data?.hiitWorkouts {
                    let newWorkouts = data.data.map {
                        HIITWorkoutItem(
                            id: $0.id,
                            displayText: $0.displayText,
                            stimulus: $0.stimulus,
                            constraintType: $0.constraintType,
                            constraintMagnitude: $0.constraintMagnitude
                        )
                    }
                    self.allWorkouts.append(contentsOf: newWorkouts)
                    self.currentPage = nextPage
                    self.totalPages = data.totalPages
                    self.currentWorkout = self.allWorkouts[self.currentIndex]
                }
            }
        }
    }

    // MARK: - Preview factory

    static func preview() -> HIITWorkoutViewModel {
        let vm = HIITWorkoutViewModel()
        vm.currentWorkout = HIITWorkoutItem(
            id: 1,
            displayText: "3 Rounds for Time:\n10 Burpee Box Jump-Overs (24/20\")\n15 Kettlebell Swings (53/35 lb)\n20 Wall Balls (20/14 lb)\n\nRest 90s between rounds",
            stimulus: "Cardiovascular Endurance",
            constraintType: "rounds",
            constraintMagnitude: 3
        )
        return vm
    }
}
