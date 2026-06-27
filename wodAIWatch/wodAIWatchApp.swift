//
//  wodAIWatchApp.swift
//  wodAI Watch
//
//  watchOS entry point. Owns the single `WatchSessionCoordinator` and routes to the
//  execution UI once the phone sends a workout.
//
//  NOTE: when you add the Watch App target in Xcode it generates its own `…App.swift`
//  + `ContentView.swift`. Replace the generated `@main` app with this file (and delete
//  the generated ContentView) so there is exactly one `@main`.
//

import SwiftUI

@main
struct wodAIWatch_Watch_AppApp: App {
    @StateObject private var coordinator = WatchSessionCoordinator()

    var body: some Scene {
        WindowGroup {
            WatchRootView(coordinator: coordinator)
                .onAppear { coordinator.activate() }
        }
    }
}

struct WatchRootView: View {
    @ObservedObject var coordinator: WatchSessionCoordinator

    var body: some View {
        if let engine = coordinator.engine {
            WatchExecutionView(engine: engine,
                               workout: coordinator.workout,
                               motion: coordinator.motion)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Ready")
                    .font(.headline)
                Text("Start a workout in wodAI on your phone.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
