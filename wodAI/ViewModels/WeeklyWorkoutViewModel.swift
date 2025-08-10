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
    
    private let calendar = DateUtility.deviceCalendar
    
    // MARK: - Date Formatting Helpers
    
    private func formatDateForGraphQL(_ date: Date) -> String {
        return DateUtility.formatDateForGraphQL(date)
    }
    
    private func parseDateFromGraphQL(_ dateTimeString: String?) -> Date? {
        return DateUtility.parseDateFromGraphQL(dateTimeString)
    }
    
    // MARK: - Computed Properties
    
    var workoutForSelectedDate: Workout? {
        let dateKey = DateUtility.startOfDay(for: selectedDate)
        return workouts[dateKey]
    }
    
    var isLoadingWorkoutForSelectedDate: Bool {
        guard let workout = workoutForSelectedDate else { return isLoading }
        return workout.shouldShowLoadingState
    }
    
    // MARK: - Public Methods
    
    func loadWorkoutsForWeek(containing date: Date) {
        // Get proper week boundaries
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { 
            print("❌ Could not calculate week interval for date: \(date)")
            return 
        }
        
        let startDate = weekInterval.start
        // Calculate proper end date - weekInterval.end is exclusive (start of next week)
        // We want the last day of the current week (Saturday)
        let endDate = calendar.date(byAdding: .day, value: -1, to: weekInterval.end)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        formatter.timeZone = TimeZone.current
        
        print("📅 Loading workouts for week: \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))")
        print("🕐 Device timezone: \(TimeZone.current.identifier)")
        
        loadWorkouts(from: startDate, to: endDate)
    }
    
    func loadWorkoutForDate(_ date: Date) {
        isLoading = true
        errorMessage = nil
        
        let dateKey = DateUtility.startOfDay(for: date)
        let dateTimeInput = formatDateForGraphQL(date)
        
        print("📅 Loading workout for date: \(date) (formatted: \(dateTimeInput))")
        
        Network.shared.client.fetch(query: GetWorkoutByDateQuery(date: dateTimeInput)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let workoutData = graphQLResult.data?.getWorkoutByDate {
                        let workout = self.mapGraphQLWorkoutToModel(workoutData)
                        self.workouts[dateKey] = workout
                        print("✅ Loaded workout: \(workout.name) for \(dateKey)")
                        print("✅   Components loaded: \(workout.components.count)")
                        if !workout.components.isEmpty {
                            workout.components.forEach { component in
                                print("✅     - \(component.name): \(component.definition.prefix(50))...")
                            }
                        }
                        
                        // If workout is still generating, poll for updates
                        if workout.status.isGenerating {
                            self.pollForWorkoutUpdate(date: date)
                        }
                    } else {
                        // No workout found for this date
                        self.workouts[dateKey] = nil
                        print("ℹ️ No workout found for date: \(dateKey)")
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load workout for \(self.formatDate(date))"
                    print("❌ Error fetching workout for date: \(error)")
                }
            }
        }
    }
    
    func generateWorkoutSchedule() {
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
                            print("✅ Workout schedule generated successfully")
                            // Refresh current week view
                            self.loadWorkoutsForWeek(containing: self.selectedDate)
                        } else {
                            self.errorMessage = response.message
                            print("❌ Workout schedule generation failed: \(response.message)")
                        }
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to generate workout schedule"
                    print("❌ Error generating workout schedule: \(error)")
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
        
        // Use consistent formatting for both date range endpoints
        let startDateTime = formatDateForGraphQL(startDate)
        let endDateTime = formatDateForGraphQL(endDate)
        
        let debugFormatter = DateFormatter()
        debugFormatter.dateFormat = "EEE MMM d, yyyy"
        debugFormatter.timeZone = TimeZone.current
        
        print("📊 Fetching workouts:")
        print("   From: \(debugFormatter.string(from: startDate)) -> \(startDateTime)")
        print("   To:   \(debugFormatter.string(from: endDate)) -> \(endDateTime)")
        
        Network.shared.client.fetch(query: GetWorkoutsByDateRangeQuery(startDate: startDateTime, endDate: endDateTime)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let workoutsData = graphQLResult.data?.getWorkoutsByDateRange {
                        print("✅ Received \(workoutsData.count) workouts from API")
                        
                        // Clear existing workouts for this date range
                        self.clearWorkoutsInRange(from: startDate, to: endDate)
                        
                        // Map and store new workouts
                        for workoutData in workoutsData {
                            let workout = self.mapGraphQLWorkoutToModel(workoutData)
                            
                            if let scheduledDate = workout.scheduledDate {
                                let dateKey = DateUtility.startOfDay(for: scheduledDate)
                                
                                // Check for duplicate dates and prioritize workouts with components
                                if let existingWorkout = self.workouts[dateKey] {
                                    if workout.components.isEmpty && !existingWorkout.components.isEmpty {
                                        print("⚠️ Skipping duplicate workout '\(workout.name)' with no components - keeping existing '\(existingWorkout.name)' with \(existingWorkout.components.count) components")
                                        continue // Skip this workout, keep the existing one
                                    } else if !workout.components.isEmpty && existingWorkout.components.isEmpty {
                                        print("✅ Replacing incomplete workout '\(existingWorkout.name)' with complete '\(workout.name)' (\(workout.components.count) components)")
                                    } else {
                                        print("⚠️ Duplicate workout for \(DateUtility.shortDateFormatter.string(from: scheduledDate)): '\(existingWorkout.name)' vs '\(workout.name)' - using latest")
                                    }
                                }
                                
                                self.workouts[dateKey] = workout
                                
                                print("📝 Stored workout '\(workout.name)' for date: \(dateKey)")
                                print("📝   Components stored: \(workout.components.count)")
                                if !workout.components.isEmpty {
                                    workout.components.forEach { component in
                                        print("📝     - \(component.name): \(component.definition.prefix(50))...")
                                    }
                                }
                                
                                // Poll for updates if workout is generating
                                if workout.status.isGenerating {
                                    self.pollForWorkoutUpdate(date: scheduledDate)
                                }
                            } else {
                                print("⚠️ Workout '\(workout.name)' has no scheduled date, skipping")
                            }
                        }
                        
                        print("📊 Total workouts in memory: \(self.workouts.count)")
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load workouts for the selected week"
                    print("❌ Error fetching workouts by date range: \(error)")
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
        
        // Parse DateTime strings to Date objects, extracting only date part
        let scheduledDate = parseDateFromGraphQL(workoutData.scheduledDate)
        let completedAt = parseDateFromGraphQL(workoutData.completedAt)
        
        let workout = Workout(
            id: workoutData.id,
            name: workoutData.name,
            description: workoutData.description,
            coaching: workoutData.coaching,
            stimulus: workoutData.stimulus,
            scheduledDate: scheduledDate,
            status: WorkoutStatus(rawValue: workoutData.status.rawValue) ?? .generating,
            components: components,
            completedAt: completedAt,
            completed: workoutData.completed
        )
        
        #if DEBUG
        print("🔄 Mapped single workout: '\(workout.name)' with \(components.count) components")
        if components.isEmpty {
            print("⚠️ WARNING: Workout '\(workout.name)' has no components!")
            print("   Raw components data: \(workoutData.components)")
        } else {
            print("   Components: \(components.map { $0.name }.joined(separator: ", "))")
        }
        #endif
        
        return workout
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
        
        // Parse DateTime strings to Date objects, extracting only date part
        let scheduledDate = parseDateFromGraphQL(workoutData.scheduledDate)
        let completedAt = parseDateFromGraphQL(workoutData.completedAt)
        
        let workout = Workout(
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
        
        #if DEBUG
        print("🔄 Mapped bulk workout: '\(workout.name)' with \(components.count) components")
        if components.isEmpty {
            print("⚠️ WARNING: Workout '\(workout.name)' has no components!")
            print("   Raw components data: \(workoutData.components)")
        } else {
            print("   Components: \(components.map { $0.name }.joined(separator: ", "))")
        }
        #endif
        
        return workout
    }
    
    private func clearWorkoutsInRange(from startDate: Date, to endDate: Date) {
        let keysToRemove = workouts.keys.filter { date in
            date >= startDate && date <= endDate
        }
        
        for key in keysToRemove {
            workouts.removeValue(forKey: key)
        }
        
        print("🧹 Cleared \(keysToRemove.count) existing workouts from range")
    }
    
    private func pollForWorkoutUpdate(date: Date) {
        // Poll every 30 seconds for workout updates when generating
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            guard let self = self else { return }
            
            let dateKey = DateUtility.startOfDay(for: date)
            if let workout = self.workouts[dateKey], workout.status.isGenerating {
                print("🔄 Polling for workout update: \(workout.name)")
                self.loadWorkoutForDate(date)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        return DateUtility.displayDateFormatter.string(from: date)
    }
    
    // MARK: - Debug Helper
    
    #if DEBUG
    func debugWorkoutData(for date: Date) {
        let dateKey = DateUtility.startOfDay(for: date)
        if let workout = workouts[dateKey] {
            print("🔍 Debug workout data for \(DateUtility.shortDateFormatter.string(from: date)):")
            print("   Name: \(workout.name)")
            print("   ID: \(workout.id)")
            print("   Status: \(workout.status)")
            print("   Components count: \(workout.components.count)")
            print("   Description: \(workout.description.prefix(100))...")
            print("   Coaching: \(workout.coaching?.prefix(100) ?? "nil")...")
            
            for (index, component) in workout.components.enumerated() {
                print("   Component \(index + 1): \(component.name)")
                print("     Definition: \(component.definition.prefix(100))...")
                print("     Order: \(component.order)")
                print("     Muscles: \(component.muscles.joined(separator: ", "))")
            }
        } else {
            print("🔍 No workout found for \(DateUtility.shortDateFormatter.string(from: date))")
        }
    }
    #endif
}
