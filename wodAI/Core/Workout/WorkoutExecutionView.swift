//
//  WorkoutExecutionView.swift
//  wodAI
//
//  Dedicated view for executing workouts, separate from home page
//

import SwiftUI
import WodAiAPI

struct WorkoutExecutionView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @EnvironmentObject var wodSessionManager: WODSessionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.background)
                    .ignoresSafeArea()
                
                if workoutGenerator.workout != nil {
                    if wodSessionManager.isActive {
                        // Show active workout view
                        ActiveWODView()
                            .environmentObject(wodSessionManager)
                    } else {
                        // Show workout preview
                        WorkoutView()
                            .environmentObject(workoutGenerator)
                    }
                } else {
                    // No workout available
                    ContentUnavailableView(
                        "No Workout Available",
                        systemImage: "figure.run",
                        description: Text("Generate a workout from the home page to get started")
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if !wodSessionManager.isActive {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                // Share workout
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(action: {
                                // Regenerate
                                workoutGenerator.workout = nil
                                dismiss()
                            }) {
                                Label("Generate New", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct WorkoutExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutExecutionView()
            .environmentObject(EnhancedWorkoutGeneratorViewModel())
            .environmentObject(WODSessionManager.shared)
    }
}
