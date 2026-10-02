//
//  ApolloSessionTelemetryUploader.swift
//  wodAI
//
//  The recorder's backend calls over Apollo: the HIITSession mutations. The
//  only file in Core/Sensors that knows about generated GraphQL types.
//

import Foundation
import Apollo
import WodAiAPI

struct ApolloSessionTelemetryUploader: SessionTelemetryUploading {
    var client: ApolloClient = Network.shared.client

    struct UploadError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    func createSession(workoutId: Int, startedAt: Date, source: SensorSource) async throws -> CreatedSensorSession {
        let input = SensorSourceInput(
            kind: source.kind.rawValue,
            deviceName: source.deviceName.map { .some($0) } ?? .none,
            brand: source.brand.map { .some($0.rawValue) } ?? .none
        )
        let data = try await perform(
            CreateHIITSessionMutation(
                wodId: String(workoutId),
                startedAt: ISO8601DateFormatter().string(from: startedAt),
                source: .some(input)
            ),
            operation: "CreateHIITSession"
        )
        let session = data.createHIITSession
        return CreatedSensorSession(id: session.id, zoneThresholds: session.zoneThresholds)
    }

    func appendFrames(sessionId: String, frames: [SensorFrame]) async throws {
        let inputs = frames.map { frame in
            SensorFrameInput(
                timestamp: frame.timestamp,
                heartRate: frame.heartRate.map { .some($0) } ?? .none,
                rrIntervalsMs: frame.rrIntervalsMs.isEmpty ? .none : .some(frame.rrIntervalsMs)
            )
        }
        _ = try await perform(AppendSensorFramesMutation(sessionId: sessionId, frames: inputs), operation: "AppendSensorFrames")
    }

    func completeSession(sessionId: String, endedAt: Date) async throws -> HeartRateSummary? {
        let data = try await perform(
            CompleteHIITSessionMutation(sessionId: sessionId, endedAt: ISO8601DateFormatter().string(from: endedAt)),
            operation: "CompleteHIITSession"
        )
        return data.completeHIITSession.heartRate.map { HeartRateSummary(fields: $0.fragments.heartRateSummaryFields) }
    }

    func abandonSession(sessionId: String) async throws {
        _ = try await perform(AbandonHIITSessionMutation(sessionId: sessionId), operation: "AbandonHIITSession")
    }

    private func perform<M: GraphQLMutation>(_ mutation: M, operation: String) async throws -> M.Data {
        try await withCheckedThrowingContinuation { continuation in
            client.perform(mutation: mutation) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: operation)
                        continuation.resume(throwing: UploadError(message: messages))
                    } else if let data = graphQLResult.data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: UploadError(message: "\(operation) returned no data"))
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension HeartRateSummary {
    init(fields: HeartRateSummaryFields) {
        self.init(
            avg: fields.avg,
            max: fields.max,
            min: fields.min,
            coverage: fields.coverage,
            zoneSeconds: fields.zoneSeconds,
            trainingLoad: fields.trainingLoad,
            estimatedCalories: fields.estimatedCalories
        )
    }
}
