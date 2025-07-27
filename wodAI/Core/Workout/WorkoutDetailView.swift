//
//  WorkoutDetailView.swift
//  wodAI
//
//  Created by Jordan Littell on 7/27/25.
//
import SwiftUI

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: Workout
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingRepeatOptions = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Workout Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Name and Date
                        Text(workout.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        // Completion Info
                        HStack(spacing: 20) {
                            Label(formatDate(workout.completedAt!), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(Color("SecondaryText"))
                            
                        }
                        
                        Divider()
                        
                        // Definition
                        Text("Workout")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Text(workout.description)
                            .font(.body)
                            .foregroundColor(Color("PrimaryText"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color("Surface"))
                    .cornerRadius(16)
                
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
