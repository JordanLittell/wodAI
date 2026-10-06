//
//  WorkoutFilters.swift
//  wodAI
//
//  The filter-bar model: three single-select dimensions, each backed by an
//  explicit allowlist of backend tag names.
//
//  Why an allowlist rather than "every tag in this category": the backend's tag
//  categories are shared by more than one vocabulary — `timeDomain` holds
//  short/medium/long alongside blast/grinder, and `format` holds for-time and
//  amrap alongside partner. Naming the options explicitly keeps the dropdowns
//  stable and readable no matter what else gets tagged server-side.
//
//  Every dimension is single-select on purpose. The backend's `tagIds` filter
//  ANDs across all supplied tags, so one value per dimension composes exactly
//  right ("AMRAP _and_ short _and_ upper-body"). Two values from the same
//  dimension would AND into a near-guaranteed empty set.
//
//  There is deliberately no intensity dimension. Intensity is a mode of
//  execution rather than a property of the workout — the same piece is a burner
//  or a warm-up depending on how it is attacked — and a single workout can carry
//  several stimuli at once, which a single-select dropdown cannot express.

import Foundation

/// One dropdown in the filter bar.
enum FilterDimension: String, CaseIterable, Identifiable, Hashable {
    case format
    case duration
    case body

    var id: String { rawValue }

    /// Label shown when nothing is selected, and as the menu's header.
    var title: String {
        switch self {
        case .format:    return "Format"
        case .duration:  return "Duration"
        case .body:      return "Body"
        }
    }

    var icon: String {
        switch self {
        case .format:    return "square.grid.2x2"
        case .duration:  return "clock"
        case .body:      return "figure.strengthtraining.traditional"
        }
    }

    /// The options, in display order. `tagName` must match a backend `Tag.name`.
    var options: [FilterOption] {
        switch self {
        case .format:
            return [
                FilterOption(tagName: "for-time", label: "For Time"),
                FilterOption(tagName: "amrap", label: "AMRAP"),
                FilterOption(tagName: "emom", label: "EMOM"),
                FilterOption(tagName: "tabata", label: "Tabata"),
                FilterOption(tagName: "chipper", label: "Chipper"),
            ]
        case .duration:
            return [
                FilterOption(tagName: "short", label: "Under 8 min", shortLabel: "<8 min"),
                FilterOption(tagName: "medium", label: "8–20 min"),
                FilterOption(tagName: "long", label: "Over 20 min", shortLabel: "20+ min"),
            ]
        case .body:
            return [
                FilterOption(tagName: "full-body", label: "Full body", shortLabel: "Full"),
                FilterOption(tagName: "upper-body", label: "Upper body", shortLabel: "Upper"),
                FilterOption(tagName: "lower-body", label: "Lower body", shortLabel: "Lower"),
            ]
        }
    }
}

/// One selectable value within a dimension. `tagName` is the join key to the
/// backend vocabulary; the numeric tag id is resolved at runtime from the tag
/// catalog, so the client never hard-codes database ids.
struct FilterOption: Identifiable, Hashable {
    let tagName: String
    let label: String
    /// Abbreviated form for the chip, where all dimensions share an equal third
    /// of the row. `nil` when `label` is already short enough to fit.
    let shortLabel: String?

    init(tagName: String, label: String, shortLabel: String? = nil) {
        self.tagName = tagName
        self.label = label
        self.shortLabel = shortLabel
    }

    var id: String { tagName }

    /// What the chip shows. Menus always use the descriptive `label`, so the
    /// abbreviation never has to carry the explanation on its own.
    var chipLabel: String { shortLabel ?? label }
}

/// A resolved option, ready to render: the display option plus the backend tag
/// id it resolves to. Options that would yield no workouts are dropped upstream
/// in `refreshFilterOptions`, so anything reaching the UI is selectable.
struct ResolvedFilterOption: Identifiable, Hashable {
    let option: FilterOption
    let tagId: Int

    var id: String { option.id }
    var label: String { option.label }
    var chipLabel: String { option.chipLabel }
}

/// The user's current filter state: at most one tag per dimension.
struct FilterSelection: Equatable {
    private(set) var byDimension: [FilterDimension: ResolvedFilterOption] = [:]

    var isEmpty: Bool { byDimension.isEmpty }

    var activeCount: Int { byDimension.count }

    subscript(dimension: FilterDimension) -> ResolvedFilterOption? {
        get { byDimension[dimension] }
        set { byDimension[dimension] = newValue }
    }

    /// Every selected tag id — what goes on the wire as `tagIds`.
    var tagIds: [Int] {
        // Sorted so an unchanged selection always produces an identical array,
        // which keeps Equatable-driven refetches from firing spuriously.
        byDimension.values.map(\.tagId).sorted()
    }

    /// Selected tag ids *excluding* one dimension — the context for counting
    /// that dimension's own options. Without this, an already-selected value
    /// would zero out its siblings (nothing is both AMRAP and EMOM), making it
    /// look like you can never switch formats.
    func tagIds(excluding dimension: FilterDimension) -> [Int] {
        byDimension
            .filter { $0.key != dimension }
            .values
            .map(\.tagId)
            .sorted()
    }

    mutating func clear() {
        byDimension.removeAll()
    }
}
