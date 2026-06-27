//
//  WatchConnectivityProtocol.swift
//  wodAI
//
//  SHARED wire contract for phone↔watch messages. Both sides import this so the
//  message keys and (de)serialization never drift. Payloads are plain `[String: Any]`
//  dictionaries (what WCSession transports natively); rich models are JSON-encoded
//  into a single key.
//

import Foundation

enum WatchMessage {
    // Top-level keys
    static let action = "action"          // command discriminator (phone → watch)
    static let payloadJSON = "payload"    // JSON-encoded WorkoutExecutionPayload
    static let batchJSON = "batch"        // JSON-encoded SensorFrameBatch (watch → phone)

    enum Action: String {
        case startSession
        case stopSession
    }

    // MARK: Phone → Watch commands

    /// Build the `startSession` command carrying the workout to execute.
    static func startCommand(_ payload: WorkoutExecutionPayload) -> [String: Any] {
        var message: [String: Any] = [action: Action.startSession.rawValue]
        if let data = try? JSONEncoder.iso.encode(payload) {
            message[payloadJSON] = data
        }
        return message
    }

    static func stopCommand() -> [String: Any] {
        [action: Action.stopSession.rawValue]
    }

    /// Decode an incoming command into (action, optional payload). Returns nil if unrecognized.
    static func decodeCommand(_ message: [String: Any]) -> (Action, WorkoutExecutionPayload?)? {
        guard let raw = message[action] as? String, let parsed = Action(rawValue: raw) else { return nil }
        var payload: WorkoutExecutionPayload?
        if let data = message[payloadJSON] as? Data {
            payload = try? JSONDecoder.iso.decode(WorkoutExecutionPayload.self, from: data)
        }
        return (parsed, payload)
    }

    // MARK: Watch → Phone telemetry

    static func batchMessage(_ batch: SensorFrameBatch) -> [String: Any]? {
        guard let data = try? JSONEncoder.iso.encode(batch) else { return nil }
        return [batchJSON: data]
    }

    static func decodeBatch(_ message: [String: Any]) -> SensorFrameBatch? {
        guard let data = message[batchJSON] as? Data else { return nil }
        return try? JSONDecoder.iso.decode(SensorFrameBatch.self, from: data)
    }
}

extension JSONEncoder {
    /// Shared encoder with ISO-8601 dates (matches the GraphQL `DateTime` scalar style).
    static let iso: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let iso: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
