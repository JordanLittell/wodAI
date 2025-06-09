//
//  ReviewGenerateStepView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct ReviewGenerateStepView: View {
    @ObservedObject var flowState: WorkoutFlowState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            if flowState.isGenerating {
                GenerationLoadingView()
            } else {
                WorkoutPreviewView(
                    workout: flowState.generatedWorkout,
                    onStartWorkout: {
                        dismiss()
                        // Navigate to workout view
                    }
                )
            }
        }
        .onAppear {
            flowState.generateWorkout()
        }
    }
}
