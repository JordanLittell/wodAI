//
//  WorkoutGenerationForm.swift
//  wodAI
//
//  Created by Jordan Littell on 4/19/25.
//

import SwiftUI
import WodAiAPI

struct WorkoutGenerationForm: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State var wgvm: WorkoutGeneratorViewModel
    
    // Create bindings for the sliders
    @State private var generationPrompt: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Generate a new workout")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            improvedTextArea()
                .padding(.horizontal)
            
            Button(action: {
                wgvm.generate(workoutDescription: generationPrompt)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Generate")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
            )
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private func improvedTextArea() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Description")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isTextFieldFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                
                if generationPrompt.isEmpty {
                    Text("Generate a heavy chipper with dumbbells and power snatches.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .allowsHitTesting(false) // Make sure this doesn't interfere with taps
                }
                
                TextField("", text: $generationPrompt, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(minHeight: 120, alignment: .topLeading)
                    .background(Color.clear)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5...10)
            }
            .frame(minHeight: 120)
            
            Text("Be specific about the type of workout you want")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading, 2)
        }
    }
}

#Preview {
    WorkoutGenerationForm(wgvm: WorkoutGeneratorViewModel(generating: false, workout: WorkoutFixture.workout))
}
