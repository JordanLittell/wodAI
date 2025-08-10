//
//  EmptyDayCard.swift
//  wodAI
//
//  Created by Jordan Littell on 8/10/25.
//
import SwiftUI

// MARK: - Updated Empty Day Card
struct EmptyDayCard: View {
    let date: Date
    let onGenerateWorkout: () -> Void
    
    private let calendar = Calendar.current
    
    private var message: String {
        if calendar.isDateInToday(date) {
            return "No programming scheduled for today"
        } else if date < Date() {
            return "No programming was scheduled for this date"
        } else {
            return "Programming unavailable"
        }
    }
    
    private var canGenerate: Bool {
        // Only allow generating for today and future dates
        return calendar.isDateInToday(date) || date > Date()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Color("SecondaryText").opacity(0.5))
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("PrimaryText"))
                
                if canGenerate {
                    Text("Tap below to generate your 7-day workout schedule.")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Button(action: onGenerateWorkout) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                            Text("Generate 7-Day Schedule")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color("BrandPrimary"))
                        .cornerRadius(25)
                    }
                    .padding(.top, 8)
                } else {
                    Text("Programming for this date will be released soon.")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }
}
