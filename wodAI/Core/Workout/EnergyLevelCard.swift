//
//  EnergyLevelCard.swift
//  wodAI
//
//  Created by Jordan Littell on 6/7/25.
//


import SwiftUI

// MARK: - EnergyLevelCard
struct EnergyLevelCard: View {
    let energy: EnergyLevel
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji and Energy Visualization
                VStack(spacing: 8) {
                    // Large emoji
                    Text(energy.emoji)
                        .font(.system(size: 32))
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    
                    // Energy meter bars
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { bar in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(bar <= energy.energyBars ? energy.color : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 16)
                                .scaleEffect(y: isSelected && bar <= energy.energyBars ? 1.2 : 1.0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.7)
                                        .delay(Double(bar) * 0.05),
                                    value: isSelected
                                )
                        }
                    }
                }
                .frame(width: 80)
                
                // Energy Description
                VStack(alignment: .leading, spacing: 6) {
                    Text(energy.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(energy.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Workout adjustment hint
                    Text(energy.workoutHint)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                        .italic()
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? .white : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isSelected ? 1.0 : 0.0)
                            .animation(.spring(response: 0.3), value: isSelected)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            colors: [energy.color, energy.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? energy.color : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? energy.color.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Extended EnergyLevel with Additional Properties
extension EnergyLevel {
    var title: String {
        switch self {
        case .tired:
            return "Feeling Tired"
        case .low:
            return "Low Energy"
        case .good:
            return "Feeling Good"
        case .energized:
            return "Energized"
        case .pumped:
            return "Pumped Up!"
        }
    }
    
    var description: String {
        switch self {
        case .tired:
            return "Need something gentle and restorative"
        case .low:
            return "Want to move but keep it moderate"
        case .good:
            return "Ready for a solid workout"
        case .energized:
            return "Feeling strong and motivated"
        case .pumped:
            return "Bring on the intensity!"
        }
    }
    
    var workoutHint: String {
        switch self {
        case .tired:
            return "We'll focus on mobility and light movement"
        case .low:
            return "Moderate intensity with longer rest periods"
        case .good:
            return "Balanced workout with standard rest"
        case .energized:
            return "Higher intensity with challenging exercises"
        case .pumped:
            return "Maximum intensity with minimal rest"
        }
    }
    
    var color: Color {
        switch self {
        case .tired:
            return .purple
        case .low:
            return .blue
        case .good:
            return .green
        case .energized:
            return .orange
        case .pumped:
            return .red
        }
    }
    
    var energyBars: Int {
        switch self {
        case .tired:
            return 1
        case .low:
            return 2
        case .good:
            return 3
        case .energized:
            return 4
        case .pumped:
            return 5
        }
    }
}

// MARK: - Alternative Compact EnergyLevelCard
struct CompactEnergyLevelCard: View {
    let energy: EnergyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Emoji with background circle
                ZStack {
                    Circle()
                        .fill(isSelected ? energy.color : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Text(energy.emoji)
                        .font(.system(size: 28))
                }
                
                // Title and energy bars
                VStack(spacing: 6) {
                    Text(energy.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? energy.color : .primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Mini energy bars
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { bar in
                            Circle()
                                .fill(bar <= energy.energyBars ? energy.color : Color.gray.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? energy.color.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? energy.color : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Usage Examples
struct EnergyLevelSelectionView: View {
    @State private var selectedEnergy: EnergyLevel = .good
    @State private var useCompactStyle = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("How are you feeling today?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We'll adjust the workout to match your energy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Toggle("Compact Style", isOn: $useCompactStyle)
                    .padding(.horizontal)
            }
            
            if useCompactStyle {
                // Compact grid layout
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(EnergyLevel.allCases, id: \.self) { energy in
                        CompactEnergyLevelCard(
                            energy: energy,
                            isSelected: selectedEnergy == energy
                        ) {
                            withAnimation(.spring()) {
                                selectedEnergy = energy
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                // Full-width cards
                VStack(spacing: 12) {
                    ForEach(EnergyLevel.allCases, id: \.self) { energy in
                        EnergyLevelCard(
                            energy: energy,
                            isSelected: selectedEnergy == energy
                        ) {
                            withAnimation(.spring()) {
                                selectedEnergy = energy
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Show selected energy info
            if selectedEnergy != .good {
                VStack(spacing: 8) {
                    Text("Workout Adjustment")
                        .font(.headline)
                    
                    Text(selectedEnergy.workoutHint)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(selectedEnergy.color.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
struct EnergyLevelCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Individual card preview
            VStack(spacing: 20) {
                EnergyLevelCard(
                    energy: .energized,
                    isSelected: true
                ) {
                    print("Energized selected")
                }
                
                EnergyLevelCard(
                    energy: .tired,
                    isSelected: false
                ) {
                    print("Tired selected")
                }
            }
            .padding()
            .previewDisplayName("Individual Cards")
            
            // Full selection view
            EnergyLevelSelectionView()
                .previewDisplayName("Full Selection View")
        }
    }
}
