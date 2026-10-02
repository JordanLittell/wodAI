//
//  SensorModels.swift
//  wodAI
//
//  Apollo-free models for wearable sensors. A `SensorProvider` (one per way of
//  connecting: Bluetooth broadcast today, a watch app or vendor SDK later)
//  produces these; `SensorManager` and `WorkoutSensorRecorder` consume them
//  without knowing which device they came from.
//

import Foundation

/// What a provider can measure. Only heart rate is recorded today; the rest
/// leave room for devices that report more (power meters, motion).
enum SensorMetric: String, Hashable {
    case heartRate
    case rrInterval
}

/// How a device connects. The raw value is what the backend stores as the
/// session's `sourceKind`.
enum SensorProviderKind: String, Codable {
    /// The standard Bluetooth Heart Rate Service (0x180D): chest straps, and
    /// watches in heart-rate broadcast mode (Garmin, Polar, Coros, ...).
    case bluetoothHeartRate = "ble-hr"
    /// Debug builds only: a generated heart-rate curve for the Simulator.
    case simulated
}

struct HeartRateSample: Equatable {
    let date: Date
    let bpm: Int
    /// Beat-to-beat intervals since the last sample, in ms; empty when the
    /// device doesn't send them.
    let rrIntervalsMs: [Double]
    /// Whether the sensor is touching skin; nil when the device doesn't say.
    let sensorContact: Bool?

    /// A reading worth recording: a real heart rate from a sensor that isn't
    /// reporting lost contact.
    var isValid: Bool { bpm > 0 && sensorContact != false }
}

/// A device seen while scanning.
struct DiscoveredDevice: Identifiable, Equatable {
    /// Stable per device for its provider (a CoreBluetooth peripheral UUID).
    let id: String
    let name: String
    let brand: DeviceBrand
    let providerKind: SensorProviderKind
    /// Signal strength in dBm; closer to 0 is nearer. Nil for a device that was
    /// already connected and so isn't advertising.
    let rssi: Int?
}

/// The device the user picked, remembered across launches so the next workout
/// reconnects to it without asking.
struct RememberedDevice: Codable, Equatable {
    let providerKind: SensorProviderKind
    let identifier: String
    let name: String
    let brand: DeviceBrand
}

enum SensorUnavailableReason: Equatable {
    case bluetoothOff
    case unauthorized
    case unsupported
}

enum SensorConnectionState: Equatable {
    /// No device chosen, or tracking is off.
    case idle
    /// Looking for the remembered device (it may not be broadcasting yet).
    case connecting(name: String)
    case connected(name: String)
    case unavailable(SensorUnavailableReason)
}

/// Where a session's samples came from, as sent to the backend.
struct SensorSource: Equatable {
    let kind: SensorProviderKind
    let deviceName: String?
    let brand: DeviceBrand?
}

/// One uploaded sample. `timestamp` is seconds since the session started.
struct SensorFrame: Equatable {
    let timestamp: Double
    let heartRate: Double?
    let rrIntervalsMs: [Double]
}

/// The server's summary of a completed session.
struct HeartRateSummary: Equatable {
    let avg: Double
    let max: Double
    let min: Double
    /// Share of the session with a valid reading, 0–1.
    let coverage: Double
    /// Seconds in zones 1–5.
    let zoneSeconds: [Int]
    /// Edwards TRIMP.
    let trainingLoad: Double
    let estimatedCalories: Double?
}

/// A point on the completion screen's heart-rate chart.
struct HeartRatePoint: Identifiable, Equatable {
    let seconds: Double
    let bpm: Int
    var id: Double { seconds }
}

/// The current reading during a workout, with its zone when known.
struct LiveHeartRate: Equatable {
    let bpm: Int
    /// 1–5, 0 below zone 1, nil until the session's thresholds are known.
    let zone: Int?

    /// The zone for `bpm` given the bpm where each of zones 1–5 starts.
    static func zone(for bpm: Int, thresholds: [Int]) -> Int? {
        guard thresholds.count == 5 else { return nil }
        return thresholds.lastIndex(where: { bpm >= $0 }).map { $0 + 1 } ?? 0
    }
}
