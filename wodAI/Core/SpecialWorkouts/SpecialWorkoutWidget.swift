//
//  SpecialWorkoutWidget.swift
//  wodAI
//
//  Widget component for Hero and Girl WODs
//

import SwiftUI

struct SpecialWorkoutWidget: View {
    let category: SpecialWorkoutCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon with category-specific styling
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
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(height: 32)
                
                // Category title
                Text(category.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 20)
                
                // Category description
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.center)
                    .frame(height: 32)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100) // Match QuickStartCard height
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("Surface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(category.gradientColors.start).opacity(0.3),
                                        Color(category.gradientColors.end).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(ScaledButtonStyle())
    }
}

// MARK: - Special Workouts Row
struct SpecialWorkoutsRow: View {
    let onHeroSelected: () -> Void
    let onGirlSelected: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Special Workouts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                // Optional: Add "View All" button
                Button("View All") {
                    // TODO: Navigate to full special workouts view
                }
                .font(.caption)
                .foregroundColor(Color("BrandPrimary"))
            }
            
            // Workout Category Cards
            HStack(spacing: 12) {
                SpecialWorkoutWidget(
                    category: .hero,
                    action: onHeroSelected
                )
                
                SpecialWorkoutWidget(
                    category: .girls,
                    action: onGirlSelected
                )
                
                // Spacer to maintain layout with 3-card rows
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        Text("Special Workout Widgets")
            .font(.title2)
            .fontWeight(.bold)
        
        // Individual widgets
        HStack(spacing: 12) {
            SpecialWorkoutWidget(category: .hero) {
                print("Hero WODs selected")
            }
            
            SpecialWorkoutWidget(category: .girls) {
                print("Girl WODs selected")
            }
            
            Spacer()
        }
        .padding(.horizontal)
        
        Divider()
        
        // Full row component
        SpecialWorkoutsRow(
            onHeroSelected: {
                print("Hero WODs row selected")
            },
            onGirlSelected: {
                print("Girl WODs row selected")
            }
        )
        .padding(.horizontal)
        
        Spacer()
    }
    .padding()
    .background(Color("Background"))
}
