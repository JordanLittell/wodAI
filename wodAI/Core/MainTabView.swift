//
//  MainTabView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//


import SwiftUI

extension Notification.Name {
    static let navigateToTab = Notification.Name("navigateToTab")
    static let authenticationRequired = Notification.Name("authenticationRequired")
    static let tokenExpired = Notification.Name("tokenExpired")
    static let gymProfileChanged = Notification.Name("gymProfileChanged")
    static let workoutStarted = Notification.Name("workoutStarted")
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @ObservedObject private var sessionManager = WODSessionManager.shared
    @State private var selectedTab: AppTab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            WeeklyWorkoutView()
                .tabItem {
                    Image(systemName: selectedTab == .workouts ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(AppTab.home)
            
            // Home view is workouts view
            WorkoutsView()
                .tabItem {
                    Image(systemName: selectedTab == .workouts ? "dumbbell.fill" : "dumbbell")
                    Text("Workouts")
                }
                .tag(AppTab.workouts)
            
            // Setup Tab
            GymProfilesView()
                .tabItem {
                    Image(systemName: selectedTab == .setup ? "gearshape.fill" : "gearshape")
                    Text("Setup")
                }
                .tag(AppTab.setup)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(AppTab.profile)
        }
        .accentColor(.blue)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
            if let tab = notification.object as? AppTab {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = tab
                }
            }
        }
    }
}

// MARK: - App Tab Enum
enum AppTab: String, CaseIterable {
    case home = "home"
    case calendar = "calendar"
    case workouts = "workouts"
    case setup = "setup"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .workouts: return "Workouts"
        case .setup: return "Setup"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .calendar: return "calendar.circle"
        case .workouts: return "dumbbell"
        case .setup: return "gearshape"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar.circle.fill"
        case .workouts: return "dumbbell.fill"
        case .setup: return "gearshape.fill"
        case .profile: return "person.fill"
        }
    }
}
