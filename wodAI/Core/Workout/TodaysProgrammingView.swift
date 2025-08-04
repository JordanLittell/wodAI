//
//  TodaysProgrammingView.swift
//  wodAI
//
//  Created by Jordan Littell on 7/22/25.
//
import SwiftUI
import WodAiAPI
import Foundation

struct TodaysProgrammingView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @EnvironmentObject var wodSessionManager: WODSessionManager
    @State private var isLoading = true
    @State private var todaysWorkout: Workout?
    @State private var error: String?
    @State private var showingWorkout = false
    @State private var isGenerating = false
    @State private var workoutCompleted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Today's Programming")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                
                if isLoading || isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            HStack {
                if todaysWorkout != nil {
                    Text("We have created this session based on your fitness level and activity.")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            
            // Content
            if let workout = todaysWorkout {
                if workout.completed {
                    CompletedWorkoutCard(workout: workout) {
                        generateNewWorkout()
                    }
                } else {
                    TodaysProgrammingCard(workout: workout) {
                        // Set the workout in the generator and show it
                        workoutGenerator.workout = workout
                        showingWorkout = true
                    }
                }
            } else if isLoading {
                LoadingCard()
            } else if let error = error {
                ErrorCard(message: error, onRetry: {
                    fetchTodaysWorkout()
                }, onGenerate: {
                    generateNewWorkout()
                })
            } else {
                // No workout and no error - show empty state
                let _ = print("📄 Showing empty state card")
                EmptyStateCard {
                    generateNewWorkout()
                }
            }
        }
        .onAppear {
            fetchTodaysWorkout()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
            print("🔔 Received workout completed notification")
            // Refresh the today's workout to get updated status
            fetchTodaysWorkout()
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            NavigationView {
                WorkoutView()
                    .environmentObject(workoutGenerator)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onChange(of: workoutGenerator.workout) { oldValue, newValue in
            // When workout is cleared (completed), refresh the current WOD
            if oldValue != nil && newValue == nil {
                print("🔄 Workout completed, refreshing current WOD...")
                fetchTodaysWorkout()
            }
        }
    }
    
    private func fetchTodaysWorkout() {
        isLoading = true
        error = nil
        
        Network.shared.client.fetch(query: CurrentWODQuery()) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let currentWod = graphQLResult.data?.currentWod {
                        // Convert from GraphQL model to local Workout model
                        let components = currentWod.components.map { component in
                            Component(
                                name: component.name,
                                order: component.order,
                                definition: component.definition,
                                description: "", // Add description if available in GraphQL
                                targetFitnessDomains: nil,
                                energySystems: nil
                            )
                        }
                        
                        todaysWorkout = Workout(
                            id: currentWod.id,
                            name: currentWod.name,
                            description: currentWod.description,
                            components: components,
                            completedAt: nil,
                            completed: currentWod.completed
                        )
                        
                        if !currentWod.completed && workoutGenerator.workout == nil {
                            workoutGenerator.workout = todaysWorkout
                        }
                    } else {
                        // No workout for today yet
                        todaysWorkout = nil
                    }
                    
                case .failure(let error):
                    self.error = "Failed to load today's workout"
                    print("Error fetching current WOD: \(error)")
                }
            }
        }
    }
    
    private func generateNewWorkout() {
        print("🎯 Generate workout button tapped")
        isGenerating = true
        error = nil
        
        print("📤 Calling GenerateWODMutation...")
        Network.shared.client.perform(mutation: GenerateWODMutation()) { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let graphQLResult):
                    print("✅ Received response from server")
                    
                    // Check for GraphQL errors
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        print("❌ GraphQL Errors: \(errors) \(String(describing: errors[0].path)) \(String(describing: errors[0].errorDescription))")
                        return
                    }
                    
                    if let generatedWod = graphQLResult.data?.generateWod {
                        print("✅ Workout data received: \(generatedWod.name)")
                        // Convert from GraphQL model to local Workout model
                        let components = generatedWod.components.map { component in
                            Component(
                                name: component.name,
                                order: component.order,
                                definition: component.definition,
                                description: component.description,
                                targetFitnessDomains: nil,
                                energySystems: nil
                            )
                        }
                        
                        let newWorkout = Workout(
                            id: generatedWod.id,
                            name: generatedWod.name,
                            description: generatedWod.description,
                            components: components,
                            completedAt: nil,
                            completed: false
                        )
                        
                        todaysWorkout = newWorkout
                        workoutCompleted = false
                        workoutGenerator.workout = newWorkout
                        
                        // Show the workout immediately after generation
                        showingWorkout = true
                    } else {
                        print("⚠️ No workout data in response")
                        self.error = "No workout data received"
                    }
                    
                case .failure(let error):
                    self.error = "Failed to generate workout"
                    print("Error generating WOD: \(error)")
                }
            }
        }
    }
}

// MARK: - Today's Programming Card
struct TodaysProgrammingCard: View {
    let workout: Workout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and name
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("BrandPrimary"))
                        .frame(width: 40, height: 40)
                        .background(Color("BrandPrimary").opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                            .lineLimit(1)
                        
                        Text("\(workout.components.count) component\(workout.components.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                }
                
                let breadcrumbs = workout.components.map { component in
                    component.name
                }.joined(separator: " > ")
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(breadcrumbs)
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("Surface2"))
                .cornerRadius(8)
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading Card
struct LoadingCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("Surface2"))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Surface2"))
                        .frame(width: 150, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Surface2"))
                        .frame(width: 100, height: 12)
                }
                
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("Surface2"))
                .frame(height: 60)
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Error Card
struct ErrorCard: View {
    let message: String
    let onRetry: () -> Void
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(Color("Warning"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unable to load workout")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Retry")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
                
                Button(action: onGenerate) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text("Generate New")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Warning").opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Completed Workout Card
struct CompletedWorkoutCard: View {
    let workout: Workout
    let onGenerateMore: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Completed workout info
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("Success"))
                    .frame(width: 40, height: 40)
                    .background(Color("Success").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completed: \(workout.name)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                        .lineLimit(1)
                    
                    Text("Great work today! 💪")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
            }
            
            // Generate more button
            Button(action: onGenerateMore) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text("Generate More")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color("BrandPrimary"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color("BrandPrimary").opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Success").opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let onGenerateTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title2)
                    .foregroundColor(Color("BrandPrimary"))
                    .frame(width: 40, height: 40)
                    .background(Color("BrandPrimary").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready for programming?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("Generate your workout for today")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
            }
            
            Button(action: onGenerateTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.subheadline)
                    Text("Generate Programming")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color("HeroStart"), Color("HeroEnd")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    TodaysProgrammingView()
        .environmentObject(EnhancedWorkoutGeneratorViewModel())
        .environmentObject(WODSessionManager.shared)
        .padding()
        .background(Color("Background"))
}
