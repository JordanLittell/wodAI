//
//  ExerciseStatsStore.swift
//  wodAI
//
//  Per-exercise numbers for a strength block: the athlete's working 1RM, and
//  the last weight they lifted for each effort. An effort is a prescription
//  (exercise, reps, RPE), because RPE alone is relative: RPE 7 for 10 reps
//  and RPE 7 for 3 are very different loads.
//
//  Device-local for now. The backend has no per-exercise 1RM (UserBenchmark
//  is free-text types from onboarding, not linked to exercises) and doesn't
//  store logged sets yet, so both live in UserDefaults until it does.
//  Exercises are keyed by name because StrengthComponent carries no exercise
//  id; weights are stored in pounds like everything else.
//

import Foundation

@MainActor
final class ExerciseStatsStore: ObservableObject {
    static let shared = ExerciseStatsStore()

    @Published private(set) var oneRepMaxes: [String: Double]
    /// Keyed "<exercise key>|<reps>|<rpe or ->": property lists only allow
    /// string keys.
    @Published private(set) var effortWeights: [String: Double]

    private let defaults: UserDefaults
    private static let oneRepMaxKey = "exerciseStats.oneRepMax"
    private static let effortWeightsKey = "exerciseStats.effortWeight"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.oneRepMaxes = defaults.dictionary(forKey: Self.oneRepMaxKey) as? [String: Double] ?? [:]
        self.effortWeights = defaults.dictionary(forKey: Self.effortWeightsKey) as? [String: Double] ?? [:]
    }

    /// "Back Squat", "back squat " and "BACK SQUAT" are the same exercise.
    static func key(_ exercise: String) -> String {
        exercise.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func oneRepMax(for exercise: String) -> Double? {
        oneRepMaxes[Self.key(exercise)]
    }

    /// Pounds; nil or zero clears it.
    func setOneRepMax(_ pounds: Double?, for exercise: String) {
        if let pounds, pounds > 0 {
            oneRepMaxes[Self.key(exercise)] = pounds
        } else {
            oneRepMaxes[Self.key(exercise)] = nil
        }
        defaults.set(oneRepMaxes, forKey: Self.oneRepMaxKey)
    }

    /// The weight (pounds) last lifted on a set of `exercise` prescribed as
    /// `reps` at `rpe` (nil: no RPE prescribed).
    func lastWeight(for exercise: String, reps: Int, rpe: Int?) -> Double? {
        effortWeights[Self.effortKey(exercise, reps, rpe)]
    }

    func recordWeight(_ pounds: Double, for exercise: String, reps: Int, rpe: Int?) {
        effortWeights[Self.effortKey(exercise, reps, rpe)] = pounds
        defaults.set(effortWeights, forKey: Self.effortWeightsKey)
    }

    private static func effortKey(_ exercise: String, _ reps: Int, _ rpe: Int?) -> String {
        "\(key(exercise))|\(reps)|\(rpe.map(String.init) ?? "-")"
    }
}
