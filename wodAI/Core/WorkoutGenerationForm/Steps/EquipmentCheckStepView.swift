//
//  EquipmentCheckStepView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct EquipmentCheckStepView: View {
    @ObservedObject var flowState: WorkoutFlowState
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("What equipment do you have today?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("We'll use your profile defaults, but you can adjust for today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Gym Profile Context
            VStack(alignment: .leading, spacing: 8) {
                Text("Training at")
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
                
                CompactGymProfileSelector()
            }
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(EquipmentOption.allCases, id: \.self) { equipment in
                        EquipmentCard(
                            equipment: equipment,
                            isSelected: flowState.selectedEquipment.contains(equipment)
                        ) {
                            flowState.toggleEquipment(equipment)
                        }
                    }
                }
            }
            
            Button("Next") {
                withAnimation {
                    flowState.nextStep()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        }
        .padding()
    }
}
