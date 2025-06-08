//
//  ContentView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager;
    
    @Query private var items: [Item]

    var body: some View {
        if authManager.isLoggedIn {
            HomeView()
                .environmentObject(WorkoutGeneratorViewModel(generating: false, workout: WorkoutFixture.workout))
        } else {
            AuthenticationView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(AuthManager())
}
