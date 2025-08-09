//
//  WorkoutFlowState.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI
import Foundation
import WodAiAPI

class WorkoutFlowState: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var duration: Double = 30
    @Published var intensityLevel: IntensityLevel = .moderate
    @Published var selectedEquipment: Set<Equipment> = []
    @Published var selectedMuscleGroups: Set<MuscleGroup> = []
    @Published var energyLevel: EnergyLevel = .good
    @Published var isGenerating: Bool = false
    @Published var generatedWorkout: Workout?
    
    func nextStep() {
        if currentStep < 4 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func toggleEquipment(_ equipment: Equipment) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }
    
    func generateWorkout() {
        isGenerating = true
        
        // Note: The new GraphQL schema doesn't accept any parameters for generateWod
        // The backend will use the user's profile and context to generate appropriate workouts
        let contextDescription = buildWorkoutDescription()
        print("📋 Workout context: \(contextDescription)")
        
        // Call your existing generation logic
        Network.shared.client.perform(mutation: GenerateWODMutation()) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isGenerating = false
                
                switch result {
                case .success(let graphqlResult):
                    if let wodData: GenerateWODMutation.Data.GenerateWod = graphqlResult.data?.generateWod {
                        // Create workout from components
                        let components = wodData.components.map { component in
                            Component(
                                name: component.name,
                                order: component.order,
                                definition: component.definition,
                                description: component.description,
                                equipment: [],
                                muscles: [],
                                movements: [],
                                stimulus: nil,
                                targetFitnessDomains: ["power"],
                                energySystems: ["aerobic"]
                            )
                        }
                        
                        self.generatedWorkout = Workout(
                            id: UUID().uuidString,
                            name: wodData.name,
                            description: wodData.description,
                            coaching: "",
                            stimulus: nil,
                            scheduledDate: Date.now,
                            status: WorkoutStatus.completed,
                            components: components,
                            completedAt: nil,
                            completed: false
                        )
                    }
                case .failure(let error):
                    print("Generation error: \(error)")
                }
            }
        }
    }
    
    private func buildWorkoutDescription() -> String {
        var description = "Generate a \(Int(duration))-minute \(intensityLevel.rawValue) workout"
        
        if !selectedMuscleGroups.isEmpty {
            let muscles = selectedMuscleGroups.map { $0.rawValue }.joined(separator: ", ")
            description += " focusing on \(muscles)"
        }
        
        if !selectedEquipment.isEmpty {
            let equipment = selectedEquipment.map { $0.name }.joined(separator: ", ")
            description += " using \(equipment)"
        }
        
        description += ". Energy level: \(energyLevel.rawValue)."
        
        return description
    }
}
