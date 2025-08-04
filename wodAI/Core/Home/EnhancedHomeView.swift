//
//  EnhancedHomeView.swift
//  wodAI
//
//  Enhanced home view with consistent UI and workout status widget
//

import SwiftUI
import WodAiAPI

struct EnhancedHomeView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @EnvironmentObject var wodSessionManager: WODSessionManager
    @State private var showingCustomFlow = false
    @State private var showingQuickWorkout = false
    @State private var showingWorkoutExecution = false
    @State private var showingWorkout = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Ready to train?")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("PrimaryText"))
                        
                    }
                    .padding(.top, 20)
                    
                    TodaysProgrammingView()
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    
                }
            }
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.3), value: workoutGenerator.workout != nil)
            .animation(.easeInOut(duration: 0.3), value: wodSessionManager.isActive)
        }
        .sheet(isPresented: $showingCustomFlow) {
            NavigationView {
                WorkoutGenerationFlowView()
                    .environmentObject(workoutGenerator)
            }
        }
        .sheet(isPresented: $showingQuickWorkout) {
            QuickWorkoutGenerationView()
                .environmentObject(workoutGenerator)
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            NavigationView {
                WorkoutView()
                    .environmentObject(workoutGenerator)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
        .onChange(of: workoutGenerator.generating) { oldValue, newValue in
            // Show the generation view when generation starts
            if newValue {
                showingQuickWorkout = true
            }
        }
        .onChange(of: workoutGenerator.workout) { oldValue, newValue in
            // Dismiss the generation view when a workout is generated
            print("determining if we show the workout")
            if newValue != nil && !workoutGenerator.generating {
                showingQuickWorkout = false
                showingWorkout = true
            }
        }
    }
    
    private func generateQuickWorkout(type: QuickWorkoutType) {
        workoutGenerator.generateQuickWorkout(type: type)
    }
}

// MARK: - Quick Workout Generation View
struct QuickWorkoutGenerationView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingWorkoutPreview = false
    
    var body: some View {
        ZStack {
            if workoutGenerator.generating {
                // Show loading animation while generating
                GenerationLoadingView()
                    .transition(.opacity)
            } else if workoutGenerator.showError, let errorMessage = workoutGenerator.errorMessage {
                // Show error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("Warning"))
                    
                    Text("Generation Failed")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        Button("Try Again") {
                            workoutGenerator.errorMessage = nil
                            workoutGenerator.showError = false
                            if let quickType = workoutGenerator.quickWorkoutType {
                                workoutGenerator.generateQuickWorkout(type: quickType)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            workoutGenerator.errorMessage = nil
                            workoutGenerator.showError = false
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .transition(.opacity)
            } else if workoutGenerator.workout != nil && !showingWorkoutPreview {
                // Auto-dismiss after generation completes
                Color.clear
                    .onAppear {
                        // Small delay to show completion state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
            } else if showingWorkoutPreview {
                NavigationView {
                    WorkoutView()
                        .environmentObject(workoutGenerator)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    dismiss()
                                }
                            }
                        }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: workoutGenerator.generating)
        .animation(.easeInOut(duration: 0.5), value: workoutGenerator.workout != nil)
    }
}

#Preview {
    EnhancedHomeView()
        .environmentObject(EnhancedWorkoutGeneratorViewModel())
        .environmentObject(WODSessionManager.shared)
}


