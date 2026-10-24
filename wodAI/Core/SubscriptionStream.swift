//
//  SubscriptionStream.swift
//  wodAI
//
//  Turns an Apollo subscription into an `AsyncThrowingStream` of Apollo-free
//  events that always ends: on the last event, on a failure, or when the
//  server goes quiet. Shared by every streamed operation (workoutGeneration,
//  whiteboardImport, assistantTurn); each maps its own results with `step`.
//

import Foundation
import Apollo
import WodAiAPI

/// What one subscription result means for the stream.
enum SubscriptionStep<Event> {
    case event(Event)
    /// The last event: yielded, then the stream finishes.
    case last(Event)
    /// The server reported a failure in-band (GenerationFailed).
    case failed(String)
    /// An event type this build doesn't know; skipped rather than failing.
    case skip
}

/// Subscribing starts the work on the server; ending the stream early (the
/// consuming task is cancelled or stops iterating) unsubscribes, which stops
/// it.
///
/// `stallTimeout` is the longest gap allowed between results. It guarantees
/// the stream ends if the socket hangs: Apollo doesn't surface the server
/// completing a subscription. Failures are reported to Sentry under
/// `operation`.
func subscriptionStream<Subscription: GraphQLSubscription, Event>(
    _ subscription: Subscription,
    client: ApolloClient = Network.shared.client,
    operation: String,
    fallbackMessage: String,
    stallTimeout: TimeInterval,
    step: @escaping (Subscription.Data) -> SubscriptionStep<Event>
) -> AsyncThrowingStream<Event, Error> {
    AsyncThrowingStream { continuation in
        // Results and the stall timer share one serial queue, so a late
        // result can't race the timer.
        let queue = DispatchQueue(label: "wodai.subscription.\(operation)")
        let stallTimer = StallTimer(queue: queue, interval: stallTimeout) {
            continuation.finish(throwing: WorkoutGenerationError.stalled)
        }

        Network.shared.connectSubscriptions()
        stallTimer.reset()

        let cancellable = client.subscribe(subscription: subscription, queue: queue) { result in
            stallTimer.reset()
            switch result {
            case let .success(graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    let messages = errors.compactMap(\.message).joined(separator: "; ")
                    TelemetryService.captureGraphQLErrors(messages: messages, operation: operation)
                    continuation.finish(throwing: WorkoutGenerationError.server(
                        errors.first?.message ?? fallbackMessage
                    ))
                    return
                }
                guard let data = graphQLResult.data else { return }
                switch step(data) {
                case let .failed(message):
                    continuation.finish(throwing: WorkoutGenerationError.server(message))
                case let .event(event):
                    continuation.yield(event)
                case let .last(event):
                    continuation.yield(event)
                    continuation.finish()
                case .skip:
                    break
                }

            case let .failure(error):
                TelemetryService.captureError(error, tags: ["operation": operation])
                continuation.finish(throwing: error)
            }
        }

        continuation.onTermination = { _ in
            cancellable.cancel()
            stallTimer.cancel()
        }
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
