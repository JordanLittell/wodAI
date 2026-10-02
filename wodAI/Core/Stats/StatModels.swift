//
//  StatModels.swift
//  wodAI
//
//  Apollo-free chart data for the backend's `stat` query. A stat is either
//  categorical (one value per label over the whole range, e.g. muscle load per
//  region) or a daily series (one value per local day, zero-filled). Views draw
//  from these types only, so the generated Apollo types stay in this file.
//

import Foundation
import WodAiAPI

struct CategoryValue: Identifiable, Equatable {
    let label: String
    let value: Double
    var id: String { label }
}

struct DayValue: Identifiable, Equatable {
    /// Local midnight of the day this value belongs to.
    let day: Date
    let value: Double
    var id: Date { day }
}

struct StatChart: Equatable {
    enum Points: Equatable {
        /// Largest first.
        case categorical([CategoryValue])
        /// In day order.
        case series([DayValue])
    }

    /// "lb", "min" or "%".
    let unit: String
    /// Sum over the range; nil when a total isn't meaningful (muscle-load shares).
    let total: Double?
    let points: Points

    init(unit: String, total: Double?, points: Points) {
        self.unit = unit
        self.total = total
        if case let .categorical(values) = points {
            self.points = .categorical(values.sorted { $0.value > $1.value })
        } else {
            self.points = points
        }
    }

    /// Nil for a result shape this build doesn't know, so a new backend shape
    /// leaves its card empty instead of crashing.
    init?(fragment: StatFields, timeZone: TimeZone) {
        if let categorical = fragment.asCategoricalStat {
            self.init(unit: fragment.unit, total: fragment.total, points: .categorical(
                categorical.categories.map { CategoryValue(label: $0.label, value: $0.value) }
            ))
        } else if let series = fragment.asSeriesStat {
            self.init(unit: fragment.unit, total: fragment.total, points: .series(
                series.series.compactMap { point in
                    StatFormatting.day(from: point.x, timeZone: timeZone).map { DayValue(day: $0, value: point.y) }
                }
            ))
        } else {
            return nil
        }
    }

    /// True when there's nothing to draw: no categories, or a series of zeros.
    var isEmpty: Bool {
        switch points {
        case let .categorical(values): return values.isEmpty
        case let .series(values): return values.allSatisfy { $0.value == 0 }
        }
    }

    /// The card's headline: the formatted total ("42,300 lb"), or for a stat
    /// with no total, its largest category ("Mostly Legs").
    func headline(locale: Locale = .current) -> String? {
        if let total {
            return StatFormatting.format(total, unit: unit, locale: locale)
        }
        if case let .categorical(values) = points, let top = values.first {
            return "Mostly \(top.label)"
        }
        return nil
    }
}

/// The three charts on the Activity screen for one week.
struct ActivityStats: Equatable {
    let muscleLoad: StatChart?
    let volume: StatChart?
    let intensity: StatChart?
}

enum StatFormatting {
    /// Parses the server's local calendar date ("2026-09-28") to local midnight
    /// in `timeZone`.
    static func day(from key: String, timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    /// "42,300 lb", "86 min", "38%". Whole numbers: these are glanceable
    /// headlines and bar labels, not a ledger.
    static func format(_ value: Double, unit: String, locale: Locale = .current) -> String {
        let number = value.formatted(.number.precision(.fractionLength(0)).locale(locale))
        return unit == "%" ? "\(number)%" : "\(number) \(unit)"
    }
}
