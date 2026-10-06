//
//  MuscleGroup.swift
//  wodAI
//
//  The drawable muscle vocabulary shared by the API and the body map.
//
//  Every case maps 1:1 onto a highlightable region of the body illustration —
//  that constraint is the whole point. The vocabulary is chosen for what can be
//  shaded on a figure, not for anatomical completeness, so a term that can't be
//  drawn doesn't belong here. `full-body` is deliberately absent for exactly
//  that reason: the server expands whole-body movements across concrete regions
//  instead, so the figure lights up broadly and truthfully.
//
//  Raw values match the server's slugs (`WorkoutMuscleSummary.muscles[].muscle`)
//  verbatim. Unknown slugs decode to nil and are skipped rather than crashing —
//  a vocabulary added server-side must never break an older client.
//

import Foundation

enum MuscleGroup: String, CaseIterable, Hashable {
    case quads
    case hamstrings
    case glutes
    case calves
    case chest
    case back
    case lats
    case shoulders
    case traps
    case biceps
    case triceps
    case forearms
    case core
    case hipFlexors = "hip-flexors"

    /// Plain-English name shown to users. Users should not have to know what
    /// "lats" or "posterior chain" means to read their own workout summary, so
    /// the anatomical slug never reaches the screen.
    var displayName: String {
        switch self {
        case .quads:      return "Front thighs"
        case .hamstrings: return "Back thighs"
        case .glutes:     return "Glutes"
        case .calves:     return "Calves"
        case .chest:      return "Chest"
        case .back:       return "Back"
        case .lats:       return "Upper back"
        case .shoulders:  return "Shoulders"
        case .traps:      return "Traps"
        case .biceps:     return "Front arms"
        case .triceps:    return "Back arms"
        case .forearms:   return "Forearms"
        case .core:       return "Core"
        case .hipFlexors: return "Hips"
        }
    }
}

/// A workout's muscle involvement: share of estimated working time per region,
/// plus the coarse body region for the headline. Mirrors the server's
/// `WorkoutMuscleSummary`.
struct MuscleSummary: Equatable {
    /// 0–1 share of estimated working time, keyed by region. Regions absent
    /// from the dictionary were not worked.
    let shares: [MuscleGroup: Double]
    /// 'upper-body' | 'lower-body' | 'full-body', or nil when underivable.
    let region: String?

    static let empty = MuscleSummary(shares: [:], region: nil)

    var isEmpty: Bool { shares.isEmpty }

    /// Plain-English headline. Again: no jargon on screen.
    var regionHeadline: String {
        switch region {
        case "upper-body": return "Upper body workout"
        case "lower-body": return "Lower body workout"
        case "full-body":  return "Full body workout"
        default:           return "Muscles worked"
        }
    }

    /// Regions ordered hardest-worked first, for the supporting label.
    var ranked: [MuscleGroup] {
        shares.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key.rawValue < rhs.key.rawValue : lhs.value > rhs.value
        }.map(\.key)
    }
}
