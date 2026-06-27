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

    private let buffer: SensorFrameBuffer

    init(buffer: SensorFrameBuffer) {
        self.buffer = buffer
        super.init()
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

    func sendStop() {
        let command = WatchMessage.stopCommand()
        let session = WCSession.default
        try? session.updateApplicationContext(command)
        if session.isReachable {
            session.sendMessage(command, replyHandler: nil, errorHandler: nil)
        }
    }

    private func ingest(_ message: [String: Any]) {
        guard let batch = WatchMessage.decodeBatch(message) else { return }
        buffer.append(batch.frames())
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

    // Live frames (watch reachable).
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        ingest(message)
    }

    // Queued frames (watch was unreachable; delivered FIFO on reconnect).
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        ingest(userInfo)
    }
}
