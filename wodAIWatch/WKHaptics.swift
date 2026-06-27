//
//  WKHaptics.swift
//  wodAI Watch
//
//  Thin wrapper over WatchKit haptics so call sites read intent, not raw enum cases.
//

import WatchKit

enum WKHaptics {
    static func click() { WKInterfaceDevice.current().play(.click) }
    static func start() { WKInterfaceDevice.current().play(.start) }
    static func stop() { WKInterfaceDevice.current().play(.stop) }
    /// Minute / interval boundary cue.
    static func boundary() { WKInterfaceDevice.current().play(.notification) }
    /// Final 3-2-1 countdown ticks.
    static func countdownTick() { WKInterfaceDevice.current().play(.click) }
}
