//
//  WorkoutProgressView.swift
//  wodAI
//
//  Shows progress of completed components in a workout
//

import SwiftUI

struct WorkoutProgressView: View {
    let workout: Workout
    @StateObject private var completionManager = ComponentCompletionManager.shared
    
    private var completedCount: Int {
        completionManager.completedComponentsCount(for: workout.id)
    }
    
    private var totalCount: Int {
        workout.components.count
    }
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    private var allCompleted: Bool {
        completedCount == totalCount && totalCount > 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Header
            HStack {
                Image(systemName: allCompleted ? "checkmark.circle.fill" : "chart.line.uptrend.xyaxis")
                    .foregroundColor(allCompleted ? Color("Success") : Color("BrandPrimary"))
                    .font(.title3)
                
                Text("Workout Progress")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Text("\(completedCount) of \(totalCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(allCompleted ? Color("Success") : Color("SecondaryText"))
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color("Surface2"))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: allCompleted ? 
                                    [Color("Success"), Color("Success").opacity(0.8)] :
                                    [Color("BrandPrimary"), Color("BrandSecondary")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            
            // Completion Message
            if allCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color("Warning"))
                        .font(.caption)
                    
                    Text("Congratulations! You've completed all components!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("Success"))
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(Color("Warning"))
                        .font(.caption)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(allCompleted ? Color("Success").opacity(0.05) : Color("Surface"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(allCompleted ? Color("Success").opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut, value: allCompleted)
    }
}

// MARK: - Preview
//#Preview {
//    VStack(spacing: 20) {
//        WorkoutProgressView(workout: Workout.example)
//            .padding()
//        
//        // Example with multiple components
//        WorkoutProgressView(
//            workout: Workout(
//                id: "example-2",
//                name: "Full Body Workout",
//                description: "Complete workout with multiple components",
//                components: [
//                    Component(name: "Warm-up", order: 1, definition: "5 min row", description: "", targetFitnessDomains: nil, energySystems: nil),
//                    Component(name: "Strength", order: 2, definition: "Deadlifts 5x5", description: "", targetFitnessDomains: nil, energySystems: nil),
//                    Component(name: "Metcon", order: 3, definition: "21-15-9 Thrusters and Pull-ups", description: "", targetFitnessDomains: nil, energySystems: nil),
//                    Component(name: "Cool Down", order: 4, definition: "Stretching", description: "", targetFitnessDomains: nil, energySystems: nil)
//                ],
//                completedAt: nil,
//                completed: true
//            )
//        )
//        .padding()
//    }
//    .background(Color("Background"))
//}
