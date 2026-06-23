//
//  AppNavigationView.swift
//  wodAI
//

import SwiftUI

enum AppDestination {
    case workout, activity, equipment
}

struct AppNavigationView: View {
    @State private var destination: AppDestination = .workout
    @State private var showMenu: Bool
    @EnvironmentObject var authManager: AuthManager

    init(showMenu: Bool = false) {
        self._showMenu = State(initialValue: showMenu)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack {
                contentView
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showMenu = true
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3)
                                    .foregroundColor(Color("PrimaryText"))
                            }
                        }
                    }
            }

            if showMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showMenu = false
                        }
                    }
                    .zIndex(1)

                SideMenuView(destination: $destination, showMenu: $showMenu)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showMenu)
    }

    @ViewBuilder
    private var contentView: some View {
        switch destination {
        case .workout:
            HIITWorkoutView()
        case .activity:
            ActivityView()
        case .equipment:
            GymProfilesView()
        }
    }
}

struct SideMenuView: View {
    @Binding var destination: AppDestination
    @Binding var showMenu: Bool
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("wodAI")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryText"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 32)

            Divider()
                .padding(.horizontal, 16)

            // Navigation items
            VStack(alignment: .leading, spacing: 4) {
                MenuRow(
                    icon: "bolt.heart.fill",
                    label: "Workout",
                    isSelected: destination == .workout
                ) {
                    navigate(to: .workout)
                }

                MenuRow(
                    icon: "clock.arrow.circlepath",
                    label: "Activity",
                    isSelected: destination == .activity
                ) {
                    navigate(to: .activity)
                }

                MenuRow(
                    icon: "dumbbell.fill",
                    label: "Equipment",
                    isSelected: destination == .equipment
                ) {
                    navigate(to: .equipment)
                }
            }
            .padding(.top, 16)

            Spacer()

            Divider()
                .padding(.horizontal, 16)

            // Sign Out
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showMenu = false
                }
                authManager.signOut()
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                        .frame(width: 24)
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color("Error"))
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .padding(.bottom, 32)
        }
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(Color("Surface"))
        .edgesIgnoringSafeArea(.vertical)
    }

    private func navigate(to dest: AppDestination) {
        withAnimation(.easeInOut(duration: 0.25)) {
            showMenu = false
        }
        destination = dest
    }
}

private struct MenuRow: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
                    .frame(width: 24)

                Text(label)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color("PrimaryText") : Color("SecondaryText"))

                Spacer()

                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color("BrandPrimary"))
                        .frame(width: 4, height: 20)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? Color("BrandPrimary").opacity(0.08)
                    : Color.clear
            )
            .cornerRadius(12)
            .padding(.horizontal, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Workout destination") {
    AppNavigationView()
        .environmentObject(AuthManager())
}

#Preview("Menu open") {
    AppNavigationView(showMenu: true)
        .environmentObject(AuthManager())
}
