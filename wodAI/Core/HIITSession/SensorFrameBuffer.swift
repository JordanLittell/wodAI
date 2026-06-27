//
//  SensorFrameBuffer.swift
//  wodAI
//
//  iPhone-side, thread-safe in-memory buffer of decoded sensor frames awaiting upload.
//  Frames arrive from the watch (via the connectivity bridge) and are drained on a 10s
//  timer by `HIITSessionManager`. On a failed flush, drained frames are re-enqueued at
//  the FRONT so ordering is preserved and the next tick retries (the user's "buffer in
//  iOS memory then upload" requirement).
//

import Foundation

final class SensorFrameBuffer {
    /// Hard cap; if uploads stall badly we drop the OLDEST frames to bound memory.
    /// At 50Hz this is ~40s of backlog — well beyond the 10s flush cadence.
    private let capacity: Int
    private var frames: [SensorFrame] = []
    private let lock = NSLock()

    init(capacity: Int = 2_000) {
        self.capacity = capacity
    }

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return frames.count
    }

    func append(_ newFrames: [SensorFrame]) {
        guard !newFrames.isEmpty else { return }
        lock.lock(); defer { lock.unlock() }
        frames.append(contentsOf: newFrames)
        trimLocked()
    }

    /// Remove and return everything currently buffered, for upload.
    func drain() -> [SensorFrame] {
        lock.lock(); defer { lock.unlock() }
        let drained = frames
        frames.removeAll(keepingCapacity: true)
        return drained
    }

    /// Put failed-upload frames back at the front, preserving chronological order.
    func reenqueue(_ failed: [SensorFrame]) {
        guard !failed.isEmpty else { return }
        lock.lock(); defer { lock.unlock() }
        frames.insert(contentsOf: failed, at: 0)
        trimLocked()
    }

    // Must hold `lock`. Drop oldest frames beyond capacity.
    private func trimLocked() {
        if frames.count > capacity {
            frames.removeFirst(frames.count - capacity)
        }
    }
}
