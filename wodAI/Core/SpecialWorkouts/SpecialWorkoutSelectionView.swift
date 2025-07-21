//
//  SpecialWorkoutSelectionView.swift
//  wodAI
//
//  View for browsing and selecting specific Hero or Girl WODs
//

import SwiftUI

struct SpecialWorkoutSelectionView: View {
    let category: SpecialWorkoutCategory
    let onWorkoutSelected: (SpecialWorkout) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWorkout: SpecialWorkout?
    @State private var showingWorkoutDetail = false
    
    private var workouts: [SpecialWorkout] {
        SpecialWorkoutsDatabase.shared.workouts(for: category)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header Section
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(category.gradientColors.start),
                                            Color(category.gradientColors.end)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: category.iconName)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text(category.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Text(category.description)
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Workouts List
                    ForEach(workouts, id: \.id) { workout in
                        SpecialWorkoutCard(workout: workout) {
                            selectedWorkout = workout
                            showingWorkoutDetail = true
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let workout = selectedWorkout {
                SpecialWorkoutDetailView(
                    workout: workout,
                    onGenerate: { selectedWorkout in
                        showingWorkoutDetail = false
                        dismiss()
                        onWorkoutSelected(selectedWorkout)
                    }
                )
            }
        }
    }
}

// MARK: - Special Workout Card
struct SpecialWorkoutCard: View {
    let workout: SpecialWorkout
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        HStack(spacing: 8) {
                            // Difficulty Badge
                            Text(workout.difficulty.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(workout.difficulty.color).opacity(0.2))
                                )
                                .foregroundColor(Color(workout.difficulty.color))
                            
                            // Duration
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("~\(workout.estimatedDuration) min")
                                    .font(.caption)
                            }
                            .foregroundColor(Color("SecondaryText"))
                        }
                    }
                    
                    Spacer()
                    
                    // Category Icon
                    Image(systemName: workout.category.iconName)
                        .font(.title2)
                        .foregroundColor(Color(workout.category.gradientColors.start))
                }
                
                // Description
                Text(workout.description)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Equipment Tags
                if !workout.equipment.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(workout.equipment.prefix(3), id: \.self) { equipment in
                                Text(equipment)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color("Neutral").opacity(0.2))
                                    )
                                    .foregroundColor(Color("SecondaryText"))
                            }
                            
                            if workout.equipment.count > 3 {
                                Text("+\(workout.equipment.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(Color("TertiaryText"))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("Surface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("Border"), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaledButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    SpecialWorkoutSelectionView(category: .hero) { workout in
        print("Selected workout: \(workout.name)")
    }
}
