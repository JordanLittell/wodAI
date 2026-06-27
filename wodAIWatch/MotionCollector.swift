//
//  MotionCollector.swift
//  wodAI Watch
//
//  CoreMotion device-motion @ 50Hz + relative altitude @ ~1Hz. Each 50Hz sample is
//  turned into a `SensorFrame` (with the latest known heart rate stamped on) and handed
//  to `onFrame` — the connectivity bridge batches and ships these to the phone.
//
//  Sample rate rationale (HIIT_SESSION_PLAN.md): 50Hz = 10ms resolution, enough for
//  the ~400ms shortest CrossFit rep peaks; moderate battery cost.
//

import Foundation
import CoreMotion
import Combine

final class MotionCollector: ObservableObject {
    /// Live values for the on-watch sensor screen (throttled to ~10Hz to spare the UI).
    @Published private(set) var accelerationMagnitude: Double = 0
    @Published private(set) var relativeAltitude: Double = 0

    /// Set by the coordinator from `WatchWorkoutSession`; stamped onto each emitted frame.
    var latestHeartRate: Double?

    /// Called on the motion queue for every 50Hz sample. Keep the handler cheap.
    var onFrame: ((SensorFrame) -> Void)?

    static let sampleHz = 50

    private let motion = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()
    private var t0: Date?
    private var sampleCount = 0

    init() {
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        motion.deviceMotionUpdateInterval = 1.0 / Double(Self.sampleHz)
    }

    /// Begin sampling. `t0` is session zero (end of countdown); frame timestamps are relative to it.
    func start(t0: Date) {
        self.t0 = t0
        self.sampleCount = 0

        if motion.isDeviceMotionAvailable {
            motion.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
                guard let self, let data, let t0 = self.t0 else { return }
                self.handle(deviceMotion: data, t0: t0)
            }
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, _ in
                guard let self, let data else { return }
                let meters = data.relativeAltitude.doubleValue
                DispatchQueue.main.async { self.relativeAltitude = meters }
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        t0 = nil
    }

    private func handle(deviceMotion data: CMDeviceMotion, t0: Date) {
        let ua = data.userAcceleration       // g, gravity removed
        let rr = data.rotationRate           // rad/s
        let magnitude = sqrt(ua.x * ua.x + ua.y * ua.y + ua.z * ua.z)

        let frame = SensorFrame(
            timestamp: Date().timeIntervalSince(t0),
            accelX: ua.x, accelY: ua.y, accelZ: ua.z,
            gyroX: rr.x, gyroY: rr.y, gyroZ: rr.z,
            heartRate: latestHeartRate,
            relativeAltitude: relativeAltitude
        )
        onFrame?(frame)

        // Throttle UI updates to ~10Hz.
        sampleCount += 1
        if sampleCount % 5 == 0 {
            DispatchQueue.main.async { self.accelerationMagnitude = magnitude }
        }
    }
}
