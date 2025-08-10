//
//  CompletedWorkoutView.swift
//  wodAI
//
//  A detailed view for displaying completed workout definitions
//

import SwiftUI

struct CompletedWorkoutView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color("Success"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("PrimaryText"))
                                    
                                    if let completedAt = workout.completedAt {
                                        Text("Completed on \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.subheadline)
                                            .foregroundColor(Color("SecondaryText"))
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color("Surface"))
                        .cornerRadius(16)
                        
                        // Components Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Workout Components")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("PrimaryText"))
                            
                            ForEach(Array(workout.components.enumerated()), id: \.element.id) { index, component in
                                ComponentDetailCard(
                                    component: component,
                                    componentNumber: index + 1
                                )
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

// MARK: - Component Detail Card
struct ComponentDetailCard: View {
    let component: Component
    let componentNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Component Header
            HStack {
                Text("Part \(componentNumber)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("BrandPrimary"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("BrandPrimary").opacity(0.1))
                    .cornerRadius(4)
                
                Text(component.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
            }
            
            // Component Definition
            VStack(alignment: .leading, spacing: 8) {
                Text("Definition")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("SecondaryText"))
                    .textCase(.uppercase)
                
                Text(component.definition)
                    .font(.body)
                    .foregroundColor(Color("PrimaryText"))
                    .lineSpacing(4)
            }
            .padding()
            .background(Color("Surface2"))
            .cornerRadius(12)
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
struct CompletedWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let completedWorkout = Workout(
            id: "completed-example",
            name: "CrossFit Total Domination",
            description: "This workout is designed to create a complete full-body challenge",
            coaching: "Focus on maintaining good form throughout all components",
            stimulus: "Multi-modal full-body challenge",
            scheduledDate: nil,
            status: .completed,
            components: WorkoutFixture.workout.components,
            completedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            completed: true
        )
        
        CompletedWorkoutView(workout: completedWorkout)
    }
}
