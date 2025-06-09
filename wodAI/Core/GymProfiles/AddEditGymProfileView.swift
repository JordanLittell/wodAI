//
//  AddEditGymProfileView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/9/25.
//

import SwiftUI

struct AddEditGymProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = GymProfileManager.shared
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "building.2.fill"
    @State private var selectedEquipment: Set<EquipmentOption> = []
    @State private var showingDeleteAlert = false
    
    let profile: GymProfile?
    
    init(profile: GymProfile? = nil) {
        self.profile = profile
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Info Section
                        VStack(spacing: 20) {
                            // Icon Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Icon")
                                    .font(.headline)
                                    .foregroundColor(Color("PrimaryText"))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(GymProfileIcon.icons, id: \.self) { icon in
                                            IconOption(
                                                icon: icon,
                                                isSelected: selectedIcon == icon,
                                                action: { selectedIcon = icon }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 1)
                                }
                            }
                            
                            // Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Profile Name")
                                    .font(.headline)
                                    .foregroundColor(Color("PrimaryText"))
                                
                                TextField("e.g., Home Gym", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                        .padding()
                        .background(Color("Surface"))
                        .cornerRadius(16)
                        
                        // Equipment Selection
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Available Equipment")
                                    .font(.headline)
                                    .foregroundColor(Color("PrimaryText"))
                                
                                Spacer()
                                
                                Text("\(selectedEquipment.count) selected")
                                    .font(.subheadline)
                                    .foregroundColor(Color("SecondaryText"))
                            }
                            
                            // Quick Actions
                            HStack(spacing: 12) {
                                Button(action: selectAll) {
                                    Text("Select All")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("BrandPrimary"))
                                }
                                
                                Text("•")
                                    .foregroundColor(Color("TertiaryText"))
                                
                                Button(action: deselectAll) {
                                    Text("Clear All")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("BrandPrimary"))
                                }
                                
                                Spacer()
                            }
                            
                            // Equipment Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(EquipmentOption.allCases, id: \.self) { equipment in
                                    EquipmentOptionView(
                                        equipment: equipment,
                                        isSelected: selectedEquipment.contains(equipment),
                                        action: { toggleEquipment(equipment) }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color("Surface"))
                        .cornerRadius(16)
                        
                        // Delete Button (only for editing)
                        if profile != nil {
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Profile")
                                }
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Surface"))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(profile == nil ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            if let profile = profile {
                name = profile.name
                selectedIcon = profile.icon
                selectedEquipment = profile.equipment
            }
        }
        .alert("Delete Profile", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let profile = profile {
                    profileManager.deleteProfile(profile)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this profile? This action cannot be undone.")
        }
    }
    
    private func toggleEquipment(_ equipment: EquipmentOption) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }
    
    private func selectAll() {
        selectedEquipment = Set(EquipmentOption.allCases)
    }
    
    private func deselectAll() {
        selectedEquipment.removeAll()
    }
    
    private func saveProfile() {
        if let existingProfile = profile {
            var updatedProfile = existingProfile
            updatedProfile.name = name
            updatedProfile.icon = selectedIcon
            updatedProfile.equipment = selectedEquipment
            profileManager.updateProfile(updatedProfile)
        } else {
            let newProfile = GymProfile(
                name: name,
                icon: selectedIcon,
                equipment: selectedEquipment
            )
            profileManager.addProfile(newProfile)
        }
        dismiss()
    }
}

struct IconOption: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color("BrandPrimary").opacity(0.15) : Color("Surface2"))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color("BrandPrimary") : Color("Border"), lineWidth: isSelected ? 2 : 1)
                    )
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
            }
        }
    }
}

struct EquipmentOptionView: View {
    let equipment: EquipmentOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: equipment.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
                    .frame(width: 24)
                
                Text(equipment.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color("PrimaryText") : Color("SecondaryText"))
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Color("Success") : Color("TertiaryText"))
            }
            .padding()
            .background(isSelected ? Color("BrandPrimary").opacity(0.08) : Color("Surface2"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("BrandPrimary") : Color("Border"), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color("Surface2"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("Border"), lineWidth: 1)
            )
            .foregroundColor(Color("PrimaryText"))
    }
}

// Preview
struct AddEditGymProfileView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditGymProfileView()
    }
}
