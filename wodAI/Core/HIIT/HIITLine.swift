//
//  HIITLine.swift
//  wodAI
//
//  One movement line of a metcon as prescribed for the athlete ("12 Cal Row",
//  "9 Thrusters · 95 lb"), from the server's HIITPrescription. MetconView
//  lists these instead of the whiteboard text when a piece has them, and a
//  swap replaces a line's movement. A SwapOption is the server's suggestion
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

    var id: String { "\(partId ?? 0)-\(line)" }

    /// "12 Cal", "400m", "Max Reps"; nil when there's no number to show
    /// (reps under a 21-15-9 style header, which carries the counts).
    func amountText(repScheme: Bool) -> String? {
        if max {
            switch amountUnit {
            case "cal": return "Max Cal"
            case "reps": return "Max Reps"
            default: return "Max \(amountUnit)"
            }
        }
        guard let amount else { return nil }
        let n = Self.trim(amount)
        switch amountUnit {
        case "reps": return repScheme ? nil : n
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
            loadUnit: f.loadUnit?.rawValue
        )
    }
}

/// A movement a line can be swapped for, from `hiitSwapOptions`: `preview` is
/// the line as the server will save it, so a pick can show it right away.
struct SwapOption: Identifiable, Hashable {
    let preview: HIITLine

    var id: Int { preview.exerciseId }

    /// "Row · 21 Cal", "Front Squat · 9 reps · 95 lb", "Run · 300m"; just the name when
    /// there's nothing to show (reps under a 21-15-9 style header).
    func label(repScheme: Bool) -> String {
        // A bare count reads as reps in a row ("9 Thrusters"), not after a name.
        let amount = preview.amountText(repScheme: repScheme).map { preview.amountUnit == "reps" && !preview.max ? "\($0) reps" : $0 }
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

/// One block of a compound piece ("AMRAP 5", then rest), for grouping lines.
struct HIITPartHeader: Identifiable, Hashable {
    let id: Int
    let order: Int
    let format: String?
    let restAfterSeconds: Int?
}

/// A header like "21-15-9 For Time": the reps live in the header, so reps
/// lines show only the movement. Mirrors the server's renderDisplayText.
func isRepScheme(_ header: String?) -> Bool {
    guard let header else { return false }
    return header.range(of: #"\b\d+(\s*-\s*\d+)+\b"#, options: .regularExpression) != nil
}
