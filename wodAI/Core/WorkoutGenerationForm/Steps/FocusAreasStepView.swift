//
//  FocusAreasStepView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//

import SwiftUI
struct FocusAreasStepView: View {
    @ObservedObject var flowState: WorkoutFlowState
    @State private var showingBodyMap = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("What do you want to focus on?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap muscle groups or choose a focus type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Toggle between body map and focus types
            Picker("View", selection: $showingBodyMap) {
                Text("Focus Types").tag(false)
                Text("Body Map").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
//            if showingBodyMap {
//                InteractiveBodyMapView(selectedMuscles: $flowState.selectedMuscleGroups)
//            } else {
//                FocusTypesGridView(flowState: flowState)
//            }
//            
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
