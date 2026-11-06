//
//  HIITLine.swift
//  wodAI
//
//  One movement line of a metcon as prescribed for the athlete ("12 Cal Row",
//  "9 Thrusters · 95 lb"), from the server's HIITPrescription. MetconView
//  lists these instead of the whiteboard text when a piece has them; a swap
//  replaces a line's movement and an adjustment its numbers. A 21-15-9 is
//  stored round by round, so every line carries its own count. A SwapOption is the server's suggestion
//  for a line: the line as it reads after that swap (converted for the new
//  movement, e.g. "21 Cal Air Bike" → "300m Run").
//

import Foundation
import WodAiAPI

struct HIITLine: Identifiable, Hashable {
    /// The prescription's line number; unique within its part.
    let line: Int
    /// The part this line belongs to on a compound piece; nil otherwise.
    let partId: Int?
    let exerciseId: Int
    let name: String
    /// Comma-separated movement patterns ("squat,push").
    let patterns: String
    let amount: Double?
    /// The server's AmountUnit: reps, cal, m, km, mi, ft, s, min.
    let amountUnit: String
    let max: Bool
    let load: Double?
    /// The server's LoadUnit: lb, kg, pood, in (a box height).
    let loadUnit: String?
    /// What load the movement can carry (the server's LoadKind: weight, height); empty when none.
    var loads: [String] = []

    /// Whether the line can be given a load: the movement takes one, or one is already written.
    var takesLoad: Bool { load != nil || !loads.isEmpty }

    var id: String { "\(partId ?? 0)-\(line)" }

    /// "12 Cal", "400m", "Max Reps"; nil when there's no number to show.
    var amountText: String? {
        if max {
            switch amountUnit {
            case "cal": return "Max Cal"
            case "reps": return "Max Reps"
            case "s", "min": return "Max" // a max hold ("Max Plank")
            default: return "Max \(amountUnit)"
            }
        }
        guard let amount else { return nil }
        let n = Self.trim(amount)
        switch amountUnit {
        case "reps": return n
        case "cal": return "\(n) Cal"
        case "m": return "\(n)m"
        case "s": return "\(n)s"
        default: return "\(n) \(amountUnit)"
        }
    }

    /// "95 lb", "24 in"; nil when unloaded.
    var loadText: String? {
        guard let load, let loadUnit else { return nil }
        return "\(Self.trim(load)) \(loadUnit)"
    }

    private static func trim(_ n: Double) -> String {
        n.rounded() == n ? String(Int(n)) : String(format: "%g", (n * 100).rounded() / 100)
    }
}

extension HIITLine {
    init(fragment f: HiitLineFields) {
        self.init(
            line: f.line,
            partId: f.partId,
            exerciseId: f.exercise.id,
            name: f.exercise.name,
            patterns: f.exercise.patterns,
            amount: f.amount,
            amountUnit: f.amountUnit.rawValue,
            max: f.max,
            load: f.load,
            loadUnit: f.loadUnit?.rawValue,
            loads: f.exercise.loads.map(\.rawValue)
        )
    }
}

/// A movement a line can be swapped for, from `hiitSwapOptions`: `preview` is
/// the line as the server will save it, so a pick can show it right away.
struct SwapOption: Identifiable, Hashable {
    let preview: HIITLine

    var id: Int { preview.exerciseId }

    /// "Row · 21 Cal", "Front Squat · 9 reps · 95 lb", "Run · 300m"; just the name when
    /// there's nothing to show.
    var label: String {
        // A bare count reads as reps in a row ("9 Thrusters"), not after a name.
        let amount = preview.amountText.map { preview.amountUnit == "reps" && !preview.max ? "\($0) reps" : $0 }
        let details = [amount, preview.loadText].compactMap { $0 }
        return ([preview.name] + details).joined(separator: " · ")
    }
}

extension SwapOption {
    init(option o: HiitSwapOptionsQuery.Data.HiitSwapOption.Option, for line: HIITLine) {
        self.init(preview: HIITLine(
            line: line.line,
            partId: line.partId,
            exerciseId: o.exercise.id,
            name: o.exercise.name,
            patterns: o.exercise.patterns,
            amount: o.amount,
            amountUnit: o.amountUnit.rawValue,
            max: o.max,
            load: o.load,
            loadUnit: o.loadUnit?.rawValue
        ))
    }
}

extension HIITLine {
    /// The line with new numbers, as the server will save it: units as written,
    /// a load added where none was takes lb (a weight) or in (a box height).
    func adjusted(amount: Double? = nil, load: Double? = nil, clearLoad: Bool = false) -> HIITLine {
        let newLoad: Double? = clearLoad ? nil : (load ?? self.load)
        let newUnit: String? = clearLoad ? nil : load == nil ? loadUnit : (loadUnit ?? (loads.contains("weight") ? "lb" : "in"))
        return HIITLine(
            line: line, partId: partId, exerciseId: exerciseId, name: name, patterns: patterns,
            amount: amount ?? self.amount, amountUnit: amountUnit, max: max,
            load: newLoad, loadUnit: newUnit, loads: loads
        )
    }

    /// The step a stepper moves this line's amount or load by.
    func step(for field: HIITLineField) -> Double {
        switch field {
        case .amount:
            switch amountUnit {
            case "m": return 10
            case "ft": return 5
            case "km", "mi": return 0.1
            case "s": return 5
            default: return 1 // reps, cal, min
            }
        case .load:
            switch loadUnit ?? (loads.contains("weight") ? "lb" : "in") {
            case "kg": return 2.5
            case "in": return 2
            case "pood": return 0.5
            default: return 5 // lb
            }
        }
    }
}

/// One block of a compound piece ("AMRAP 5", then rest), for grouping lines.
struct HIITPartHeader: Identifiable, Hashable {
    let id: Int
    let order: Int
    let format: String?
    let restAfterSeconds: Int?
}
