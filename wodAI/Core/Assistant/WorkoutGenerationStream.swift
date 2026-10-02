//
//  WorkoutGenerationStream.swift
//  wodAI
//
//  Streams a new session from the backend's `workoutGeneration` subscription.
//  The agent writes one block at a time and the server forwards each as soon
//  as it's written, so the Assistant can draw the session piece by piece
//  instead of waiting on the whole plan.
//
//  Two layers, so the part with the logic is testable without Apollo:
//  - `WorkoutGenerationStream` turns the subscription into an
//    `AsyncThrowingStream` of Apollo-free `GenerationEvent`s that always ends:
//    on the saved session, on a failure, or when the server goes quiet.
//  - `GenerationProgress` folds those events into the `AssistantSession` the
//    view already knows how to render.
//

import Foundation
import Apollo
import WodAiAPI

/// One step of a streamed generation, in the order the server sends them:
/// `session`, then each block by `order` (a strength block followed by its
/// sets, or a HIIT block), then `complete`.
enum GenerationEvent {
    case session(name: String, description: String, stimulus: String)
    case strengthBlock(order: Int, name: String, instructions: String)
    /// One set of the strength block with the same `order`.
    case strengthSet(order: Int, component: StrengthComponent)
    case hiitBlock(order: Int, name: String, workout: HIITWorkoutItem)
    /// The session as saved; it replaces everything streamed before it.
    case complete(AssistantSession)
}

enum WorkoutGenerationError: LocalizedError {
    /// The server reported a failure (GenerationFailed or a GraphQL error).
    case server(String)
    /// No event arrived within the stall timeout.
    case stalled

    var errorDescription: String? {
        switch self {
        case let .server(message):
            return message
        case .stalled:
            return "Generating your workout is taking too long. Please try again."
        }
    }
}

struct WorkoutGenerationStream {
    var client: ApolloClient = Network.shared.client
    /// The longest gap allowed between events. Generous next to the first
    /// event (a few seconds) and the gaps after it (under a second), but it
    /// guarantees the stream ends if the socket hangs: Apollo doesn't surface
    /// the server completing a subscription.
    var stallTimeout: TimeInterval = 45

    /// Subscribing starts generation on the server; ending the stream early
    /// (the consuming task is cancelled or stops iterating) unsubscribes,
    /// which stops it.
    ///
    /// If the socket drops and reconnects mid-stream, Apollo re-subscribes and
    /// the server starts over with a fresh `session` event;
    /// `GenerationProgress` treats that as a restart.
    func events() -> AsyncThrowingStream<GenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            // Results and the stall timer share one serial queue, so a late
            // result can't race the timer.
            let queue = DispatchQueue(label: "wodai.workout-generation")
            let stallTimer = StallTimer(queue: queue, interval: stallTimeout) {
                continuation.finish(throwing: WorkoutGenerationError.stalled)
            }

            Network.shared.connectSubscriptions()
            stallTimer.reset()

            let subscription = client.subscribe(
                subscription: WorkoutGenerationSubscription(),
                queue: queue
            ) { result in
                stallTimer.reset()
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "WorkoutGeneration")
                        continuation.finish(throwing: WorkoutGenerationError.server(
                            errors.first?.message ?? "Unable to generate a workout."
                        ))
                        return
                    }
                    guard let event = graphQLResult.data?.workoutGeneration else { return }
                    if let failed = event.asGenerationFailed {
                        continuation.finish(throwing: WorkoutGenerationError.server(failed.message))
                    } else if let mapped = Self.event(from: event) {
                        continuation.yield(mapped)
                        if case .complete = mapped { continuation.finish() }
                    }
                    // Anything else is an event type this build doesn't know;
                    // skip it rather than fail the stream.

                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": "WorkoutGeneration"])
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                subscription.cancel()
                stallTimer.cancel()
            }
        }
    }

    // MARK: - Mapping

    static func event(from event: WorkoutGenerationSubscription.Data.WorkoutGeneration) -> GenerationEvent? {
        if let session = event.asGenerationSession {
            return .session(name: session.name, description: session.description, stimulus: session.stimulus)
        }
        if let block = event.asGenerationStrengthBlock {
            return .strengthBlock(order: block.order, name: block.name, instructions: block.instructions)
        }
        if let set = event.asGenerationStrengthSet {
            return .strengthSet(order: set.order, component: StrengthComponent(
                order: set.setOrder,
                reps: set.reps,
                weight: set.weight,
                rpe: set.rpe,
                exercise: ExerciseName(
                    name: set.exercise.name,
                    muscleGroups: ExerciseName.muscleGroups(fromCatalog: set.exercise.muscleGroups)
                )
            ))
        }
        if let block = event.asGenerationHiitBlock {
            let hiit = block.hiitWorkout.fragments.generatedHiitWorkout
            return .hiitBlock(order: block.order, name: hiit.name ?? "Metcon", workout: HIITWorkoutItem(
                id: hiit.id,
                format: hiit.format,
                displayText: hiit.displayText,
                stimulus: hiit.stimulus,
                constraintType: hiit.constraintType,
                constraintMagnitude: hiit.constraintMagnitude,
                timeCap: hiit.timeCap,
                timingScheme: hiit.timingScheme.flatMap { WodTimerConfig(fragment: $0) },
                tags: []
            ))
        }
        if let complete = event.asGenerationComplete {
            return .complete(AssistantViewModel.session(from: complete.workout.fragments.sessionDetails))
        }
        return nil
    }
}

/// Fires `onStall` when `reset()` hasn't been called for `interval`.
private final class StallTimer {
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private let onStall: () -> Void
    private var pending: DispatchWorkItem?

    init(queue: DispatchQueue, interval: TimeInterval, onStall: @escaping () -> Void) {
        self.queue = queue
        self.interval = interval
        self.onStall = onStall
    }

    /// Call on `queue`, or before any result can arrive.
    func reset() {
        pending?.cancel()
        let item = DispatchWorkItem(block: onStall)
        pending = item
        queue.asyncAfter(deadline: .now() + interval, execute: item)
    }

    func cancel() {
        queue.async { [weak self] in self?.pending?.cancel() }
    }
}

/// Folds streamed events into the session the Assistant renders. Pure, so the
/// ordering rules are testable without a server.
struct GenerationProgress {
    private struct Header {
        let name: String
        let description: String
        let stimulus: String
    }

    private struct Strength {
        let name: String
        let instructions: String
        var sets: [StrengthComponent] = []
    }

    private var header: Header?
    private var strength: [Int: Strength] = [:]
    private var hiit: [Int: (name: String, workout: HIITWorkoutItem)] = [:]
    private var saved: AssistantSession?

    /// True once the saved session has arrived.
    var isComplete: Bool { saved != nil }

    mutating func apply(_ event: GenerationEvent) {
        switch event {
        case let .session(name, description, stimulus):
            // A second header means the server restarted generation (the
            // socket reconnected); drop what the first attempt sent.
            self = GenerationProgress()
            header = Header(name: name, description: description, stimulus: stimulus)
        case let .strengthBlock(order, name, instructions):
            strength[order] = Strength(name: name, instructions: instructions)
        case let .strengthSet(order, component):
            strength[order]?.sets.append(component)
        case let .hiitBlock(order, name, workout):
            hiit[order] = (name, workout)
        case let .complete(session):
            saved = session
        }
    }

    /// What to show right now: the saved session once it's in, otherwise the
    /// blocks streamed so far in session order. Nil until the header arrives.
    var session: AssistantSession? {
        if let saved { return saved }
        guard let header else { return nil }

        let orders = Set(strength.keys).union(hiit.keys).sorted()
        let blocks = orders.enumerated().compactMap { index, order -> AssistantBlock? in
            let letter = AssistantFormatting.blockLetter(index)
            if let piece = strength[order] {
                let workout = StrengthWorkout(
                    id: index,
                    name: piece.name,
                    instructions: piece.instructions,
                    components: piece.sets.sorted { $0.order < $1.order }
                )
                return AssistantBlock(id: order, label: piece.name, letter: letter, kind: .strength(workout))
            }
            if let piece = hiit[order] {
                return AssistantBlock(id: order, label: piece.name, letter: letter, kind: .hiit(piece.workout))
            }
            return nil
        }

        return AssistantSession(
            name: header.name,
            description: header.description,
            stimulus: header.stimulus,
            coaching: nil,
            // The server programs generated sessions for today.
            scheduledDate: Date(),
            blocks: blocks
        )
    }
}
