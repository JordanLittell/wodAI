//
//  TweakOptionButton.swift
//  wodAI
//
//  Reusable button component for workout tweaking options
//

import SwiftUI

struct TweakOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let isFullWidth: Bool
    let action: () -> Void
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isLoading: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: isFullWidth ? 12 : 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: color))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(isFullWidth ? .title2 : .title3)
                }
                
                if isFullWidth {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    
                    Spacer()
                } else {
                    VStack(spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryText"))
                            .lineLimit(1)
                        
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(Color("SecondaryText"))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isFullWidth ? 56 : 44)
            .padding(.horizontal, isFullWidth ? 16 : 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("Surface2"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaledButtonStyle())
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Regular buttons
        HStack(spacing: 12) {
            TweakOptionButton(
                title: "Shorter",
                subtitle: "Less time",
                icon: "minus.circle.fill",
                color: .orange
            ) {
                print("Shorter tapped")
            }
            
            TweakOptionButton(
                title: "Longer",
                subtitle: "More time",
                icon: "plus.circle.fill",
                color: .blue
            ) {
                print("Longer tapped")
            }
        }
        
        // Full width button
        TweakOptionButton(
            title: "Regenerate",
            subtitle: "Brand new workout",
            icon: "arrow.clockwise.circle.fill",
            color: .purple,
            isFullWidth: true
        ) {
            print("Regenerate tapped")
        }
        
        // Loading state
        TweakOptionButton(
            title: "Updating...",
            subtitle: "Please wait",
            icon: "arrow.clockwise",
            color: .blue,
            isLoading: true,
            isFullWidth: true
        ) {
            print("Loading button tapped")
        }
    }
    .padding()
    .background(Color("Background"))
}
