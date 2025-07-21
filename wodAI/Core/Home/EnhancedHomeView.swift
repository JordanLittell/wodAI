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
    @State private var showingHeroWorkouts = false
    @State private var showingGirlWorkouts = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section - Always visible
                    VStack(spacing: 16) {
                        Text("Ready to train?")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.primaryText))
                        
                        Text("Your AI fitness companion is ready to create the perfect workout for you")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Gym Profile Selector
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Training Location")
                                .font(.headline)
                                .foregroundColor(Color("PrimaryText"))
                            Spacer()
                            
                        }
                        .padding(.horizontal)
                        
                        GymProfileSelector()
                            .padding(.horizontal)
                    }
                    
                    // Workout Status Widget - Shows when workout exists or is active
                    if workoutGenerator.workout != nil || wodSessionManager.isActive {
                        WorkoutStatusWidget()
                            .padding(.horizontal)
                            .onTapGesture {
                                showingWorkout = true
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Quick Start Options - Always visible
                    VStack(spacing: 12) {
                        // Primary CTA
                        Button(action: {
                            generateQuickWorkout(type: .intelligent)
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Smart Workout")
                                        .font(.headline)
                                    Text("AI picks the perfect workout for you")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.heroStart, .heroEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        
                        // Quick Options Row
                        HStack(spacing: 12) {
                            QuickStartCard(
                                title: "Quick 20min",
                                subtitle: "High intensity",
                                icon: "timer",
                                color: .orange
                            ) {
                                generateQuickWorkout(type: .quick20)
                            }
                            
                            QuickStartCard(
                                title: "Full Session",
                                subtitle: "45-60 mins",
                                icon: "flame.fill",
                                color: .red
                            ) {
                                generateQuickWorkout(type: .fullSession)
                            }
                            
                            QuickStartCard(
                                title: "Custom",
                                subtitle: "Your way",
                                icon: "slider.horizontal.3",
                                color: .green
                            ) {
                                showingCustomFlow = true
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Special Workouts Section
                    SpecialWorkoutsRow(
                        onHeroSelected: {
                            showingHeroWorkouts = true
                        },
                        onGirlSelected: {
                            showingGirlWorkouts = true
                        }
                    )
                    .padding(.horizontal)
                    
                    // Recent Workouts Section
                    // RecentWorkoutsSection()
                    
                    // Progress Insights
                    // ProgressInsightsSection()
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
        .sheet(isPresented: $showingHeroWorkouts) {
            SpecialWorkoutSelectionView(category: .hero) { specialWorkout in
                generateSpecialWorkout(specialWorkout)
            }
        }
        .sheet(isPresented: $showingGirlWorkouts) {
            SpecialWorkoutSelectionView(category: .girls) { specialWorkout in
                generateSpecialWorkout(specialWorkout)
            }
        }
    }
    
    private func generateQuickWorkout(type: QuickWorkoutType) {
        workoutGenerator.generateQuickWorkout(type: type)
    }
    
    private func generateSpecialWorkout(_ specialWorkout: SpecialWorkout) {
        workoutGenerator.generateQuickWorkout(type: .specialWorkout(specialWorkout))
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
                        .foregroundColor(.warning)
                    
                    Text("Generation Failed")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondaryText)
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

// MARK: - Preview
#Preview {
    EnhancedHomeView()
        .environmentObject(EnhancedWorkoutGeneratorViewModel())
        .environmentObject(WODSessionManager.shared)
}

enum QuickWorkoutType {
    case intelligent, quick20, fullSession
    case specialWorkout(SpecialWorkout)
}
