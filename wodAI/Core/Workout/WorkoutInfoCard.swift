//
//  WorkoutInfoCard.swift
//  wodAI
//
//  Created by Jordan Littell on 7/27/25.
//
import SwiftUI

struct WorkoutInfoCard: View {
    let workout: Workout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and name
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("BrandPrimary"))
                        .frame(width: 40, height: 40)
                        .background(Color("BrandPrimary").opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                            .lineLimit(1)
                        if workout.completed {
                            Text("Completed \(workout.completedAt!.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.omitted))")
                                .font(.subheadline)
                                .foregroundColor(Color("BrandSecondary"))
                                .lineLimit(1)
                        }
                        
                        
                        Text("\(workout.components.count) part\(workout.components.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                }
                
                let breadcrumbs = workout.components.map { component in
                    component.name
                }.joined(separator: " > ")
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(breadcrumbs)
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("Surface2"))
                .cornerRadius(8)
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WorkoutInfoCard(workout: WorkoutFixture.workout) {
        print("none")
    }
}
