//
//  SwiftUIView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//

import SwiftUI

struct WorkoutDefinitionView: View {
    let workout: Workout;
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Workout Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
            
            }
            
            // Workout Definition Display
            VStack(alignment: .leading, spacing: 12) {
                // Format Title
                Text(workout.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.brandPrimary)
            
                
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}
