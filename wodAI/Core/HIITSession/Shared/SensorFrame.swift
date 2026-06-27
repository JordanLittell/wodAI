//
//  SensorFrame.swift
//  wodAI
//
//  SHARED between targets. One sampled instant of watch telemetry. Mirrors the
//  backend `SensorFrame` / `SensorFrameInput` GraphQL shape (see HIIT_SESSION_PLAN.md).
//
//  Two representations:
//   • `SensorFrame` — the rich value type used in app code and uploaded to GraphQL.
//   • compact array form `[Double?]` — used ONLY on the WatchConnectivity wire to keep
//     batches tiny (array-of-arrays rather than array-of-dicts). Order is fixed; see
//     `CompactField`.
//

import Foundation

struct SensorFrame: Codable, Equatable {
    /// Seconds since session t=0 (end of the pre-roll countdown).
    var timestamp: Double
    var accelX: Double?
    var accelY: Double?
    var accelZ: Double?
    var gyroX: Double?
    var gyroY: Double?
    var gyroZ: Double?
    var heartRate: Double?
    var relativeAltitude: Double?
    var lat: Double?
    var lng: Double?
    var horizontalAccuracy: Double?

    /// Fixed column order for the compact wire form. Changing this is a breaking
    /// change to the watch↔phone protocol — bump and handle both sides if you do.
    enum CompactField: Int, CaseIterable {
        case accelX, accelY, accelZ, gyroX, gyroY, gyroZ
        case heartRate, relativeAltitude, lat, lng, horizontalAccuracy
    }

    /// Encode everything-but-timestamp into the fixed-order array. `nil` where unavailable.
    /// The timestamp travels via the batch header (`t` + `hz` + row index), not per row.
    var compactRow: [Double?] {
        [accelX, accelY, accelZ, gyroX, gyroY, gyroZ,
         heartRate, relativeAltitude, lat, lng, horizontalAccuracy]
    }

    /// Reconstruct a frame from a compact row + its absolute timestamp.
    init(timestamp: Double, compactRow row: [Double?]) {
        func value(_ field: CompactField) -> Double? {
            field.rawValue < row.count ? row[field.rawValue] : nil
        }
        self.timestamp = timestamp
        self.accelX = value(.accelX); self.accelY = value(.accelY); self.accelZ = value(.accelZ)
        self.gyroX = value(.gyroX); self.gyroY = value(.gyroY); self.gyroZ = value(.gyroZ)
        self.heartRate = value(.heartRate)
        self.relativeAltitude = value(.relativeAltitude)
        self.lat = value(.lat); self.lng = value(.lng)
        self.horizontalAccuracy = value(.horizontalAccuracy)
    }

    init(timestamp: Double,
         accelX: Double? = nil, accelY: Double? = nil, accelZ: Double? = nil,
         gyroX: Double? = nil, gyroY: Double? = nil, gyroZ: Double? = nil,
         heartRate: Double? = nil, relativeAltitude: Double? = nil,
         lat: Double? = nil, lng: Double? = nil, horizontalAccuracy: Double? = nil) {
        self.timestamp = timestamp
        self.accelX = accelX; self.accelY = accelY; self.accelZ = accelZ
        self.gyroX = gyroX; self.gyroY = gyroY; self.gyroZ = gyroZ
        self.heartRate = heartRate; self.relativeAltitude = relativeAltitude
        self.lat = lat; self.lng = lng; self.horizontalAccuracy = horizontalAccuracy
    }
}

/// A compact batch of frames as sent over WatchConnectivity. ~50 rows ≈ 1s @ 50Hz.
struct SensorFrameBatch: Codable {
    /// Batch start offset in milliseconds from session t=0.
    var startOffsetMs: Int
    /// Sample rate of the rows in this batch.
    var hz: Int
    /// Fixed-order rows (see `SensorFrame.CompactField`). `nil` entries become `null` in JSON.
    var rows: [[Double?]]

    /// Expand into absolute-timestamped frames.
    func frames() -> [SensorFrame] {
        let step = hz > 0 ? 1.0 / Double(hz) : 0
        let base = Double(startOffsetMs) / 1000.0
        return rows.enumerated().map { index, row in
            SensorFrame(timestamp: base + Double(index) * step, compactRow: row)
        }
    }
}
