//
//  wodAIApp.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import SwiftUI

@main
struct wodAIApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
