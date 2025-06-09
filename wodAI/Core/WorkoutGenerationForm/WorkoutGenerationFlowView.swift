//
//  WorkoutGenerationFlowView.swift
//  wodAI
//
//  Redesigned custom workout creation flow with improved UX and design system alignment
//

import SwiftUI
import WodAiAPI

struct WorkoutGenerationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var flowState = WorkoutFlowState()
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Simplified Progress Bar
                    ProgressBar(currentStep: flowState.currentStep, totalSteps: 4)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current Step View
                            Group {
                                switch flowState.currentStep {
                                case 1:
                                    DurationIntensityStep(flowState: flowState)
                                case 2:
                                    EquipmentSelectionStep(flowState: flowState)
                                case 3:
                                    MuscleGroupStep(flowState: flowState)
                                case 4:
                                    ReviewAndGenerateStep(flowState: flowState)
                                default:
                                    EmptyView()
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .animation(.easeInOut(duration: 0.3), value: flowState.currentStep)
                            
                            // Navigation Buttons
                            NavigationButtons(flowState: flowState, dismiss: dismiss)
                                .padding(.top, 20)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
            .onChange(of: flowState.generatedWorkout) { _, newWorkout in
                if let workout = newWorkout {
                    // Transfer to main workout generator and dismiss
                    workoutGenerator.workout = workout
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.surface))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.heroStart, .heroEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Step 1: Duration & Intensity
struct DurationIntensityStep: View {
    @ObservedObject var flowState: WorkoutFlowState
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("How much time do you have?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("We'll match the intensity to your time")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            // Duration Selection
            VStack(spacing: 20) {
                // Large Time Display
                Text("\(Int(flowState.duration))")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.brandPrimary)
                + Text(" min")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.secondaryText)
                
                // Custom Slider
                Slider(value: $flowState.duration, in: 10...90, step: 5)
                    .tint(.brandPrimary)
                
                // Quick Select Buttons
                HStack(spacing: 12) {
                    ForEach([15, 20, 30, 45, 60], id: \.self) { minutes in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                flowState.duration = Double(minutes)
                            }
                        }) {
                            Text("\(minutes)m")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Int(flowState.duration) == minutes ? .white : .primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Int(flowState.duration) == minutes ?
                                    AnyView(
                                        LinearGradient(
                                            colors: [.brandPrimary, .brandSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    ) : AnyView(Color(.surface))
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Intensity Selection
            VStack(spacing: 16) {
                Text("Intensity")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                HStack(spacing: 12) {
                    ForEach(IntensityLevel.allCases, id: \.self) { intensity in
                        IntensityButton(
                            intensity: intensity,
                            isSelected: flowState.intensityLevel == intensity
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                flowState.intensityLevel = intensity
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 2: Equipment Selection
struct EquipmentSelectionStep: View {
    @ObservedObject var flowState: WorkoutFlowState
    
    let equipmentOptions: [(EquipmentOption, String)] = [
        (.bodyweight, "figure.strengthtraining.traditional"),
        (.dumbbells, "dumbbell"),
        (.barbell, "figure.strengthtraining.traditional"),
        (.kettlebells, "figure.boxing"),
        (.resistance_bands, "oval.portrait"),
        (.pull_up_bar, "arrow.up.and.down")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("What equipment do you have?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            // Equipment Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(equipmentOptions, id: \.0) { equipment, icon in
                    EquipmentSelectionCard(
                        equipment: equipment,
                        icon: icon,
                        isSelected: flowState.selectedEquipment.contains(equipment)
                    ) {
                        flowState.toggleEquipment(equipment)
                    }
                }
            }
            
            // Quick Options
            HStack(spacing: 12) {
                Button(action: {
                    flowState.selectedEquipment = [.bodyweight]
                }) {
                    Text("Bodyweight Only")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(.surface))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    flowState.selectedEquipment = Set(equipmentOptions.map { $0.0 })
                }) {
                    Text("Full Gym")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(.surface))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Step 3: Muscle Groups
struct MuscleGroupStep: View {
    @ObservedObject var flowState: WorkoutFlowState
    
    let muscleGroups: [(MuscleGroup, String, String)] = [
        (.chest, "rectangle.expand.vertical", "Chest"),
        (.back, "arrow.up.backward", "Back"),
        (.shoulders, "figure.strengthtraining.traditional", "Shoulders"),
        (.arms, "figure.wave", "Arms"),
        (.legs, "figure.run", "Legs"),
        (.core, "figure.core.training", "Core"),
        (.glutes, "figure.walk", "Glutes"),
        (.cardio, "heart.fill", "Cardio")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Focus areas")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("What do you want to work on today?")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            // Muscle Group Selection
            VStack(spacing: 12) {
                ForEach(muscleGroups, id: \.0) { muscle, icon, name in
                    MuscleGroupRow(
                        muscle: muscle,
                        icon: icon,
                        name: name,
                        isSelected: flowState.selectedMuscleGroups.contains(muscle)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if flowState.selectedMuscleGroups.contains(muscle) {
                                flowState.selectedMuscleGroups.remove(muscle)
                            } else {
                                flowState.selectedMuscleGroups.insert(muscle)
                            }
                        }
                    }
                }
            }
            
            // Quick Options
            HStack(spacing: 12) {
                Button(action: {
                    flowState.selectedMuscleGroups = Set(muscleGroups.map { $0.0 })
                }) {
                    Text("Full Body")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.surface))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    flowState.selectedMuscleGroups = []
                }) {
                    Text("Clear All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondaryText)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.surface))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Step 4: Review & Generate
struct ReviewAndGenerateStep: View {
    @ObservedObject var flowState: WorkoutFlowState
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Ready to create your workout!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Here's what we'll build for you")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            // Summary Cards
            VStack(spacing: 16) {
                // Duration & Intensity
                SummaryCard(
                    icon: "timer",
                    title: "Duration & Intensity",
                    value: "\(Int(flowState.duration)) minutes • \(flowState.intensityLevel.displayName)"
                )
                
                // Equipment
                if !flowState.selectedEquipment.isEmpty {
                    SummaryCard(
                        icon: "dumbbell",
                        title: "Equipment",
                        value: flowState.selectedEquipment.map { $0.displayName }.joined(separator: ", ")
                    )
                }
                
                // Muscle Groups
                if !flowState.selectedMuscleGroups.isEmpty {
                    SummaryCard(
                        icon: "figure.strengthtraining.traditional",
                        title: "Focus Areas",
                        value: flowState.selectedMuscleGroups.map { $0.displayName }.joined(separator: ", ")
                    )
                }
            }
            
            // Generate Button
            Button(action: {
                flowState.generateWorkout()
            }) {
                if flowState.isGenerating {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Generating...")
                    }
                } else {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Generate Workout")
                    }
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.heroStart, .heroEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .disabled(flowState.isGenerating)
        }
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    @ObservedObject var flowState: WorkoutFlowState
    let dismiss: DismissAction
    
    var body: some View {
        HStack(spacing: 16) {
            // Back Button
            if flowState.currentStep > 1 {
                Button(action: {
                    withAnimation {
                        flowState.previousStep()
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.surface))
                    .cornerRadius(12)
                }
            }
            
            // Next/Generate Button
            if flowState.currentStep < 4 {
                Button(action: {
                    withAnimation {
                        flowState.nextStep()
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.brandPrimary, .brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct IntensityButton: View {
    let intensity: IntensityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: intensity.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .brandPrimary)
                
                Text(intensity.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [.brandPrimary, .brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color(.surface), Color(.surface)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
    }
}

struct EquipmentSelectionCard: View {
    let equipment: EquipmentOption
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .brandPrimary)
                
                Text(equipment.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [.brandPrimary, .brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color(.surface), Color(.surface)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(.border), lineWidth: 1)
            )
        }
    }
}

struct MuscleGroupRow: View {
    let muscle: MuscleGroup
    let icon: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .brandPrimary)
                    .frame(width: 30)
                
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                isSelected ?
                LinearGradient(
                    colors: [.brandPrimary, .brandSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color(.surface), Color(.surface)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandPrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.surface))
        .cornerRadius(12)
    }
}

// MARK: - Extensions for Display Names
extension IntensityLevel {
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .intense: return "Intense"
        case .brutal: return "Brutal"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "hare"
        case .moderate: return "figure.walk"
        case .intense: return "figure.run"
        case .brutal: return "flame.fill"
        }
    }
}

extension EquipmentOption {
    var displayName: String {
        switch self {
        case .bodyweight: return "Bodyweight"
        case .dumbbells: return "Dumbbells"
        case .barbell: return "Barbell"
        case .kettlebells: return "Kettlebells"
        case .resistance_bands: return "Resistance Bands"
        case .pull_up_bar: return "Pull-up Bar"
        case .cable_machine: return "Cable Machine"
        case .rowing_machine: return "Rowing Machine"
        case .treadmill: return "Treadmill"
        case .stationary_bike: return "Stationary Bike"
        case .medicine_ball: return "Medicine Ball"
        case .foam_roller: return "Foam Roller"
        case .yoga_mat: return "Yoga Mat"
        case .bench: return "Bench"
        case .smith_machine: return "Smith Machine"
        }
    }
}

extension MuscleGroup {
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .legs: return "Legs"
        case .core: return "Core"
        case .glutes: return "Glutes"
        case .cardio: return "Cardio"
        }
    }
}

// MARK: - Preview
struct WorkoutGenerationFlowView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutGenerationFlowView()
            .environmentObject(EnhancedWorkoutGeneratorViewModel())
    }
}
