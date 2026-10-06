//
//  WorkoutCustomizationOptions.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct WorkoutCustomizationOptions: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Adjustments")
                .font(.headline)
            
            VStack(spacing: 12) {
                CustomizationButton(
                    icon: "clock",
                    title: "Make it shorter",
                    subtitle: "Reduce to 30 minutes"
                ) {
                    // Handle time reduction
                }
                
                CustomizationButton(
                    icon: "arrow.up.circle",
                    title: "Increase intensity",
                    subtitle: "Add more challenging variations"
                ) {
                    // Handle intesquare.and.arrow.up.circlesquare.and.arrow.up.circlensity increase
                }
                
                CustomizationButton(
                    icon: "arrow.2.squarepath",
                    title: "Swap exercises",
                    subtitle: "Replace exercises you don't like"
                ) {
                    // Handle exercise swapping
                }
                
                CustomizationButton(
                    icon: "arrow.counterclockwise.circle",
                    title: "Regenerate",
                    subtitle: "Regenerate based on current criteria"
                ) {
                    // Handle exercise swapping
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
