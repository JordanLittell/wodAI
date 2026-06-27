//
//  PhoneConnectivityBridge.swift
//  wodAI
//
//  iPhone side of the bridge. Sends start/stop commands to the watch and receives sensor
//  batches, decoding them into the shared `SensorFrameBuffer`.
//
//  Watch-readiness is gated on `isWatchAppInstalled` (stable), NOT `isReachable` (flaps as
//  the watch screen sleeps) — see HIIT_SESSION_PLAN.md "Watch Pairing UX".
//

import Foundation
import Combine
import WatchConnectivity

final class PhoneConnectivityBridge: NSObject, ObservableObject {
    @Published private(set) var isPaired = false
    @Published private(set) var isWatchAppInstalled = false
    @Published private(set) var isReachable = false

    /// Permission state the watch reported during Devices setup (persisted).
    @Published private(set) var watchHealthAuthorized = false
    @Published private(set) var watchMotionAuthorized = false
    /// True once the watch has reported BOTH permissions granted at least once.
    @Published private(set) var isWatchConfigured = false

    /// Watch → phone lifecycle control (pause/resume/finish/abandon initiated on the watch).
    var onControl: ((WatchMessage.ControlAction) -> Void)?
    /// Watch → phone permission report (from setup).
    var onDeviceStatus: ((_ health: Bool, _ motion: Bool) -> Void)?

    private static let configuredKey = "watchDeviceConfigured"

    private let buffer: SensorFrameBuffer

    init(buffer: SensorFrameBuffer) {
        self.buffer = buffer
        super.init()
        isWatchConfigured = UserDefaults.standard.bool(forKey: Self.configuredKey)
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Tell the watch to start a workout. Uses applicationContext (survives a cold watch
    /// launch) plus a sendMessage nudge when reachable for immediacy.
    func sendStart(_ payload: WorkoutExecutionPayload) {
        let command = WatchMessage.startCommand(payload)
        let session = WCSession.default
        try? session.updateApplicationContext(command)
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        }
    }

    /// Send a lifecycle action (pause/resume/finish/abandon) to the watch.
    func sendControl(_ control: WatchMessage.ControlAction) {
        let command = WatchMessage.controlCommand(control)
        let session = WCSession.default
        try? session.updateApplicationContext(command)
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        }
    }

    /// Route an inbound message: lifecycle control / device status, else a sensor batch.
    private func handleIncoming(_ message: [String: Any]) {
        if let incoming = WatchMessage.decode(message) {
            DispatchQueue.main.async {
                switch incoming {
                case .control(let control):
                    self.onControl?(control)
                case .deviceStatus(let health, let motion):
                    self.applyDeviceStatus(health: health, motion: motion)
                case .start:
                    break // phone never receives start
                }
            }
            return
        }
        if let batch = WatchMessage.decodeBatch(message) {
            buffer.append(batch.frames())
        }
    }

    private func applyDeviceStatus(health: Bool, motion: Bool) {
        watchHealthAuthorized = health
        watchMotionAuthorized = motion
        if health && motion && !isWatchConfigured {
            isWatchConfigured = true
            UserDefaults.standard.set(true, forKey: Self.configuredKey)
        }
        onDeviceStatus?(health, motion)
    }

    private func refreshState(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityBridge: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        refreshState(session)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate for the next paired watch.
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        refreshState(session)
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        refreshState(session)
    }

    // Live messages (watch reachable): sensor frames + lifecycle control.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncoming(message)
    }

    // Queued messages (watch was unreachable; delivered FIFO on reconnect).
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncoming(userInfo)
    }

    // Control/status sent via applicationContext (survives a sleeping app).
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncoming(applicationContext)
    }
}
