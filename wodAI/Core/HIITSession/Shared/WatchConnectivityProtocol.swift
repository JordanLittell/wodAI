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
    static let action = "action"            // message discriminator
    static let payloadJSON = "payload"      // JSON-encoded WorkoutExecutionPayload
    static let batchJSON = "batch"          // JSON-encoded SensorFrameBatch (watch → phone)
    static let controlKey = "control"       // ControlAction raw value
    static let healthAuthKey = "healthAuthorized"  // device-status flags (watch → phone)
    static let motionAuthKey = "motionAuthorized"

    enum Action: String {
        case startSession   // phone → watch, carries the workout payload
        case control        // either direction, carries a ControlAction
        case deviceStatus   // watch → phone, carries permission flags
    }

    /// Lifecycle actions that must stay in sync on both devices. Sent in either direction;
    /// the receiver applies it to its local engine WITHOUT echoing back (loop guard lives
    /// in the bridge/relay callers).
    enum ControlAction: String {
        case pause
        case resume
        case finish      // normal completion → CompleteHIITSession
        case abandon     // bailed early → AbandonHIITSession
    }

    /// A decoded inbound message. `sensorBatch` is decoded separately via `decodeBatch`.
    enum Incoming {
        case start(WorkoutExecutionPayload)
        case control(ControlAction)
        case deviceStatus(health: Bool, motion: Bool)
    }

    // MARK: Builders

    /// Build the `startSession` command carrying the workout to execute.
    static func startCommand(_ payload: WorkoutExecutionPayload) -> [String: Any] {
        var message: [String: Any] = [action: Action.startSession.rawValue]
        if let data = try? JSONEncoder.iso.encode(payload) {
            message[payloadJSON] = data
        }
        return message
    }

    static func controlCommand(_ control: ControlAction) -> [String: Any] {
        [action: Action.control.rawValue, controlKey: control.rawValue]
    }

    static func deviceStatusMessage(health: Bool, motion: Bool) -> [String: Any] {
        [action: Action.deviceStatus.rawValue, healthAuthKey: health, motionAuthKey: motion]
    }

    static func batchMessage(_ batch: SensorFrameBatch) -> [String: Any]? {
        guard let data = try? JSONEncoder.iso.encode(batch) else { return nil }
        return [batchJSON: data]
    }

    // MARK: Decoders

    /// Decode an inbound command/status message. Returns nil for sensor batches (use
    /// `decodeBatch`) and unrecognized messages.
    static func decode(_ message: [String: Any]) -> Incoming? {
        guard let raw = message[action] as? String, let parsed = Action(rawValue: raw) else { return nil }
        switch parsed {
        case .startSession:
            guard let data = message[payloadJSON] as? Data,
                  let payload = try? JSONDecoder.iso.decode(WorkoutExecutionPayload.self, from: data) else { return nil }
            return .start(payload)
        case .control:
            guard let raw = message[controlKey] as? String, let control = ControlAction(rawValue: raw) else { return nil }
            return .control(control)
        case .deviceStatus:
            let health = message[healthAuthKey] as? Bool ?? false
            let motion = message[motionAuthKey] as? Bool ?? false
            return .deviceStatus(health: health, motion: motion)
        }
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
