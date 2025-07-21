//
//  SpecialWorkoutDetailView.swift
//  wodAI
//
//  Detailed view for a specific Hero or Girl WOD
//

import SwiftUI

struct SpecialWorkoutDetailView: View {
    let workout: SpecialWorkout
    let onGenerate: (SpecialWorkout) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Icon and category
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(workout.category.gradientColors.start),
                                            Color(workout.category.gradientColors.end)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: workout.category.iconName)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(workout.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color("PrimaryText"))
                                .multilineTextAlignment(.center)
                            
                            Text(workout.description)
                                .font(.subheadline)
                                .foregroundColor(Color("SecondaryText"))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Workout Stats
                        HStack(spacing: 20) {
                            WorkoutStatCard(
                                icon: "speedometer",
                                title: "Difficulty",
                                value: workout.difficulty.rawValue,
                                color: Color(workout.difficulty.color)
                            )
                            
                            WorkoutStatCard(
                                icon: "clock",
                                title: "Duration",
                                value: "~\(workout.estimatedDuration) min",
                                color: Color("BrandPrimary")
                            )
                            
                            WorkoutStatCard(
                                icon: "flame.fill",
                                title: "Category",
                                value: workout.category.displayName,
                                color: Color(workout.category.gradientColors.start)
                            )
                        }
                    }
                    
                    // Workout Definition
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Text(workout.definition)
                            .font(.body)
                            .foregroundColor(Color("PrimaryText"))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("Surface2"))
                            )
                    }
                    
                    // Story Section (for Hero WODs)
                    if let story = workout.story {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Story")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("PrimaryText"))
                            
                            Text(story)
                                .font(.body)
                                .foregroundColor(Color("SecondaryText"))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("Surface2"))
                                )
                        }
                    }
                    
                    // Equipment Required
                    if !workout.equipment.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Equipment Required")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("PrimaryText"))
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 120), spacing: 8)
                            ], spacing: 8) {
                                ForEach(workout.equipment, id: \.self) { equipment in
                                    Text(equipment)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color("BrandPrimary").opacity(0.1))
                                        )
                                        .foregroundColor(Color("BrandPrimary"))
                                }
                            }
                        }
                    }
                    
                    // Movements
                    if !workout.movements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Movements")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("PrimaryText"))
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100), spacing: 8)
                            ], spacing: 8) {
                                ForEach(workout.movements, id: \.self) { movement in
                                    Text(movement)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color("Success").opacity(0.1))
                                        )
                                        .foregroundColor(Color("Success"))
                                }
                            }
                        }
                    }
                    
                    // Generate Button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Generate \(workout.name)")
                                    .font(.headline)
                                Text("Create this workout for today")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(workout.category.gradientColors.start),
                                    Color(workout.category.gradientColors.end)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog(
            "Generate \(workout.name)?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Generate Workout") {
                onGenerate(workout)
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will create \(workout.name) as your current workout. Are you ready to take on this challenge?")
        }
    }
}

// MARK: - Workout Stat Card
struct WorkoutStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(Color("TertiaryText"))
                .textCase(.uppercase)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryText"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("Surface"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    SpecialWorkoutDetailView(
        workout: SpecialWorkoutsDatabase.shared.heroWorkouts.first!
    ) { workout in
        print("Generating workout: \(workout.name)")
    }
}
