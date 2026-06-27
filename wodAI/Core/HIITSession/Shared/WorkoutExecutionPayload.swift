//
//  WorkoutExecutionPayload.swift
//  wodAI
//
//  SHARED between the iOS app and the watchOS app targets.
//  Add this file's Target Membership to BOTH `wodAI` and `wodAI Watch`.
//
//  Describes everything the Watch needs to render and time a workout. The phone
//  builds this from a `HIITWorkout`, encodes it, and sends it to the Watch over
//  WatchConnectivity at session start. It must contain no UIKit/HealthKit types
//  so it compiles cleanly on watchOS.
//

import Foundation

/// The execution format the Watch timer should run. Parsed from the backend's
/// free-text `HIITWorkout.format` string, which is not an enum server-side.
enum WorkoutFormat: String, Codable, CaseIterable {
    case amrap
    case emom
    case forTime
    case tabata
    /// Anything we can't confidently classify — falls back to a plain count-up timer.
    case other

    /// Best-effort classification of the backend's free-text `format` field.
    /// e.g. "AMRAP", "EMOM", "For Time", "Tabata", "21-15-9".
    init(rawFormat: String?) {
        let normalized = (rawFormat ?? "")
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.contains("amrap") {
            self = .amrap
        } else if normalized.contains("emom") || normalized.contains("every minute") {
            self = .emom
        } else if normalized.contains("tabata") || normalized.contains("interval") {
            self = .tabata
        } else if normalized.contains("for time") || normalized.contains("rft") || normalized.contains("rounds for time") {
            self = .forTime
        } else {
            self = .other
        }
    }
}

/// Work/rest interval configuration for Tabata-style formats. Interval params are
/// not first-class in the schema, so these are parsed heuristically with defaults
/// (see `WorkoutExecutionPayload.parse`). Mis-parses degrade only the Tabata timer.
struct IntervalConfig: Codable, Hashable {
    var workSeconds: Int
    var restSeconds: Int
    var rounds: Int

    /// Classic Tabata: 20s work / 10s rest × 8.
    static let tabataDefault = IntervalConfig(workSeconds: 20, restSeconds: 10, rounds: 8)
}

/// The self-contained packet sent phone → watch to start a workout.
struct WorkoutExecutionPayload: Codable, Hashable {
    /// Backend `HIITSession.id`. `nil` when running watch-less / session record not yet created.
    var sessionId: String?
    /// Backend `HIITWorkout.id`.
    var wodId: Int
    var format: WorkoutFormat
    /// Raw backend fields, kept for display and debugging.
    var constraintType: String
    var constraintMagnitude: Int
    /// Ordered movement names the watch cycles through (EMOM advance, text screen list).
    var movements: [String]
    /// Full human-readable prescription shown on the workout-text screen.
    var displayText: String
    /// Present only for `.tabata`.
    var intervalConfig: IntervalConfig?
    /// Timer `t=0`, pinned to the END of the pre-roll countdown. Epoch seconds.
    /// Also the `startedAt` already sent to `CreateHIITSession`.
    var startedAt: Date

    // MARK: Derived timing helpers (single source of truth for both targets)

    /// Total time cap in seconds, when the format is time-bounded; `nil` for open count-up.
    var capSeconds: TimeInterval? {
        switch format {
        case .amrap, .emom:
            // constraintType "minutes" → magnitude is minutes.
            return TimeInterval(constraintMagnitude * 60)
        case .tabata:
            let cfg = intervalConfig ?? .tabataDefault
            return TimeInterval(cfg.rounds * (cfg.workSeconds + cfg.restSeconds))
        case .forTime, .other:
            return nil
        }
    }

    /// Whether the primary timer should count down (toward 0) vs up (stopwatch).
    var countsDown: Bool {
        switch format {
        case .amrap, .emom: return true
        case .forTime, .tabata, .other: return false
        }
    }

    /// Number of rounds when the format is round-bounded (For Time), else `nil`.
    var roundTarget: Int? {
        guard format == .forTime, constraintType.lowercased().contains("round") else { return nil }
        return constraintMagnitude
    }
}

extension IntervalConfig {
    /// Best-effort parse of a Tabata/interval spec from free text such as
    /// "Tabata: 8 rounds of 20s work / 10s rest" or "20 on / 10 off x 8".
    /// Falls back to `.tabataDefault` for anything it can't read. Pure + testable.
    static func parse(from rawText: String?) -> IntervalConfig {
        guard let text = rawText?.lowercased() else { return .tabataDefault }

        func firstInt(matching patterns: [String]) -> Int? {
            for pattern in patterns {
                if let range = text.range(of: pattern, options: .regularExpression) {
                    let digits = text[range].filter(\.isNumber)
                    if let value = Int(digits) { return value }
                }
            }
            return nil
        }

        let work = firstInt(matching: [#"(\d+)\s*s?\s*(?:on|work)"#]) ?? IntervalConfig.tabataDefault.workSeconds
        let rest = firstInt(matching: [#"(\d+)\s*s?\s*(?:off|rest)"#]) ?? IntervalConfig.tabataDefault.restSeconds
        let rounds = firstInt(matching: [#"x\s*(\d+)"#, #"(\d+)\s*rounds?"#, #"(\d+)\s*sets?"#]) ?? IntervalConfig.tabataDefault.rounds

        return IntervalConfig(workSeconds: work, restSeconds: rest, rounds: rounds)
    }
}
