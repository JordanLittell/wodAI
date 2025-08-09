//
//  WeeklyWorkoutViewModel.swift
//  wodAI
//
//  ViewModel for managing 7-day workout scheduling and async generation
//

import Foundation
import SwiftUI
import WodAiAPI

@MainActor
class WeeklyWorkoutViewModel: ObservableObject {
    @Published var workouts: [Date: Workout] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate = Date()
    
    private let calendar = Calendar.current
    
    // MARK: - Computed Properties
    
    var workoutForSelectedDate: Workout? {
        let dateKey = calendar.startOfDay(for: selectedDate)
        return workouts[dateKey]
    }
    
    var isLoadingWorkoutForSelectedDate: Bool {
        guard let workout = workoutForSelectedDate else { return isLoading }
        return workout.shouldShowLoadingState
    }
    
    // MARK: - Public Methods
    
    func loadWorkoutsForWeek(containing date: Date) {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return }
        
        let startDate = weekInterval.start
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? weekInterval.end
        
        loadWorkouts(from: startDate, to: endDate)
    }
    
    func loadWorkoutForDate(_ date: Date) {
        isLoading = true
        errorMessage = nil
        
        let dateKey = calendar.startOfDay(for: date)
        
        // Convert Date to String for GraphQL DateTime
        let formatter = ISO8601DateFormatter()
        let dateTimeInput = formatter.string(from: date)
        
        Network.shared.client.fetch(query: GetWorkoutByDateQuery(date: dateTimeInput)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let workoutData = graphQLResult.data?.getWorkoutByDate {
                        let workout = self.mapGraphQLWorkoutToModel(workoutData)
                        self.workouts[dateKey] = workout
                        
                        // If workout is still generating, poll for updates
                        if workout.status.isGenerating {
                            self.pollForWorkoutUpdate(date: date)
                        }
                    } else {
                        // No workout found for this date
                        self.workouts[dateKey] = nil
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load workout for \(self.formatDate(date))"
                    print("Error fetching workout for date: \(error)")
                }
            }
        }
    }
    
    func generateWorkoutSchedule() {
        // For now, we'll use a placeholder user ID
        // In a real implementation, you'd get this from AuthManager
        let _ = "current-user-id" // Unused but kept for reference
        
        isLoading = true
        errorMessage = nil
        
        Network.shared.client.perform(mutation: GenerateWorkoutScheduleMutation()) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let response = graphQLResult.data?.generateWorkoutSchedule {
                        if response.success {
                            // Refresh current week view
                            self.loadWorkoutsForWeek(containing: self.selectedDate)
                        } else {
                            self.errorMessage = response.message
                        }
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to generate workout schedule"
                    print("Error generating workout schedule: \(error)")
                }
            }
        }
    }
    
    func retryFailedWorkout() {
        loadWorkoutForDate(selectedDate)
    }
    
    // MARK: - Private Methods
    
    private func loadWorkouts(from startDate: Date, to endDate: Date) {
        isLoading = true
        errorMessage = nil
        
        // Convert Dates to String for GraphQL DateTime
        let formatter = ISO8601DateFormatter()
        let startDateTime = formatter.string(from: startDate)
        let endDateTime = formatter.string(from: endDate)
        
        Network.shared.client.fetch(query: GetWorkoutsByDateRangeQuery(startDate: startDateTime, endDate: endDateTime)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let workoutsData = graphQLResult.data?.getWorkoutsByDateRange {
                        // Clear existing workouts for this date range
                        self.clearWorkoutsInRange(from: startDate, to: endDate)
                        
                        // Map and store new workouts
                        for workoutData in workoutsData {
                            let workout = self.mapGraphQLWorkoutToModel(workoutData)
                            if let scheduledDate = workout.scheduledDate {
                                let dateKey = self.calendar.startOfDay(for: scheduledDate)
                                self.workouts[dateKey] = workout
                                
                                // Poll for updates if workout is generating
                                if workout.status.isGenerating {
                                    self.pollForWorkoutUpdate(date: scheduledDate)
                                }
                            }
                        }
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load workouts for the selected week"
                    print("Error fetching workouts by date range: \(error)")
                }
            }
        }
    }
    
    private func mapGraphQLWorkoutToModel(_ workoutData: GetWorkoutByDateQuery.Data.GetWorkoutByDate) -> Workout {
        let components = workoutData.components.map { componentData in
            Component(
                name: componentData.name,
                order: componentData.order,
                definition: componentData.definition,
                description: componentData.description,
                equipment: [], // Not available in GraphQL Component
                muscles: componentData.muscles,
                movements: componentData.movements,
                stimulus: nil, // Not available in GraphQL Component
                targetFitnessDomains: nil,
                energySystems: nil
            )
        }
        
        // Convert DateTime strings to Date objects
        let dateFormatter = ISO8601DateFormatter()
        let scheduledDate = workoutData.scheduledDate.flatMap { dateFormatter.date(from: $0) }
        let completedAt = workoutData.completedAt.flatMap { dateFormatter.date(from: $0) }
        
        return Workout(
            id: workoutData.id,
            name: workoutData.name,
            description: workoutData.description,
            coaching: workoutData.coaching,
            stimulus: workoutData.stimulus,
            scheduledDate: scheduledDate,
            status: WorkoutStatus(rawValue: workoutData.status.rawValue) ?? .pending,
            components: components,
            completedAt: completedAt,
            completed: workoutData.completed
        )
    }
    
    // Overloaded for date range query
    private func mapGraphQLWorkoutToModel(_ workoutData: GetWorkoutsByDateRangeQuery.Data.GetWorkoutsByDateRange) -> Workout {
        let components = workoutData.components.map { componentData in
            Component(
                name: componentData.name,
                order: componentData.order,
                definition: componentData.definition,
                description: componentData.description,
                equipment: [], // Not available in GraphQL Component
                muscles: componentData.muscles,
                movements: componentData.movements,
                stimulus: nil, // Not available in GraphQL Component
                targetFitnessDomains: nil,
                energySystems: nil
            )
        }
        
        // Convert DateTime strings to Date objects
        let dateFormatter = ISO8601DateFormatter()
        let scheduledDate = workoutData.scheduledDate.flatMap { dateFormatter.date(from: $0) }
        let completedAt = workoutData.completedAt.flatMap { dateFormatter.date(from: $0) }
        
        return Workout(
            id: workoutData.id,
            name: workoutData.name,
            description: workoutData.description,
            coaching: workoutData.coaching,
            stimulus: workoutData.stimulus,
            scheduledDate: scheduledDate,
            status: WorkoutStatus(rawValue: workoutData.status.rawValue) ?? .pending,
            components: components,
            completedAt: completedAt,
            completed: workoutData.completed
        )
    }
    
    private func clearWorkoutsInRange(from startDate: Date, to endDate: Date) {
        let keysToRemove = workouts.keys.filter { date in
            date >= startDate && date <= endDate
        }
        
        for key in keysToRemove {
            workouts.removeValue(forKey: key)
        }
    }
    
    private func pollForWorkoutUpdate(date: Date) {
        // Poll every 3 seconds for workout updates when generating
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            
            let dateKey = self.calendar.startOfDay(for: date)
            if let workout = self.workouts[dateKey], workout.status.isGenerating {
                self.loadWorkoutForDate(date)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
