//
//  WorkoutFlowComponentPreviews.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI
import WodAiAPI


struct WorkoutPreviewView: View {
    let workout: Workout?
    let onStartWorkout: () -> Void
    
    @State private var showingFullWorkout = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Your Workout is Ready!")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                if let workout = workout {
                    EnhancedWorkoutDefinitionView(workout: workout) {
                        print("sharing")
                    }
                    
                    WorkoutCustomizationOptions(workout: workout)
                    
                    VStack(spacing: 12) {
                        StartWODButton(workout: workout)
                    }
                
                    
                }
            }
            .padding()
        }
    }
}

struct FullWorkoutPreviewView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Full workout content would go here
                    Text("Full Workout Details")
                        .font(.title)
                        .padding()
                    
                    // Parse and display complete workout from workout.definition
                    Text(workout.definition)
                        .padding()
                }
            }
            .navigationTitle("Full Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


struct WorkoutFlowComponentPreviews: View {
    @State private var sliderValue: Double = 30
    @State private var selectedIntensity: IntensityLevel = .moderate
    @State private var selectedEquipment: Set<EquipmentOption> = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                WorkoutFlowProgressView(currentStep: 3, totalSteps: 5)
                
                CustomSlider(
                    value: $sliderValue,
                    range: 15...90,
                    step: 5,
                    trackColor: .blue.opacity(0.3),
                    thumbColor: .blue
                )
                .frame(height: 50)
                
                HStack {
                    ForEach(IntensityLevel.allCases, id: \.self) { intensity in
                        IntensityCard(
                            intensity: intensity,
                            isSelected: selectedIntensity == intensity
                        ) {
                            selectedIntensity = intensity
                        }
                    }
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(Array(EquipmentOption.allCases.prefix(4)), id: \.self) { equipment in
                        EquipmentCard(
                            equipment: equipment,
                            isSelected: selectedEquipment.contains(equipment)
                        ) {
                            if selectedEquipment.contains(equipment) {
                                selectedEquipment.remove(equipment)
                            } else {
                                selectedEquipment.insert(equipment)
                            }
                        }
                    }
                }
                
                GenerationLoadingView()
                    .frame(height: 400)
                
                WorkoutPreviewView(
                    workout: Workout(
                        definition: "Sample workout definition",
                        stimulus: "High intensity",
                        muscles: "Full body",
                        format: "AMRAP",
                        id: "sample-id"
                    )
                ) {
                    print("Start workout tapped")
                }
            }
            .padding()
        }
    }
}

struct WorkoutExercisePreview: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Preview")
                .font(.headline)
            
            // Show first few exercises
            VStack(spacing: 8) {
                ForEach(0..<min(3, sampleExercises.count), id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text(sampleExercises[index])
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("3 x 12")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if sampleExercises.count > 3 {
                    HStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        
                        Text("+ \(sampleExercises.count - 3) more exercises")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var sampleExercises: [String] {
        // Parse actual exercises from workout.definition
        // For now, return sample data
        [
            "Push-ups",
            "Squats",
            "Mountain Climbers",
            "Plank",
            "Burpees",
            "Lunges"
        ]
    }
}

#Preview {
    WorkoutFlowComponentPreviews()
}
