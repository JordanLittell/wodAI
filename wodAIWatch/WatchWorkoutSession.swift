//
//  WatchWorkoutSession.swift
//  wodAI Watch
//
//  Owns the HKWorkoutSession + HKLiveWorkoutBuilder. Two jobs:
//   1. Publish live heart rate for the HR screen and for stamping onto sensor frames.
//   2. Hold an active workout session so watchOS keeps the app running screen-off and
//      keeps the optical HR sensor sampling (HR via HKLiveWorkoutBuilder is "free" while
//      a workout is active).
//

import Foundation
import HealthKit
import Combine

final class WatchWorkoutSession: NSObject, ObservableObject {
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var isAuthorized = false

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private let heartRateType = HKQuantityType(.heartRate)
    private let bpmUnit = HKUnit.count().unitDivided(by: .minute())

    /// Request HealthKit permission. Safe to call on launch.
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set = [HKQuantityType.workoutType()]
        let read: Set = [heartRateType, HKQuantityType(.activeEnergyBurned)]
        do {
            try await healthStore.requestAuthorization(toShare: share, read: read)
            await MainActor.run { self.isAuthorized = true }
        } catch {
            // Non-fatal: a session can still run without HR (frames just carry nil HR).
            print("⚠️ HealthKit authorization failed: \(error)")
        }
    }

    /// Begin an indoor functional-training workout. Call as the pre-roll countdown starts
    /// so HR is warm by the time the main timer begins.
    func start() {
        let config = HKWorkoutConfiguration()
        config.activityType = .functionalStrengthTraining
        config.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self

            self.session = session
            self.builder = builder

            let startDate = Date()
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { _, error in
                if let error { print("⚠️ beginCollection error: \(error)") }
            }
        } catch {
            print("⚠️ Failed to start HKWorkoutSession: \(error)")
        }
    }

    /// End the workout and finalize the builder.
    func stop() {
        guard let session, let builder else { return }
        let end = Date()
        session.end()
        builder.endCollection(withEnd: end) { [weak self] _, _ in
            builder.finishWorkout { _, _ in }
            self?.session = nil
            self?.builder = nil
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutSession: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("⚠️ Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutSession: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard collectedTypes.contains(heartRateType),
              let stats = workoutBuilder.statistics(for: heartRateType),
              let value = stats.mostRecentQuantity()?.doubleValue(for: bpmUnit) else { return }
        DispatchQueue.main.async { self.heartRate = value }
    }
}
