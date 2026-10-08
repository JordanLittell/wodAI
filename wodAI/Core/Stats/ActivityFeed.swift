//
//  ActivityFeed.swift
//  wodAI
//
//  The Stats screen's workout log, Apollo-free so it's unit-tested: completed
//  HIIT and strength items grouped under the day they were done, plus the text
//  rules their cards use (rep scheme, weight progression, RPE band).
//

import Foundation

// MARK: - Items

struct CompletedHiitEntry: Identifiable, Equatable {
    let id: Int
    let completedAt: Date
    let workoutId: Int
    var format: String? = nil
    var displayText: String = ""
    let stimulus: String
    var perceivedEffort: Int? = nil
    var avgHeartRate: Int? = nil
    var maxHeartRate: Int? = nil
    var trainingLoad: Double? = nil
    /// The session's heart rate over time; empty when none was recorded.
    var heartRate: [HeartRatePoint] = []
    /// bpm where zones 1–5 start; empty when no heart rate was recorded.
    var zoneThresholds: [Int] = []
    /// The recorded result, editable from the completion screen.
    var durationSeconds: Int? = nil
    var roundsCompleted: Int? = nil
    var repsCompleted: Int? = nil
    /// The rest of the workout, so it can reopen in the completion screen.
    var name: String? = nil
    var constraintType: String = ""
    var constraintMagnitude: Int = 0
    var timeCap: Int? = nil
    var heartRateSummary: HeartRateSummary? = nil

    var workout: HIITWorkoutItem {
        HIITWorkoutItem(
            id: workoutId,
            format: format,
            displayText: displayText,
            stimulus: stimulus,
            constraintType: constraintType,
            constraintMagnitude: constraintMagnitude,
            timeCap: timeCap,
            timingScheme: nil,
            tags: [],
            name: name
        )
    }

    /// The completion screen's starting point: the result as logged.
    var completionDraft: WorkoutCompletionDraft {
        var draft = WorkoutCompletionDraft(
            id: workoutId,
            workout: workout,
            capturedElapsed: TimeInterval(durationSeconds ?? 0)
        )
        draft.durationSeconds = durationSeconds
        draft.roundsCompleted = roundsCompleted
        draft.repsCompleted = repsCompleted
        draft.perceivedEffort = perceivedEffort
        return draft
    }

    /// What Save sends for an edited `draft`. Effort always goes (the slider
    /// always shows a value); a result only when it changed, so opening a
    /// result logged without a time and saving doesn't record 0:00.
    func edit(from draft: WorkoutCompletionDraft) -> HiitCompletionEdit {
        HiitCompletionEdit(
            durationSeconds: draft.durationSeconds == durationSeconds ? nil : draft.durationSeconds,
            roundsCompleted: draft.roundsCompleted == roundsCompleted ? nil : draft.roundsCompleted,
            repsCompleted: draft.repsCompleted == repsCompleted ? nil : draft.repsCompleted,
            perceivedEffort: draft.perceivedEffort
        )
    }
}

/// The fields an edit changes; nil leaves a field as it is on the server.
struct HiitCompletionEdit: Equatable {
    var durationSeconds: Int?
    var roundsCompleted: Int?
    var repsCompleted: Int?
    var perceivedEffort: Int?
}

/// One strength piece with at least one logged set.
struct CompletedStrengthEntry: Identifiable, Equatable {
    let id: Int
    let completedAt: Date
    let title: String
    /// One line per exercise, in the order they first appear (several for a superset).
    let lifts: [Lift]
    /// The whole piece, so it can reopen in StrengthWorkoutView for editing.
    var workout: StrengthWorkout? = nil

    struct Lift: Equatable {
        let exercise: String
        /// Prescribed reps of every set, in order.
        let prescribedReps: [Int]
        /// Logged sets' weights in pounds, in order; nil for a bodyweight set.
        let loggedWeights: [Double?]
    }

    /// A set as the server sends it, before grouping.
    struct Set {
        let order: Int
        let exercise: String
        let reps: Int
        let completedAt: Date?
        let completedWeight: Double?
    }

    init(id: Int, completedAt: Date, title: String, lifts: [Lift]) {
        self.id = id
        self.completedAt = completedAt
        self.title = title
        self.lifts = lifts
    }

    /// Groups `sets` by exercise. `name` is the piece's own name, if it has one.
    init(id: Int, completedAt: Date, name: String?, sets: [Set]) {
        let ordered = sets.sorted { $0.order < $1.order }
        var exercises: [String] = []
        for set in ordered where !exercises.contains(set.exercise) {
            exercises.append(set.exercise)
        }
        let lifts = exercises.map { exercise in
            let mine = ordered.filter { $0.exercise == exercise }
            return Lift(
                exercise: exercise,
                prescribedReps: mine.map(\.reps),
                loggedWeights: mine.filter { $0.completedAt != nil }.map(\.completedWeight)
            )
        }
        let title = name.flatMap { $0.isEmpty ? nil : $0 }
            ?? exercises.joined(separator: " + ")
        self.init(id: id, completedAt: completedAt, title: title.isEmpty ? "Strength" : title, lifts: lifts)
    }

    /// Builds the card from the whole piece, keeping it for editing.
    init(completedAt: Date, name: String?, workout: StrengthWorkout) {
        self.init(
            id: workout.serverId ?? workout.id,
            completedAt: completedAt,
            name: name,
            sets: workout.components.map {
                Set(
                    order: $0.order,
                    exercise: $0.exercise.name,
                    reps: $0.reps,
                    completedAt: $0.completed == nil ? nil : completedAt,
                    completedWeight: $0.completed?.weightUsed
                )
            }
        )
        self.workout = workout
    }

    /// This card after its piece was edited: same day and title, lifts from
    /// what's logged now. Nil once every set is un-checked, since the piece
    /// is no longer a completed workout.
    func updated(with workout: StrengthWorkout) -> CompletedStrengthEntry? {
        guard workout.components.contains(where: { $0.completed != nil }) else { return nil }
        return CompletedStrengthEntry(completedAt: completedAt, name: title, workout: workout)
    }
}

enum ActivityItem: Identifiable, Equatable {
    case hiit(CompletedHiitEntry)
    case strength(CompletedStrengthEntry)

    var id: String {
        switch self {
        case let .hiit(entry): return "hiit-\(entry.id)"
        case let .strength(entry): return "strength-\(entry.id)"
        }
    }

    var completedAt: Date {
        switch self {
        case let .hiit(entry): return entry.completedAt
        case let .strength(entry): return entry.completedAt
        }
    }
}

// MARK: - Grouping

struct ActivityDay: Identifiable, Equatable {
    /// Local start of the day.
    let day: Date
    /// Newest first.
    let items: [ActivityItem]
    var id: Date { day }
}

enum ActivityFeed {
    /// Only days with something on them, newest day first.
    static func days(_ items: [ActivityItem], calendar: Calendar = .current) -> [ActivityDay] {
        Dictionary(grouping: items) { calendar.startOfDay(for: $0.completedAt) }
            .map { day, items in
                ActivityDay(day: day, items: items.sorted { $0.completedAt > $1.completedAt })
            }
            .sorted { $0.day > $1.day }
    }

    /// "Today", "Yesterday", else e.g. "Tue, Oct 6".
    static func dayLabel(_ day: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEMMMd")
        return formatter.string(from: day)
    }
}

// MARK: - Strength text

enum StrengthText {
    /// The prescription's shape: "5 × 5" when every set has the same reps, else
    /// the reps in order, "5-3-3-1".
    static func scheme(_ reps: [Int]) -> String? {
        guard let first = reps.first else { return nil }
        if reps.allSatisfy({ $0 == first }) { return "\(reps.count) × \(first)" }
        return reps.map(String.init).joined(separator: "-")
    }

    /// Every logged set's load, in order: "135 → 155 → 155 → 185 lb". Sets at
    /// the same load each get their own step; bodyweight sets read "BW" (no
    /// unit when every set is bodyweight). Nil when nothing was logged.
    static func progression(_ weights: [Double?], unit: WeightUnit) -> String? {
        guard !weights.isEmpty else { return nil }
        if weights.allSatisfy({ $0 == nil }) {
            return weights.map { _ in "BW" }.joined(separator: " → ")
        }

        let text = weights.map { step -> String in
            guard let step else { return "BW" }
            return unit.format(step)
        }.joined(separator: " → ")
        return "\(text) \(unit.rawValue)"
    }
}

// MARK: - RPE

enum RPEBand: Equatable {
    case easy, moderate, hard, max

    /// Nil when the athlete didn't rate the workout.
    init?(rpe: Int?) {
        guard let rpe else { return nil }
        switch rpe {
        case ...4: self = .easy
        case 5...6: self = .moderate
        case 7...8: self = .hard
        default: self = .max
        }
    }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .max: return "Max"
        }
    }

    /// Asset catalog color, cool → hot.
    var colorName: String {
        switch self {
        case .easy: return "RPEEasy"
        case .moderate: return "RPEModerate"
        case .hard: return "RPEHard"
        case .max: return "RPEMax"
        }
    }
}
