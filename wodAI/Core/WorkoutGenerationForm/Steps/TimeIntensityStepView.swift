//
//  TimeIntensityStepView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct TimeIntensityStepView: View {
    @ObservedObject var flowState: WorkoutFlowState
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("How long do you want to train?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("We'll adjust the intensity to maximize your results")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Duration Slider with Visual Feedback
            VStack(spacing: 24) {
                Text("\(Int(flowState.duration)) minutes")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                CustomSlider(
                    value: $flowState.duration,
                    range: 15...90,
                    step: 5,
                    trackColor: .blue.opacity(0.3),
                    thumbColor: .blue
                )
                
                // Duration Presets
                HStack(spacing: 12) {
                    ForEach([20, 30, 45, 60], id: \.self) { duration in
                        Button("\(duration)m") {
                            withAnimation(.spring()) {
                                flowState.duration = Double(duration)
                            }
                        }
                        .buttonStyle(PresetButtonStyle(isSelected: Int(flowState.duration) == duration))
                    }
                }
            }
            
            // Intensity Indicators
            VStack(spacing: 16) {
                Text("Intensity Level")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    ForEach(IntensityLevel.allCases, id: \.self) { intensity in
                        IntensityCard(
                            intensity: intensity,
                            isSelected: flowState.intensityLevel == intensity
                        ) {
                            flowState.intensityLevel = intensity
                        }
                    }
                }
            }
            
            Spacer()
            
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
