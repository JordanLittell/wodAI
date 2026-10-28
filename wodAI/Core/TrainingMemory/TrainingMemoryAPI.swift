//
//  TrainingMemoryAPI.swift
//  wodAI
//
//  The Your training screen's calls (trainingMemory, updateMemoryItem,
//  removeMemoryItem), mapped to the Apollo-free models. The view model takes
//  a `TrainingMemoryAPI`, so tests swap in closures.
//

import Foundation
import Apollo
import WodAiAPI

struct TrainingMemoryAPI {
    var load: () async throws -> TrainingMemory
    /// Rewords an item (text) or sets a focus block's length (weeks); nil
    /// leaves that part alone.
    var update: (_ id: String, _ text: String?, _ weeks: Int?) async throws -> TrainingMemoryItem
    /// False when the item was already gone.
    var remove: (_ id: String) async throws -> Bool

    enum APIError: LocalizedError {
        case server(String)

        var errorDescription: String? {
            switch self {
            case let .server(message): return message
            }
        }
    }

    static let live = TrainingMemoryAPI(
        load: {
            let data = try await fetch(TrainingMemoryQuery(), operation: "TrainingMemory")
            let memory = data.trainingMemory
            return TrainingMemory(
                focus: memory.focus.map { item($0.fragments.memoryItemFields) },
                habits: memory.habits.map { item($0.fragments.memoryItemFields) },
                avoid: memory.avoid.map { item($0.fragments.memoryItemFields) }
            )
        },
        update: { id, text, weeks in
            let mutation = UpdateMemoryItemMutation(id: id, text: text.map { .some($0) } ?? .none, weeks: weeks.map { .some($0) } ?? .none)
            let data = try await perform(mutation, operation: "UpdateMemoryItem")
            return item(data.updateMemoryItem.fragments.memoryItemFields)
        },
        remove: { id in
            try await perform(RemoveMemoryItemMutation(id: id), operation: "RemoveMemoryItem").removeMemoryItem
        }
    )

    private static func item(_ fields: MemoryItemFields) -> TrainingMemoryItem {
        let kind: TrainingMemoryItem.Kind
        switch fields.kind {
        case .case(.focus): kind = .focus
        case .case(.avoid): kind = .avoid
        default: kind = .habit
        }
        return TrainingMemoryItem(id: fields.id, kind: kind, text: fields.text, startsOn: fields.startsOn, endsOn: fields.endsOn)
    }

    private static func fetch<Query: GraphQLQuery>(_ query: Query, operation: String) async throws -> Query.Data {
        try await withCheckedThrowingContinuation { continuation in
            Network.shared.client.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                continuation.resume(with: unwrap(result, operation: operation))
            }
        }
    }

    private static func perform<Mutation: GraphQLMutation>(_ mutation: Mutation, operation: String) async throws -> Mutation.Data {
        try await withCheckedThrowingContinuation { continuation in
            Network.shared.client.perform(mutation: mutation) { result in
                continuation.resume(with: unwrap(result, operation: operation))
            }
        }
    }

    /// The data, or the server's message (written for the athlete), reported
    /// to Sentry either way.
    private static func unwrap<Data>(_ result: Result<GraphQLResult<Data>, Error>, operation: String) -> Result<Data, Error> {
        switch result {
        case let .success(graphQLResult):
            if let errors = graphQLResult.errors, !errors.isEmpty {
                let messages = errors.compactMap(\.message).joined(separator: "; ")
                TelemetryService.captureGraphQLErrors(messages: messages, operation: operation)
                return .failure(APIError.server(errors.first?.message ?? messages))
            }
            guard let data = graphQLResult.data else { return .failure(APIError.server("No data")) }
            return .success(data)
        case let .failure(error):
            TelemetryService.captureError(error, tags: ["operation": operation])
            return .failure(error)
        }
    }
}
