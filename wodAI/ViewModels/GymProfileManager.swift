//
//  GymProfileManager.swift
//  wodAI
//
//  Created by Jordan Littell on 6/9/25.
//

import Foundation
import SwiftUI

class GymProfileManager: ObservableObject {
    static let shared = GymProfileManager()
    
    @Published private(set) var profiles: [GymProfile] = []
    @Published private(set) var selectedProfile: GymProfile?
    
    private let userDefaults = UserDefaults.standard
    private let profilesKey = "gymProfiles"
    private let selectedProfileKey = "selectedGymProfile"
    
    private init() {
        loadProfiles()
    }
    
    // MARK: - Public Methods
    
    var selectedEquipment: Set<Equipment> {
        selectedProfile?.equipment ?? []
    }
    
    func loadProfiles() {
        // Try to load saved profiles
        if let data = userDefaults.data(forKey: profilesKey),
           let savedProfiles = try? JSONDecoder().decode([GymProfile].self, from: data) {
            profiles = savedProfiles
        } else {
            // Load default profiles on first launch
            saveProfiles()
        }
        
        // Load selected profile
        if let selectedId = userDefaults.string(forKey: selectedProfileKey),
           let uuid = UUID(uuidString: selectedId),
           let profile = profiles.first(where: { $0.id == uuid }) {
            selectedProfile = profile
        } else if let firstProfile = profiles.first {
            // Select the first profile by default
            selectProfile(firstProfile)
        }
    }
    
    func addProfile(_ profile: GymProfile) {
        profiles.append(profile)
        saveProfiles()
    }
    
    func updateProfile(_ profile: GymProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updatedProfile = profile
            updatedProfile.updatedAt = Date()
            profiles[index] = updatedProfile
            
            // Update selected profile if it's the one being updated
            if selectedProfile?.id == profile.id {
                selectedProfile = updatedProfile
            }
            
            saveProfiles()
        }
    }
    
    func deleteProfile(_ profile: GymProfile) {
        profiles.removeAll { $0.id == profile.id }
        
        // If we deleted the selected profile, select another one
        if selectedProfile?.id == profile.id {
            if let firstProfile = profiles.first {
                selectProfile(firstProfile)
            } else {
                selectedProfile = nil
            }
        }
        
        saveProfiles()
    }
    
    func selectProfile(_ profile: GymProfile) {
        // Deselect all profiles
        for i in profiles.indices {
            profiles[i].isSelected = false
        }
        
        // Select the new profile
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index].isSelected = true
            selectedProfile = profiles[index]
            userDefaults.set(profile.id.uuidString, forKey: selectedProfileKey)
        }
        
        saveProfiles()
    }
    
    func duplicateProfile(_ profile: GymProfile) {
        let newProfile = GymProfile(
            name: "\(profile.name) Copy",
            icon: profile.icon,
            equipment: profile.equipment,
            isSelected: false
        )
        addProfile(newProfile)
    }
    
    // MARK: - Private Methods
    
    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            userDefaults.set(data, forKey: profilesKey)
        }
    }
}
