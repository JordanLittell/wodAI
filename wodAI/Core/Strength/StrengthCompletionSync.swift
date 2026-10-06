//
//  StrengthCompletionSync.swift
//  wodAI
//

import Foundation

/// One set's result as sent to the server. Weight is pounds; nil is bodyweight.
struct StrengthSetResult: Equatable {
    let componentId: Int
    let reps: Int
    let weight: Double?
    let rpe: Int?
}

enum StrengthCompletionSyncError: Error {
    case graphQL(String)
}

/// Test seam for StrengthWorkoutViewModel's server writes. The app passes
/// nil and the view model sends the Apollo mutations itself.
protocol StrengthCompletionSyncing {
    func complete(strengthWorkoutId: Int, sets: [StrengthSetResult]) async throws
    func uncomplete(strengthWorkoutId: Int, componentIds: [Int]) async throws
}
