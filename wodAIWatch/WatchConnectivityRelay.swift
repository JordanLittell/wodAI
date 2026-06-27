//
//  WatchConnectivityRelay.swift
//  wodAI Watch
//
//  Watch side of the bridge. Receives start/stop commands from the phone and ships
//  sensor frames back. Frames are accumulated into ~1s batches and sent with a hybrid
//  transport for durability:
//    • reachable  → sendMessage (low-latency; the phone's live HR screen stays current)
//    • not reachable → transferUserInfo (FIFO, guaranteed delivery, drains on reconnect)
//

import Foundation
import Combine
import WatchConnectivity

final class WatchConnectivityRelay: NSObject, ObservableObject {
    @Published private(set) var isReachable = false

    /// Invoked when the phone sends a start command (with the workout to run).
    var onStart: ((WorkoutExecutionPayload) -> Void)?
    /// Invoked when the phone sends a stop command.
    var onStop: (() -> Void)?

    /// Frames per batch (~1s @ 50Hz).
    private let batchSize = MotionCollector.sampleHz
    private var pending: [SensorFrame] = []
    private let lock = NSLock()

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Buffer a frame; flush a batch once `batchSize` frames have accumulated.
    func enqueue(_ frame: SensorFrame) {
        lock.lock()
        pending.append(frame)
        let ready = pending.count >= batchSize ? drainLocked() : nil
        lock.unlock()
        if let ready { send(ready) }
    }

    /// Flush whatever is buffered (call at session end).
    func flush() {
        lock.lock()
        let ready = pending.isEmpty ? nil : drainLocked()
        lock.unlock()
        if let ready { send(ready) }
    }

    // Must hold `lock`.
    private func drainLocked() -> SensorFrameBatch {
        let frames = pending
        pending.removeAll(keepingCapacity: true)
        let startMs = Int((frames.first?.timestamp ?? 0) * 1000)
        return SensorFrameBatch(startOffsetMs: startMs,
                                hz: MotionCollector.sampleHz,
                                rows: frames.map(\.compactRow))
    }

    private func send(_ batch: SensorFrameBatch) {
        guard let message = WatchMessage.batchMessage(batch) else { return }
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                // On live-send failure, fall back to guaranteed queued delivery.
                session.transferUserInfo(message)
            }
        } else {
            session.transferUserInfo(message)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityRelay: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handle(applicationContext)
    }

    private func handle(_ message: [String: Any]) {
        guard let (action, payload) = WatchMessage.decodeCommand(message) else { return }
        DispatchQueue.main.async {
            switch action {
            case .startSession:
                if let payload { self.onStart?(payload) }
            case .stopSession:
                self.onStop?()
            }
        }
    }
}
