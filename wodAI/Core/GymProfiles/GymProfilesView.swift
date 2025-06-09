//
//  GymProfilesView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/9/25.
//

import SwiftUI

struct GymProfilesView: View {
    @StateObject private var profileManager = GymProfileManager.shared
    @State private var showingAddProfile = false
    @State private var profileToEdit: GymProfile?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                if profileManager.profiles.isEmpty {
                    EmptyStateView()
                } else {
                    ProfilesList()
                }
            }
            .navigationTitle("Equipment Setup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProfile = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("BrandPrimary"))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProfile) {
            AddEditGymProfileView()
        }
        .sheet(item: $profileToEdit) { profile in
            AddEditGymProfileView(profile: profile)
        }
    }
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(Color("TertiaryText"))
            
            VStack(spacing: 8) {
                Text("No Equipment Profiles")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                
                Text("Create profiles for different workout locations with their available equipment")
                    .font(.body)
                    .foregroundColor(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddProfile = true }) {
                Label("Add First Profile", systemImage: "plus")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color("BrandPrimary"))
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func ProfilesList() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Selected Profile Section
                if let selectedProfile = profileManager.selectedProfile {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Profile")
                            .font(.headline)
                            .foregroundColor(Color("SecondaryText"))
                            .padding(.horizontal)
                        
                        ProfileCard(
                            profile: selectedProfile,
                            isSelected: true,
                            onTap: { },
                            onEdit: { profileToEdit = selectedProfile }
                        )
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                
                // Other Profiles
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Profiles")
                        .font(.headline)
                        .foregroundColor(Color("SecondaryText"))
                        .padding(.horizontal)
                    
                    ForEach(profileManager.profiles) { profile in
                        if profile.id != profileManager.selectedProfile?.id {
                            ProfileCard(
                                profile: profile,
                                isSelected: false,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        profileManager.selectProfile(profile)
                                    }
                                },
                                onEdit: { profileToEdit = profile }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, profileManager.selectedProfile == nil ? 16 : 0)
            }
            .padding(.bottom, 100)
        }
    }
}

struct ProfileCard: View {
    let profile: GymProfile
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("BrandPrimary").opacity(0.15) : Color("Surface2"))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: profile.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("\(profile.equipment.count) equipment types")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("Success"))
                    }
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("SecondaryText"))
                    }
                }
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("BrandPrimary") : Color("Border"), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct GymProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        GymProfilesView()
    }
}
