//
//  GymProfilesView.swift
//  wodAI

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

                if profileManager.isLoading && profileManager.profiles.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color("BrandPrimary"))
                        Text("Loading profiles...")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                    }
                } else if profileManager.profiles.isEmpty {
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
        .onAppear {
            profileManager.loadProfiles()
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
                if let activeProfile = profileManager.activeProfile {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Profile")
                            .font(.headline)
                            .foregroundColor(Color("SecondaryText"))
                            .padding(.horizontal)

                        ProfileCard(
                            profile: activeProfile,
                            isActive: true,
                            isToggling: profileManager.togglingId == activeProfile.id,
                            onTap: { profileManager.toggleActive(id: activeProfile.id) { _ in } },
                            onEdit: { profileToEdit = activeProfile }
                        )
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("All Profiles")
                        .font(.headline)
                        .foregroundColor(Color("SecondaryText"))
                        .padding(.horizontal)

                    ForEach(profileManager.profiles) { profile in
                        if !profile.isActive {
                            ProfileCard(
                                profile: profile,
                                isActive: false,
                                isToggling: profileManager.togglingId == profile.id,
                                onTap: { profileManager.toggleActive(id: profile.id) { _ in } },
                                onEdit: { profileToEdit = profile }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, profileManager.activeProfile == nil ? 16 : 0)
            }
            .padding(.bottom, 100)
        }
    }
}

struct ProfileCard: View {
    let profile: GymProfile
    let isActive: Bool
    let isToggling: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color("BrandPrimary").opacity(0.15) : Color("Surface2"))
                        .frame(width: 50, height: 50)

                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundColor(isActive ? Color("BrandPrimary") : Color("SecondaryText"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))

                    Text("\(profile.equipment.count) equipment types")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }

                Spacer()

                HStack(spacing: 12) {
                    if isToggling {
                        ProgressView()
                            .tint(Color("BrandPrimary"))
                    } else if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("Success"))
                    }

                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    .disabled(isToggling)
                }
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color("BrandPrimary") : Color("Border"), lineWidth: isActive ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isToggling)
    }
}

struct GymProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        GymProfilesView()
    }
}
