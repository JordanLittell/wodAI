//
//  wodAIApp.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI
import SwiftData

@main
struct wodAIApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(workout: WorkoutFixture.workout)
        }
    }
}

#Preview {
    HomeView(workout: WorkoutFixture.workout)
}
