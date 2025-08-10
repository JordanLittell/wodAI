//
//  WeeklyWorkoutCard.swift
//  wodAI
//
//  Created by Jordan Littell on 8/10/25.
//


import SwiftUI
import WodAiAPI

// MARK: - Enhanced Weekly Workout Card with Status Support
struct WeeklyWorkoutCard: View {
    let workout: Workout
    let date: Date
    let onStartWorkout: () -> Void
    
    @State private var isIntentionExpanded = false
    private let calendar = Calendar.current
    
    private var isCompleted: Bool {
        workout.completed
    }
    
    private var canStart: Bool {
        workout.status == .generated
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        if workout.status != .generated {
                            Image(systemName: statusIcon)
                                .font(.title3)
                                .foregroundColor(statusColor)
                        }

                        Text(workout.name)
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                    }

                    if workout.status != .generated {
                        Text(workout.status.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                if canStart {
                    Button(action: onStartWorkout) {
                        Text("Start")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color("BrandPrimary"))
                            .cornerRadius(20)
                    }
                }
            }
            
            // Components Section
            if !workout.components.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Workout Intention - Expandable section
                    if !workout.description.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isIntentionExpanded.toggle() } }) {
                                HStack {
                                    Label("Workout Intention", systemImage: "lightbulb")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("BrandPrimary"))
                                    
                                    Spacer()
                                    
                                    Image(systemName: isIntentionExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(Color("BrandPrimary"))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if isIntentionExpanded {
                                Text(workout.description)
                                    .font(.callout)
                                    .foregroundColor(Color("SecondaryText"))
                                    .multilineTextAlignment(.leading)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(12)
                        .background(Color("Surface2").opacity(0.5))
                        .cornerRadius(10)
                    }
                    
                    ForEach(Array(workout.components.enumerated()), id: \.element.id) { index, component in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(component.name)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("PrimaryText"))
                            
                            Text(component.definition)
                                .font(.body)
                                .foregroundColor(Color("PrimaryText"))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                            
                            if !component.description.isEmpty {
                                Text(component.description)
                                    .font(.callout)
                                    .italic()
                                    .foregroundColor(Color("SecondaryText"))
                                    .padding(.top, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color("Background"))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var statusIcon: String {
        if isCompleted {
            return "checkmark.circle.fill"
        }
        
        switch workout.status {
        case .pending:
            return "clock.fill"
        case .generating:
            return "bolt.fill"
        case .completed:
            return "dumbbell.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        default:
            return ""
        }
    }
    
    private var statusColor: Color {
        if isCompleted {
            return Color("Success")
        }
        
        switch workout.status {
        case .pending:
            return Color("Warning")
        case .generating:
            return Color("BrandPrimary")
        case .completed:
            return Color("BrandPrimary")
        case .failed:
            return Color("Warning")
        default:
            return Color("BrandPrimary")
        }
    }
}