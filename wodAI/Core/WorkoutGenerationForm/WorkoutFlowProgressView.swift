//
//  WorkoutFlowProgressView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct WorkoutFlowProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    private var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            HStack(spacing: 4) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Rectangle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .cornerRadius(2)
            
            // Step Indicator
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal)
    }
}
