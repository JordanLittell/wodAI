//
//  HealthStore.swift
//  wodAI
//
//  The only file that talks to HealthKit. Reads one snapshot for onboarding
//  and the Apple Health screen, and writes a finished workout. Every query
//  runs at once and reads the phone's own database, so a read takes well
//  under a second; no per-workout queries (each HKWorkout already carries its
//  heart-rate statistics).
//
//  iOS never says whether the athlete denied a read: denied looks exactly
//  like no data, and both come back as nil.
//

import Foundation
import HealthKit

/// One finished workout to save to Health.
struct HealthWorkoutWrite: Equatable {
    /// Health keeps one workout per sync identifier from this app, replacing
    /// it when a higher version is saved, so a write can safely repeat.
    let syncIdentifier: String
    let syncVersion: Int
    let activity: SessionWorkoutPlan.Activity
    let start: Date
    let end: Date
    let title: String
    /// Heart rate recorded by a Bluetooth device during the workout.
    var heartRate: [(date: Date, bpm: Double)] = []
    var activeEnergyKcal: Double?

    static func == (lhs: HealthWorkoutWrite, rhs: HealthWorkoutWrite) -> Bool {
        lhs.syncIdentifier == rhs.syncIdentifier && lhs.syncVersion == rhs.syncVersion
            && lhs.activity == rhs.activity && lhs.start == rhs.start && lhs.end == rhs.end
            && lhs.title == rhs.title && lhs.activeEnergyKcal == rhs.activeEnergyKcal
            && lhs.heartRate.map(\.date) == rhs.heartRate.map(\.date)
            && lhs.heartRate.map(\.bpm) == rhs.heartRate.map(\.bpm)
    }
}

enum HealthWriteOutcome: Equatable {
    case saved
    /// Another app (an Apple Watch workout, say) already has a workout at
    /// that time; a second would double-count the athlete's rings.
    case skippedOverlap
    case notAllowed
}

protocol HealthDataSource {
    var isAvailable: Bool { get }
    /// Shows the system sheet the first time; reads and writes in one ask.
    func requestAuthorization() async throws
    func readSnapshot(now: Date) async -> HealthSnapshot
    var canWriteWorkouts: Bool { get }
    func save(_ workout: HealthWorkoutWrite) async throws -> HealthWriteOutcome
}

final class HealthKitDataSource: HealthDataSource {
    static let shared = HealthKitDataSource()

    private let store = HKHealthStore()

    private static let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
    private static let vo2MaxUnit = HKUnit(from: "ml/kg*min")

    private static let readTypes: Set<HKObjectType> = [
        HKCharacteristicType(.dateOfBirth),
        HKCharacteristicType(.biologicalSex),
        HKQuantityType(.height),
        HKQuantityType(.bodyMass),
        HKQuantityType(.vo2Max),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.stepCount),
        HKQuantityType(.heartRate),
        HKObjectType.workoutType(),
    ]

    private static let writeTypes: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
    ]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes)
    }

    var canWriteWorkouts: Bool {
        isAvailable && store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    // MARK: - Reading

    func readSnapshot(now: Date) async -> HealthSnapshot {
        let lastMonth = HKQuery.predicateForSamples(withStart: now.addingTimeInterval(-30 * 86_400), end: now)
        let window = HKQuery.predicateForSamples(
            withStart: now.addingTimeInterval(-Double(WorkoutHistorySummary.weeks) * 7 * 86_400),
            end: now
        )

        async let height = latest(.height, unit: .inch())
        async let weight = latest(.bodyMass, unit: .pound())
        async let vo2Max = latest(.vo2Max, unit: Self.vo2MaxUnit)
        async let resting = average(.restingHeartRate, unit: Self.heartRateUnit, predicate: lastMonth)
        async let hrv = average(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), predicate: lastMonth)
        async let steps = sum(.stepCount, unit: .count(), predicate: lastMonth)
        async let workouts = workouts(matching: window)

        var snapshot = HealthSnapshot()
        snapshot.dateOfBirth = try? store.dateOfBirthComponents()
        snapshot.biologicalSex = (try? store.biologicalSex()).flatMap { Self.sex($0.biologicalSex) }
        snapshot.heightInches = await height
        snapshot.weightPounds = await weight
        snapshot.vo2Max = await vo2Max
        snapshot.restingHeartRate = await resting
        snapshot.hrvMs = await hrv
        snapshot.dailySteps = await steps.map { $0 / 30 }
        snapshot.workouts = WorkoutHistorySummary(await workouts, now: now)
        return snapshot
    }

    private func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let query = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(id))],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        return (try? await query.result(for: store))?.first?.quantity.doubleValue(for: unit)
    }

    private func average(_ id: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate) async -> Double? {
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(id), predicate: predicate),
            options: .discreteAverage
        )
        return (try? await query.result(for: store))??.averageQuantity()?.doubleValue(for: unit)
    }

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate) async -> Double? {
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(id), predicate: predicate),
            options: .cumulativeSum
        )
        let total = (try? await query.result(for: store))??.sumQuantity()?.doubleValue(for: unit)
        return total.flatMap { $0 > 0 ? $0 : nil }
    }

    /// Workouts from other apps and devices; ours are left out so what we
    /// write never comes back as outside training.
    private func workouts(matching predicate: NSPredicate) async -> [HealthWorkoutRecord] {
        let query = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 500
        )
        let ownBundle = Bundle.main.bundleIdentifier
        let heartRate = HKQuantityType(.heartRate)
        return ((try? await query.result(for: store)) ?? [])
            .filter { $0.sourceRevision.source.bundleIdentifier != ownBundle }
            .map { workout in
                let kind = HealthActivity.describe(workout.workoutActivityType)
                return HealthWorkoutRecord(
                    start: workout.startDate,
                    activityName: kind.name,
                    category: kind.category,
                    maxHeartRate: workout.statistics(for: heartRate)?.maximumQuantity()?.doubleValue(for: Self.heartRateUnit)
                )
            }
    }

    private static func sex(_ sex: HKBiologicalSex) -> OnboardingSex? {
        switch sex {
        case .male: return .male
        case .female: return .female
        case .other: return .other
        default: return nil
        }
    }

    // MARK: - Writing

    func save(_ workout: HealthWorkoutWrite) async throws -> HealthWriteOutcome {
        guard canWriteWorkouts else { return .notAllowed }
        if try await hasOtherWorkout(from: workout.start, to: workout.end) { return .skippedOverlap }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = HealthActivity.activityType(for: workout.activity)
        configuration.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())

        try await builder.beginCollection(at: workout.start)
        var samples: [HKSample] = workout.heartRate
            .filter { $0.date >= workout.start && $0.date <= workout.end }
            .map {
                HKQuantitySample(
                    type: HKQuantityType(.heartRate),
                    quantity: HKQuantity(unit: Self.heartRateUnit, doubleValue: $0.bpm),
                    start: $0.date,
                    end: $0.date
                )
            }
        if let kcal = workout.activeEnergyKcal, kcal > 0 {
            samples.append(HKQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                start: workout.start,
                end: workout.end
            ))
        }
        if !samples.isEmpty { try await builder.addSamples(samples) }
        try await builder.addMetadata([
            HKMetadataKeySyncIdentifier: workout.syncIdentifier,
            HKMetadataKeySyncVersion: workout.syncVersion,
            HKMetadataKeyWorkoutBrandName: "wodAI",
            HealthActivity.titleMetadataKey: workout.title,
        ])
        try await builder.endCollection(at: workout.end)
        _ = try await builder.finishWorkout()
        return .saved
    }

    /// Whether another app saved a workout overlapping [start, end].
    private func hasOtherWorkout(from start: Date, to end: Date) async throws -> Bool {
        let query = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: start, end: end))],
            sortDescriptors: [],
            limit: 20
        )
        let ownBundle = Bundle.main.bundleIdentifier
        return try await query.result(for: store).contains { $0.sourceRevision.source.bundleIdentifier != ownBundle }
    }
}

/// How HealthKit's workout types map to what the app uses. Pure, so it's tested.
enum HealthActivity {
    static let titleMetadataKey = "WODAITitle"

    static func activityType(for activity: SessionWorkoutPlan.Activity) -> HKWorkoutActivityType {
        switch activity {
        case .strength: return .traditionalStrengthTraining
        case .hiit: return .highIntensityIntervalTraining
        case .mixed: return .functionalStrengthTraining
        }
    }

    static func describe(_ type: HKWorkoutActivityType) -> (name: String, category: HealthWorkoutCategory) {
        switch type {
        case .running: return ("running", .cardio)
        case .cycling: return ("cycling", .cardio)
        case .rowing: return ("rowing", .cardio)
        case .swimming: return ("swimming", .cardio)
        case .hiking: return ("hiking", .cardio)
        case .elliptical: return ("elliptical", .cardio)
        case .stairClimbing, .stairs, .stepTraining: return ("stairs", .cardio)
        case .crossCountrySkiing: return ("skiing", .cardio)
        case .jumpRope: return ("jump rope", .cardio)
        case .highIntensityIntervalTraining: return ("HIIT", .cardio)
        case .mixedCardio, .cardioDance, .kickboxing, .boxing: return ("cardio", .cardio)
        case .traditionalStrengthTraining: return ("strength training", .strength)
        case .functionalStrengthTraining, .crossTraining: return ("functional training", .strength)
        case .coreTraining: return ("core training", .strength)
        case .walking: return ("walking", .other)
        case .yoga: return ("yoga", .other)
        case .pilates: return ("pilates", .other)
        default: return ("other", .other)
        }
    }
}
