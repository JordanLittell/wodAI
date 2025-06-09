//
//  IntensityCard.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct IntensityCard: View {
    let intensity: IntensityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Intensity Icon
                ZStack {
                    Circle()
                        .fill(intensity.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: intensity.iconName)
                        .font(.title3)
                        .foregroundColor(intensity.color)
                }
                
                // Intensity Name
                Text(intensity.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Intensity Bars
                HStack(spacing: 2) {
                    ForEach(1...4, id: \.self) { bar in
                        Rectangle()
                            .fill(bar <= intensity.barCount ?
                                  (isSelected ? .white : intensity.color) :
                                  Color.gray.opacity(0.3))
                            .frame(width: 4, height: 12)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? intensity.color : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? intensity.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

extension IntensityLevel {
    var iconName: String {
        switch self {
        case .light: return "leaf.fill"
        case .moderate: return "figure.walk"
        case .intense: return "flame.fill"
        case .brutal: return "bolt.fill"
        }
    }
    
    var barCount: Int {
        switch self {
        case .light: return 1
        case .moderate: return 2
        case .intense: return 3
        case .brutal: return 4
        }
    }
}
