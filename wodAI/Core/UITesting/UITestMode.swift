//
//  UITestMode.swift
//  wodAI
//
//  Launching with `-uiTesting` (wodAIUITests) runs the app without a server:
//  a stand-in athlete is signed in and the Workout page reads fixtures.
//  Debug builds only.
//

#if DEBUG
import UIKit

enum UITestMode {
    static let isActive = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    /// Signs in a stand-in athlete, so the app opens on the Workout page,
    /// and turns off animations so the tests don't wait on them.
    static func configure() {
        UIView.setAnimationsEnabled(false)
        AuthState.shared.currentToken = "ui-test"
        // Not `isProvisioned = true`: its sink reads the old value, which
        // would leave a fresh install in onboarding.
        AuthState.shared.completeProvisioning()
    }
}

extension AssistantViewModel {
    /// Weeks within two of this one have a session every day, named by the
    /// week's offset from this one and the day's place in it ("W-1 D3"), so
    /// tests read the same whatever today, the locale's first weekday, or
    /// the time zone. Weeks further out are empty.
    static func uiTesting() -> AssistantViewModel {
        let viewModel = AssistantViewModel()
        let current = viewModel.currentWeek
        viewModel.weekSessions = { week in
            let offset = current.calendar.dateComponents([.weekOfYear], from: current.first, to: week.first).weekOfYear ?? 0
            guard abs(offset) <= 2 else { return [] }
            return week.days.enumerated().map { index, day in
                AssistantSession(
                    id: "ui-test-\(offset)-\(index)",
                    name: "W\(offset) D\(index)",
                    description: "",
                    stimulus: nil,
                    coaching: nil,
                    scheduledDate: day,
                    blocks: []
                )
            }
        }
        viewModel.planStatus = { nil }
        viewModel.deleteWorkout = { _ in }
        viewModel.sessionProgressed = { _, _ in }
        return viewModel
    }
}
#endif
