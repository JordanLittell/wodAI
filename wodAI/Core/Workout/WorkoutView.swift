//
//  WorkoutView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//
import SwiftUI
import WodAiAPI

struct WorkoutView: View {
    @EnvironmentObject var wgvm: WorkoutGeneratorViewModel
    
    @State var showTimer: Bool = false
    @State var isPaused: Bool = false
    @State var restartRequested: Bool = false
    @State private var modificationInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        if wgvm.generating {
            WorkoutLaunchAnimation()
        } else {
            if showTimer {
                TimerView(progress: .constant(50.0), duration: .constant(15.0))
            } else {
                VStack(spacing: 24) {
                    // Header section with workout format
                    VStack(spacing: 8) {
                        Text("Today's Workout")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    if wgvm.updating {
                        WorkoutLaunchAnimation(text: "Updating workout...")
                    } else {
                        workoutDisplay(workout: wgvm.workout)
                    }
                    
                    
                    Spacer()
                    
                    modifyWorkout()
                }
                .padding(.vertical, 25)
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    private func workoutDisplay(workout: Workout) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("\(workout.format.uppercased()):")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(workout.definition)")
                    .font(.body)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
            
            Button(action: {
                wgvm.markCompleted()
            }) {
                Text("Mark Completed")
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
        }
    }
    
    private func modifyWorkout() -> some View {
        // Chat input field with message bubble and send icon
        VStack(spacing: 16) {
            Text("Modify Workout")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if modificationInput.isEmpty && !isInputFocused {
                        Text("Make the weights heavier")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 1)
                            .allowsHitTesting(false)
                    }
                    
                    TextField("", text: $modificationInput, axis: .vertical)
                        .focused($isInputFocused)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .multilineTextAlignment(.leading)
                }.focused($isInputFocused)
                
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .stroke(isInputFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                ).blur(radius: 0.5)
                
                Button(action: {
                    submitModification()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.blue)
                        )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }
    
    private func submitModification() {
        guard !modificationInput.isEmpty else { return }
        wgvm.update(description: modificationInput)
        modificationInput = ""
        isInputFocused = false
    }
}

#Preview {
    WorkoutView()
        .environmentObject(WorkoutGeneratorViewModel(generating: false, workout: WorkoutFixture.workout))
}
