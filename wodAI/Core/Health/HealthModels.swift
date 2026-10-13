//
//  HealthModels.swift
//  wodAI
//
//  What the app reads from Apple Health and what it writes back, as plain
//  values. HealthKit-free and Apollo-free, so the summaries and timing are
//  unit-tested (wodAITests/HealthModelsTests.swift).
//

import Foundation

/// What a 90-day workout counts as when suggesting a level. Walks are left
/// out of cardio: a watch logs plenty, and they say little about an engine.
enum HealthWorkoutCategory: Equatable {
    case cardio, strength, other
}

/// One workout from Apple Health, as the summary needs it.
struct HealthWorkoutRecord: Equatable {
    let start: Date
    /// A short name for the type, e.g. "running".
    let activityName: String
    let category: HealthWorkoutCategory
    /// The highest heart rate in the workout, when it recorded one.
    let maxHeartRate: Double?
}

/// The last 90 days of workouts, summarized on the device. Only this is
/// uploaded; individual workouts stay on the phone.
struct WorkoutHistorySummary: Equatable {
    static let weeks = 13
    static let topActivityLimit = 5

    var workoutCount = 0
    var workoutsPerWeek = 0.0
    var cardioPerWeek = 0.0
    var strengthPerWeek = 0.0
    /// Of the last 13 weeks, how many had at least one workout.
    var activeWeeks = 0
    /// Most frequent first.
    var topActivityTypes: [String] = []
    /// The highest heart rate seen in any of them.
    var maxHeartRate: Double?

    init() {}

    /// Summarizes `workouts`, counting only those in the 13 weeks before `now`.
    init(_ workouts: [HealthWorkoutRecord], now: Date) {
        let windowStart = now.addingTimeInterval(-Double(Self.weeks) * 7 * 86_400)
        let recent = workouts.filter { $0.start >= windowStart && $0.start <= now }
        let weeks = Double(Self.weeks)

        workoutCount = recent.count
        workoutsPerWeek = Double(recent.count) / weeks
        cardioPerWeek = Double(recent.filter { $0.category == .cardio }.count) / weeks
        strengthPerWeek = Double(recent.filter { $0.category == .strength }.count) / weeks
        // Week 0 is the last 7 days; a workout exactly 13 weeks back counts in the oldest week.
        activeWeeks = Set(recent.map { min(Int(now.timeIntervalSince($0.start) / (7 * 86_400)), Self.weeks - 1) }).count
        maxHeartRate = recent.compactMap(\.maxHeartRate).max()

        let counts = Dictionary(recent.map { ($0.activityName, 1) }, uniquingKeysWith: +)
        topActivityTypes = counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(Self.topActivityLimit)
            .map(\.key)
    }
}

/// Everything read from Apple Health in one pass. Each value is nil when
/// Health has none, or the athlete didn't share it (iOS doesn't say which).
struct HealthSnapshot: Equatable {
    var dateOfBirth: DateComponents?
    var biologicalSex: OnboardingSex?
    var heightInches: Double?
    var weightPounds: Double?
    var vo2Max: Double?
    /// 30-day averages.
    var restingHeartRate: Double?
    var hrvMs: Double?
    var dailySteps: Double?
    var workouts = WorkoutHistorySummary()

    /// Whole years old on `date`.
    func age(on date: Date, calendar: Calendar = .current) -> Int? {
        guard let dateOfBirth, let birthday = calendar.date(from: dateOfBirth) else { return nil }
        return calendar.dateComponents([.year], from: birthday, to: date).year
    }

    /// True when nothing came back: no data, or no access.
    var isEmpty: Bool {
        dateOfBirth == nil && biologicalSex == nil && heightInches == nil && weightPounds == nil
            && vo2Max == nil && restingHeartRate == nil && hrvMs == nil && dailySteps == nil
            && workouts.workoutCount == 0
    }
}

/// The starting level the server suggested, and why.
struct HealthSuggestion: Equatable {
    let level: OnboardingLevel
    let reasons: [String]
}

/// The levels the app offers an athlete to confirm, mirroring the API's
/// FitnessLevel (never PRO, which isn't suggested or offered).
enum OnboardingLevel: String, CaseIterable, Equatable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"
    case elite = "ELITE"

    var title: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .elite: return "Elite"
        }
    }
}

// MARK: - Writing a session

/// What a finished session's Health workout records.
struct SessionWorkoutPlan: Equatable {
    enum Activity: Equatable {
        case strength, hiit, mixed
    }

    /// Shortest workout written, so a session of one logged set still has a length.
    static let minimumDuration: TimeInterval = 60

    let activity: Activity
    let start: Date
    let end: Date

    /// When the work was done: the first set logged (or a metcon's start,
    /// its result time less its duration) to the last thing logged. Nil when
    /// nothing in the session was logged.
    init?(setTimes: [Date], hiitResults: [(completedAt: Date, durationSeconds: Int?)]) {
        let hiitStarts = hiitResults.map { $0.completedAt.addingTimeInterval(-Double($0.durationSeconds ?? 0)) }
        let ends = setTimes + hiitResults.map(\.completedAt)
        guard let end = ends.max(), let first = (setTimes + hiitStarts).min() else { return nil }

        switch (setTimes.isEmpty, hiitResults.isEmpty) {
        case (false, false): activity = .mixed
        case (true, false): activity = .hiit
        default: activity = .strength
        }
        self.end = end
        start = min(first, end.addingTimeInterval(-Self.minimumDuration))
    }
}
