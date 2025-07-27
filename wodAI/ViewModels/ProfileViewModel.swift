//
//  ProfileViewModel.swift
//  wodAI
//
//  Created by Jordan Littell on 4/26/25.
//

import WodAiAPI
import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // Published properties for the view
    @Published var weight: WodAiAPI.WeightUnit = .lbs
    @Published var weightValue: Double = 150
    
    @Published var height: WodAiAPI.HeightUnit = .inches
    @Published var heightValue: Double = 60
    
    @Published var level: WodAiAPI.FitnessLevel = .intermediate
    
    @Published var age: Int = 25
    @Published var gender: WodAiAPI.Gender = .male
    @Published var goal: String = "Build muscle"
    
    // UI State
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var hasUnsavedChanges = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showSuccessToast = false
    
    init() {
    }
    
    // MARK: - Data Loading
    func loadUserProfile() {
        
        isLoading = true
        
        Network.shared.client.fetch(query: UserQuery()) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors, !errors.isEmpty {
                        self.errorMessage = errors.first?.message ?? "Failed to load profile"
                        self.showError = true
                    } else if let userData = graphqlResult.data?.user {
                        self.updateFromUserData(userData)
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    // MARK: - Update Profile
    func saveProfile() {
        isSaving = true
        
        let weightInput = WeightInput(value: weightValue, unit: GraphQLEnum(weight))
        let heightInput = HeightInput(value: heightValue, unit: GraphQLEnum(height))
        
        let input = UpdateUserInput(
            age: .some(age),
            gender: .some(GraphQLEnum(gender)),
            fitnessLevel: .some(GraphQLEnum(level)),
            goal: .some(goal),
            weight: .some(weightInput),
            height: .some(heightInput)
        )
        
        Network.shared.client.perform(mutation: UpdateUserMutation(input: input)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isSaving = false
                
                switch result {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors, !errors.isEmpty {
                        self.errorMessage = errors.first?.message ?? "Failed to save profile"
                        self.showError = true
                    } else if let userData = graphqlResult.data?.updateUser {
                        self.hasUnsavedChanges = false
                        self.showSuccessToast = true
                        
                        // Update local state with saved values
                        self.updateFromMutationData(userData)
                        
                        // Hide toast after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showSuccessToast = false
                        }
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateFromUserData(_ userData: UserQuery.Data.User) {
        if let userAge = userData.age {
            self.age = userAge
        }
        
        if let userGender = userData.gender?.value {
            self.gender = userGender
        }
        
        if let fitnessLevel = userData.fitnessLevel.value {
            self.level = fitnessLevel
        }
        
        if let userWeight = userData.weight {
            self.weightValue = userWeight.value
            if let unit = userWeight.unit.value {
                self.weight = unit
            }
        }
        
        if let userHeight = userData.height {
            self.heightValue = userHeight.value
            if let unit = userHeight.unit.value {
                self.height = unit
            }
        }
        
        // Note: goal is not in the UserQuery, so we can't set it here
    }
    
    private func updateFromMutationData(_ userData: UpdateUserMutation.Data.UpdateUser) {
        if let userAge = userData.age {
            self.age = userAge
        }
        
        if let userGender = userData.gender?.value {
            self.gender = userGender
        }
        
        if let fitnessLevel = userData.fitnessLevel.value {
            self.level = fitnessLevel
        }
        
        if let userWeight = userData.weight {
            self.weightValue = userWeight.value
            if let unit = userWeight.unit.value {
                self.weight = unit
            }
        }
        
        if let userHeight = userData.height {
            self.heightValue = userHeight.value
            if let unit = userHeight.unit.value {
                self.height = unit
            }
        }
        
        if let userGoal = userData.goal {
            self.goal = userGoal
        }
    }
    
    // Convert height for display
    func getHeightFeetAndInches() -> (feet: Int, inches: Int) {
        let totalInches = Int(heightValue)
        return (feet: totalInches / 12, inches: totalInches % 12)
    }
    
    // Set height from feet and inches
    func setHeightFromFeetAndInches(feet: Int, inches: Int) {
        let totalInches = Double((feet * 12) + inches)
        self.heightValue = totalInches
        self.hasUnsavedChanges = true
    }
}
