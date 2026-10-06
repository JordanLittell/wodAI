//
//  PlanWait.swift
//  wodAI
//
//  What the "planning your week" screen shows, from the latest planning run
//  and how long the athlete has waited. Apollo-free and tested in
//  wodAITests/OnboardingViewModelTests.swift.
//

import Foundation

enum PlanWait: Equatable {
    /// Still planning. `slow` once it's taken longer than usual, which offers
    /// a way into the app while the server keeps going.
    case waiting(slow: Bool)
    /// Today is planned (or the run finished without it): show the app.
    case ready
    /// Planning stopped before today was planned.
    case failed(String)

    /// After this long the screen offers to continue without waiting.
    static let slowAfter: TimeInterval = 90

    static func from(_ status: PlanStatus?, today: String, waited: TimeInterval) -> PlanWait {
        guard let status else { return .waiting(slow: waited > slowAfter) }
        if status.plannedDates.contains(today) { return .ready }
        switch status.state {
        case .done:
            return .ready
        case .failed:
            return .failed(status.message ?? "We couldn't plan your week right now.")
        case .running:
            return .waiting(slow: waited > slowAfter)
        }
    }
}
