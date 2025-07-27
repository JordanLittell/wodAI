//
//  TargetedWorkouts.swift
//  wodAI
//
//  Created by Jordan Littell on 7/27/25.
//

import SwiftUI
import WodAiAPI

enum QuickWorkoutType {
    case intelligent, quick20, fullSession
}

struct TargetedWorkouts: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Targeted Sessions")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
            }
            HStack {
                Text("Maximally target specific aspects of your fintess.")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickStartCard(
                    title: "HIIT",
                    subtitle: "Build anaerobic capacity",
                    icon: "flame",
                    color: .red
                ) {
//                    generateQuickWorkout(type: .quick20)
                }
                
                QuickStartCard(
                    title: "Strength",
                    subtitle: "Build strength, power, and muscle mass",
                    icon: "dumbbell.fill",
                    color: .blue
                ) {
//                    generateQuickWorkout(type: .fullSession)
                }
                
                QuickStartCard(
                    title: "Endurance",
                    subtitle: "Cardiovascular/respiratory endurance, stamina",
                    icon: "clock.fill",
                    color: .neutral
                ) {
//                    generateQuickWorkout(type: .fullSession)
                }
            }
            
            HStack(spacing: 12) {
                
                QuickStartCard(
                    title: "Mobility",
                    subtitle: "Flexibility, balance, injury prevention",
                    icon: "clock.fill",
                    color: .neutral
                ) {
//                    generateQuickWorkout(type: .fullSession)
                }
                
                QuickStartCard(
                    title: "Metcon",
                    subtitle: "Work capacity across multiple domains",
                    icon: "clock.fill",
                    color: .neutral
                ) {
//                    generateQuickWorkout(type: .fullSession)
                }
                QuickStartCard(
                    title: "Bodyweight",
                    subtitle: "Bodyweight workouts",
                    icon: "clock.fill",
                    color: .neutral
                ) {
//                    generateQuickWorkout(type: .fullSession)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    TargetedWorkouts()
}
