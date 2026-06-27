//
//  HIITSessionService.swift
//  wodAI
//
//  Thin async wrapper over the four HIITSession mutations, mirroring the call pattern in
//  HIITWorkoutViewModel.completeWorkout (Network.shared.client + continuation).
//
//  ⚠️ The `…Mutation` / `SensorFrameInput` symbols are GENERATED into the WodAiAPI module
//     by apollo-ios-cli from the .graphql files + HIITSession.additions.graphqls. This file
//     will not compile until codegen has run (see CLAUDE.md "GraphQL Code Generation").
//

import Foundation
import Apollo
import WodAiAPI

struct HIITSessionService {

    /// Create the session record. Returns the backend session id.
    func create(wodId: Int, startedAt: Date) async throws -> String {
        let result = try await perform(
            CreateHIITSessionMutation(wodId: String(wodId), startedAt: Self.iso(startedAt))
        )
        guard let id = result.data?.createHIITSession.id else {
            throw HIITSessionError.missingSessionId
        }
        return id
    }

    /// Append a batch of buffered frames. Returns the server ack.
    @discardableResult
    func appendFrames(sessionId: String, frames: [SensorFrame]) async throws -> Bool {
        let result = try await perform(
            AppendSensorFramesMutation(sessionId: sessionId, frames: frames.map(Self.input))
        )
        return result.data?.appendSensorFrames ?? false
    }

    /// Finalize the session. v1 sends no movement intervals (classification is out of scope).
    func complete(sessionId: String, endedAt: Date) async throws {
        _ = try await perform(
            CompleteHIITSessionMutation(
                sessionId: sessionId,
                endedAt: Self.iso(endedAt),
                movementIntervals: []
            )
        )
    }

    func abandon(sessionId: String) async throws {
        _ = try await perform(AbandonHIITSessionMutation(sessionId: sessionId))
    }

    // MARK: - Helpers

    private func perform<M: GraphQLMutation>(_ mutation: M) async throws -> GraphQLResult<M.Data> {
        try await withCheckedThrowingContinuation { continuation in
            Network.shared.client.perform(mutation: mutation) { result in
                continuation.resume(with: result)
            }
        }
    }

    private static let isoFormatter = ISO8601DateFormatter()
    private static func iso(_ date: Date) -> String { isoFormatter.string(from: date) }

    /// Map a domain frame → generated input, turning optionals into GraphQLNullable.
    private static func input(_ f: SensorFrame) -> SensorFrameInput {
        func nz(_ v: Double?) -> GraphQLNullable<Double> { v.map { .some($0) } ?? .none }
        return SensorFrameInput(
            timestamp: f.timestamp,
            accelX: nz(f.accelX), accelY: nz(f.accelY), accelZ: nz(f.accelZ),
            gyroX: nz(f.gyroX), gyroY: nz(f.gyroY), gyroZ: nz(f.gyroZ),
            heartRate: nz(f.heartRate), relativeAltitude: nz(f.relativeAltitude),
            lat: nz(f.lat), lng: nz(f.lng), horizontalAccuracy: nz(f.horizontalAccuracy)
        )
    }
}

enum HIITSessionError: Error {
    case missingSessionId
}
