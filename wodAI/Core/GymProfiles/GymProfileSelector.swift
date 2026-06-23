//
//  GymProfileSelector.swift
//  wodAI
//
//  Created by Jordan Littell on 6/9/25.
//

import SwiftUI

struct GymProfileSelector: View {
    @StateObject private var profileManager = GymProfileManager.shared
    @State private var showingProfiles = false
    
    var body: some View {
        Button(action: { showingProfiles = true }) {
            HStack(spacing: 12) {
                Image(systemName: profileManager.selectedProfile?.icon ?? "building.2")
                    .font(.body)
                    .foregroundColor(Color("BrandPrimary"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                    
                    Text(profileManager.selectedProfile?.name ?? "Select Location")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("PrimaryText"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("Surface"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("Border"), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingProfiles) {
            QuickGymProfilePicker()
        }
    }
}

struct QuickGymProfilePicker: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = GymProfileManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(profileManager.profiles) { profile in
                            ProfilePickerRow(
                                profile: profile,
                                isSelected: profile.id == profileManager.selectedProfile?.id,
                                action: {
                                    profileManager.selectProfile(profile)
                                    dismiss()
                                }
                            )
                        }
                        
                        // Add New Profile Option
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color("Surface2"))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(Color("BrandPrimary"))
                                }
                                
                                Text("Add New Profile")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("BrandPrimary"))
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color("Surface"))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("Border"), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct ProfilePickerRow: View {
    let profile: GymProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("BrandPrimary").opacity(0.15) : Color("Surface2"))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: profile.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("\(profile.equipment.count) equipment types")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("Success"))
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
    }
}

// Mini selector for compact spaces
struct CompactGymProfileSelector: View {
    @StateObject private var profileManager = GymProfileManager.shared
    @State private var showingProfiles = false
    
    var body: some View {
        Button(action: { showingProfiles = true }) {
            HStack(spacing: 8) {
                Image(systemName: profileManager.selectedProfile?.icon ?? "building.2")
                    .font(.subheadline)
                
                Text(profileManager.selectedProfile?.name ?? "Select Location")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(Color("BrandPrimary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color("BrandPrimary").opacity(0.1))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingProfiles) {
            QuickGymProfilePicker()
        }
    }
}

// Preview
struct GymProfileSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GymProfileSelector()
            CompactGymProfileSelector()
        }
        .padding()
        .background(Color("Background"))
    }
}
