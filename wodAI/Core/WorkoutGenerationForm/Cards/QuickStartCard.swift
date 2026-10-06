//
//  QuickStartCard.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct QuickStartCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon with fixed frame
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(height: 24)
                
                // Title with fixed height and line limit
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 20)
                
                // Subtitle with fixed height and line limit
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.center)
                    .frame(height: 32)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100) // Fixed card height
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaledButtonStyle())
    }
}

// MARK: - Custom Button Style for Better Interaction
struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("QuickStartCard Preview - Different Content Lengths")
            .font(.headline)
            .padding()
        
        HStack(spacing: 12) {
            QuickStartCard(
                title: "Quick 20min",
                subtitle: "High intensity",
                icon: "timer",
                color: .orange
            ) {
                print("Quick 20min selected")
            }
            
            QuickStartCard(
                title: "Full Session",
                subtitle: "45-60 mins",
                icon: "flame.fill",
                color: .red
            ) {
                print("Full Session selected")
            }
            
            QuickStartCard(
                title: "Custom",
                subtitle: "Your way",
                icon: "slider.horizontal.3",
                color: .green
            ) {
                print("Custom selected")
            }
        }
        .padding(.horizontal)
        
        // Test with longer content
        HStack(spacing: 12) {
            QuickStartCard(
                title: "Very Long Title Here",
                subtitle: "This is a much longer subtitle that would normally wrap to multiple lines",
                icon: "brain.head.profile",
                color: .blue
            ) {
                print("Long content test")
            }
            
            QuickStartCard(
                title: "Short",
                subtitle: "Brief",
                icon: "checkmark",
                color: .green
            ) {
                print("Short content test")
            }
        }
        .padding(.horizontal)
        
        Spacer()
    }
    .background(Color(.systemBackground))
}
