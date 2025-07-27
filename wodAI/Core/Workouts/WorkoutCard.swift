//
//  WorkoutCard.swift
//  wodAI
//
//  Created by Jordan Littell on 7/27/25.
//
import SwiftUI

// MARK: - Workout Card
struct WorkoutCard: View {
    let workout: CompletedWorkout
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                            .lineLimit(1)
                        
                        Text(formatDate(workout.completedAt))
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    
                    Spacer()
                    
                    if let muscles = workout.muscles, !muscles.isEmpty {
                        Text(muscles)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color("BrandPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("BrandPrimary").opacity(0.1))
                            .cornerRadius(6)
                            .lineLimit(1)
                    }
                }
                
                // Definition Preview with gradient fade
                ZStack(alignment: .bottomTrailing) {
                    Text(workout.definition)
                        .font(.subheadline)
                        .foregroundColor(Color("PrimaryText"))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Gradient fade effect
                    if workout.definition.count > 100 {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("Surface").opacity(0),
                                Color("Surface").opacity(0.8),
                                Color("Surface")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 100)
                        .allowsHitTesting(false)
                        
                        Text("...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("SecondaryText"))
                            .padding(.trailing, 4)
                    }
                }
                
                // Footer
                HStack {
                    // Action hint
                    Text("Tap to view full workout")
                        .font(.caption)
                        .foregroundColor(Color("BrandPrimary"))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                }
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
