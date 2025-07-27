//
//  WorkoutSummaryCard.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct WorkoutSummaryCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(workout.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("45 min") // You'd calculate this from workout data
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            // Workout Stats
            HStack(spacing: 20) {
                WorkoutStatItem(icon: "flame.fill", value: "320", label: "Calories", color: .orange)
                WorkoutStatItem(icon: "heart.fill", value: "8/10", label: "Intensity", color: .red)
                WorkoutStatItem(icon: "figure.strengthtraining.traditional", value: "12", label: "Exercises", color: .blue)
            }
            
            // Brief description
            Text(workout.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func parseWorkoutDescription(_ definition: String) -> String {
        // Parse the workout definition to extract a user-friendly description
        // This would depend on your backend's response format
        return "A balanced mix of strength and cardio exercises designed to maximize your results in the time available."
    }
}

struct WorkoutStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
