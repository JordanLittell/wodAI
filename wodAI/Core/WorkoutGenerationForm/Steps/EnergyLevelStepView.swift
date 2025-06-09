//
//  EnergyLevelStepView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//

import SwiftUI

struct EnergyLevelStepView: View {
    @ObservedObject var flowState: WorkoutFlowState
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("How are you feeling today?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We'll adjust the workout to match your energy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                ForEach(EnergyLevel.allCases, id: \.self) { energy in
                    EnergyLevelCard(
                        energy: energy,
                        isSelected: flowState.energyLevel == energy
                    ) {
                        flowState.energyLevel = energy
                        flowState.nextStep()
                    }
                }
            }
            
            Spacer()
            
            Button("Generate Workout") {
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

#Preview {
    EnergyLevelStepView(flowState: WorkoutFlowState())
}
