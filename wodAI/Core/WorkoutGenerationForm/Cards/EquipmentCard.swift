//
//  EquipmentCard.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct EquipmentCard: View {
    let equipment: EquipmentOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Equipment Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                        .frame(height: 80)
                    
                    Image(systemName: equipment.icon)
                        .font(.system(size: 32))
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                // Equipment Name
                Text(equipment.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    EquipmentCard(equipment: EquipmentOption.barbell, isSelected: false) {
        print("selected")
    }
}
