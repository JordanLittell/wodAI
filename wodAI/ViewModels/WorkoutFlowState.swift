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
        
        // Convert flow state to GraphQL input
        let description = buildWorkoutDescription()
        let input = CreateWodInput(
            description: GraphQLNullable(stringLiteral: description),
            loadParams: GraphQLNullable(
                LoadParams(
                    weight: GraphQLNullable(integerLiteral: Int.IntegerLiteralType(intensityLevel.weightMultiplier * 10)),
                    volume: GraphQLNullable(integerLiteral: Int.IntegerLiteralType(duration / 5)
                        )
                    )
                )
            )
        
        // Call your existing generation logic
        Network.shared.client.perform(mutation: GenerateWODMutation(input: input)) { result in
            DispatchQueue.main.async {
                self.isGenerating = false
                
                switch result {
                case .success(let graphqlResult):
                    if let wodData = graphqlResult.data?.generateWod {
                        self.generatedWorkout = Workout(
                            definition: wodData.definition,
                            stimulus: "",
                            muscles: "",
                            format: wodData.format,
                            id: wodData.id
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
