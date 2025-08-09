//
//  WorkoutGeneratorViewModel 2.swift
//  wodAI
//
//  Created by Jordan Littell on 6/7/25.
//


import Foundation
import SwiftUI
import WodAiAPI

// MARK: - Enhanced WorkoutGeneratorViewModel
@MainActor
class EnhancedWorkoutGeneratorViewModel: ObservableObject {
    
    // MARK: - Generation States
    @Published var generating: Bool = false
    @Published var updating: Bool = false
    @Published var generationStep: GenerationStep = .idle
    @Published var generationProgress: Double = 0.0
    
    // MARK: - Current Workout
    @Published var workout: Workout?
    @Published var workoutHistory: [Workout] = []
    
    // MARK: - User Preferences (for intelligent defaults)
    @Published var userPreferences: UserWorkoutPreferences = UserWorkoutPreferences()
    
    // MARK: - Quick Generation Options
    @Published var quickWorkoutType: QuickWorkoutType?
    @Published var lastGeneratedWorkout: Workout?
    
    // MARK: - Generation Flow State
    @Published var flowState: WorkoutFlowState = WorkoutFlowState()
    
    // MARK: - Customization States
    @Published var isCustomizing: Bool = false
    @Published var availableAlternatives: [String: [ExerciseAlternative]] = [:]
    
    // MARK: - Error Handling
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    private let networkService: Network
    private let userPreferencesService: UserPreferencesService
    private let gymProfileManager: GymProfileManager
    private let authProvider: AuthenticationProvider
    
    init(
        generating: Bool = false,
        workout: Workout? = nil,
        networkService: Network = Network.shared,
        userPreferencesService: UserPreferencesService = UserPreferencesService(),
        gymProfileManager: GymProfileManager = GymProfileManager.shared,
        authProvider: AuthenticationProvider = AuthState.shared
    ) {
        self.generating = generating
        self.workout = workout
        self.networkService = networkService
        self.userPreferencesService = userPreferencesService
        self.gymProfileManager = gymProfileManager
        self.authProvider = authProvider
        
        loadUserPreferences()
        setupFlowStateDefaults()
        setupGymProfileListener()
    }
    
    // MARK: - Quick Workout Generation
    func generateQuickWorkout(type: QuickWorkoutType) {
        quickWorkoutType = type
        generating = true
        generationStep = .analyzing
        
        let _ = buildQuickWorkoutPreferences(for: type)
        performGeneration()
    }
    
    private func buildQuickWorkoutPreferences(for type: QuickWorkoutType) -> WorkoutGenerationPreferences {
        // Use equipment from selected gym profile, fallback to user preferences
        let availableEquipment = gymProfileManager.selectedEquipment.isEmpty ? 
            userPreferences.availableEquipment : gymProfileManager.selectedEquipment
        
        switch type {
        case .intelligent:
            return WorkoutGenerationPreferences(
                duration: userPreferences.preferredDuration,
                intensity: userPreferences.preferredIntensity,
                equipment: availableEquipment,
                muscleGroups: [],
                energyLevel: .good,
                isQuick: true,
                useAIRecommendations: true
            )
            
        case .quick20:
            return WorkoutGenerationPreferences(
                duration: 20,
                intensity: .intense,
                equipment: availableEquipment,
                muscleGroups: [],
                energyLevel: .good,
                isQuick: true,
                useAIRecommendations: true
            )
            
        case .fullSession:
            return WorkoutGenerationPreferences(
                duration: 60,
                intensity: .moderate,
                equipment: availableEquipment,
                muscleGroups: [],
                energyLevel: .good,
                isQuick: false,
                useAIRecommendations: true
            )
        }
    }
    
    func generateCustomWorkout() {
        generating = true
        generationStep = .analyzing
        performGeneration()
    }
    
    private func performGeneration() {
        // Debug: Check authentication
        print("🔐 Auth Status: isAuthenticated = \(authProvider.isAuthenticated)")
        
        simulateGenerationSteps()
        
        // Note: The new GraphQL schema doesn't accept any parameters for generateWod
        // The backend will use the user's profile and context to generate appropriate workouts
        print("📤 Sending workout generation request")
        
        networkService.client.perform(mutation: GenerateWODMutation()) { [weak self] result in
            DispatchQueue.main.async {
                self?.generating = false
                self?.generationStep = .complete
                
                switch result {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors, !errors.isEmpty {
                        print("❌ GraphQL Errors: \(errors)")
                        self?.handleGenerationError(errors.first?.message ?? "Generation failed")
                    } else if let wodData: GenerateWODMutation.Data.GenerateWod = graphqlResult.data?.generateWod {
                        print("✅ Workout generated successfully!")
                        
                        let components: [Component] = wodData.components.map { component in
                            Component(
                                name: component.name,
                                order: component.order,
                                definition: component.definition,
                                description: component.description,
                                equipment: [],
                                muscles: [],
                                movements: [],
                                stimulus: nil,
                                targetFitnessDomains: [],
                                energySystems: []
                            )
                        
                        }
                        
                        let newWorkout = Workout(
                            id: wodData.id,
                            name: wodData.name,
                            description: wodData.description,
                            coaching: "Focus on the hips",
                            stimulus: nil,
                            scheduledDate: Date.now,
                            status: WorkoutStatus.generating,
                            components: components,
                            completedAt: nil,
                            completed: false
                        )
                        
                        self?.workout = newWorkout
                        self?.lastGeneratedWorkout = newWorkout
                        self?.addToHistory(newWorkout)
                        self?.loadExerciseAlternatives(for: newWorkout)
                    }
                    
                case .failure(let error):
                    print("❌ Network Error: \(error)")
                    self?.handleGenerationError(error.localizedDescription)
                }
            }
        }
    }
    
    func adjustIntensity(_ adjustment: IntensityAdjustment) {
        guard let currentWorkout = workout else { return }
        
        updating = true
        
        let instruction = buildIntensityInstruction(adjustment)
        
        networkService.client.perform(mutation: UpdateWodMutation(
            updateWodId: currentWorkout.id,
            instructions: instruction
        )) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                self?.updating = false
                
                switch result {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors {
                        self?.handleGenerationError(errors.first?.message ?? "Update failed")
                    } else if let _ = graphqlResult.data?.updateWod {
                        print("✅ Workout updated successfully")
                    }
                    
                case .failure(let error):
                    self?.handleGenerationError(error.localizedDescription)
                }
            }
        }
    }

    func markCompleted() {
        guard let currentWorkout = workout else { return }
        
        userPreferences.lastWorkoutDate = Date()
        userPreferences.totalWorkoutsCompleted += 1
        savePreferences()
        
        print("🎯 Marking workout as completed: \(currentWorkout.id)")
        networkService.client.perform(mutation: CompleteWodMutation(completeWodId: currentWorkout.id)) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        print("❌ Error completing workout: \(errors)")
                        self?.handleGenerationError(errors.first?.message ?? "Failed to complete workout")
                    } else {
                        print("✅ Workout marked as completed")
                        self?.workout = nil
                        // Post notification that workout was completed
                        NotificationCenter.default.post(name: .workoutCompleted, object: nil)
                    }
                case .failure(let error):
                    print("❌ Network error completing workout: \(error)")
                    self?.handleGenerationError(error.localizedDescription)
                }
            }
        }
    }
    
    private func savePreferences() {
        userPreferencesService.savePreferences(userPreferences)
    }
    
    func startWODSession() {
        guard let currentWorkout = workout else { return }
        WODSessionManager.shared.startWOD(currentWorkout)
    }
    
    private func setupFlowStateDefaults() {
        flowState.duration = Double(userPreferences.preferredDuration)
        flowState.intensityLevel = userPreferences.preferredIntensity
        
        let availableEquipment = gymProfileManager.selectedEquipment.isEmpty ? 
            userPreferences.availableEquipment : gymProfileManager.selectedEquipment
        flowState.selectedEquipment = availableEquipment
    }
    
    private func setupGymProfileListener() {
        NotificationCenter.default.addObserver(
            forName: .gymProfileChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.setupFlowStateDefaults()
            }
        }
    }
    
    private func simulateGenerationSteps() {
        let steps: [GenerationStep] = [.analyzing, .selecting, .calculating, .personalizing, .finalizing]
        
        for (index, step) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                self.generationStep = step
                self.generationProgress = Double(index + 1) / Double(steps.count)
            }
        }
    }
    
    
    private func loadUserPreferences() {
        userPreferences = userPreferencesService.loadPreferences()
    }
    
    private func updateUserPreferences(based preferences: WorkoutGenerationPreferences) {
        userPreferences.preferredDuration = preferences.duration
        userPreferences.preferredIntensity = preferences.intensity
        userPreferences.availableEquipment = preferences.equipment
        userPreferencesService.savePreferences(userPreferences)
    }
    
    private func addToHistory(_ workout: Workout) {
        workoutHistory.append(workout)
        if workoutHistory.count > 50 { // Keep last 50 workouts
            workoutHistory.removeFirst()
        }
    }
    
    private func loadExerciseAlternatives(for workout: Workout) {
        // Load alternatives for each exercise in the workout
        // This would call a backend endpoint to get exercise alternatives
    }
    
    private func handleGenerationError(_ message: String) {
        print("🔴 Generation error: \(message)")
        
        // Check if it's an auth error
        if message.lowercased().contains("unauthorized") || 
           message.lowercased().contains("authentication") ||
           message.lowercased().contains("token") {
            print("🔓 Unauthorized error detected in view model - auth handled by Network layer")
            // Auth error is handled by the Network layer's interceptor
            // which will redirect to login automatically
            authProvider.handleSessionExpired()
            
        } else {
            // Show regular error for non-auth issues
            errorMessage = message
            showError = true
        }
        
        generating = false
        updating = false
        generationStep = .idle
    }
    
    
    private func buildIntensityInstruction(_ adjustment: IntensityAdjustment) -> String {
        switch adjustment {
        case .increase:
            return "Increase the intensity by adding more challenging variations and reducing rest time"
        case .decrease:
            return "Decrease the intensity with easier variations and longer rest periods"
        case .addSets:
            return "Add additional sets to increase volume"
        case .reduceSets:
            return "Reduce the number of sets for a shorter workout"
        }
    }
}

// MARK: - Supporting Models
struct WorkoutGenerationPreferences {
    let duration: Int
    let intensity: IntensityLevel
    let equipment: Set<Equipment>
    let muscleGroups: Set<MuscleGroup>
    let energyLevel: EnergyLevel
    let isQuick: Bool
    let useAIRecommendations: Bool
    let contextualPrompt: String?
    
    init(
        duration: Int,
        intensity: IntensityLevel,
        equipment: Set<Equipment>,
        muscleGroups: Set<MuscleGroup>,
        energyLevel: EnergyLevel,
        isQuick: Bool,
        useAIRecommendations: Bool = true,
        contextualPrompt: String? = nil
    ) {
        self.duration = duration
        self.intensity = intensity
        self.equipment = equipment
        self.muscleGroups = muscleGroups
        self.energyLevel = energyLevel
        self.isQuick = isQuick
        self.useAIRecommendations = useAIRecommendations
        self.contextualPrompt = contextualPrompt
    }
    
    func buildDescription() -> String {
        if let prompt = contextualPrompt {
            return prompt
        }
        
        var description = "Generate a \(duration)-minute \(intensity.rawValue) workout"
        
        if !muscleGroups.isEmpty {
            let muscles = muscleGroups.map { $0.rawValue }.joined(separator: ", ")
            description += " focusing on \(muscles)"
        }
        
        if !equipment.isEmpty {
            let equipmentList = equipment.map { $0.name }.joined(separator: ", ")
            description += " using \(equipmentList)"
        }
        
        description += ". Energy level: \(energyLevel.rawValue)."
        
        return description
    }
    
    func calculateWeightParameter() -> Int {
        return Int(intensity.weightMultiplier * Double(energyLevel.skillLevel))
    }
    
    func calculateVolumeParameter() -> Int {
        return duration / 5 // Simple volume calculation
    }
}

// MARK: - Make IntensityLevel Codable
extension IntensityLevel: Codable {
    // IntensityLevel already conforms to String, CaseIterable
    // String-based enums automatically get Codable conformance
}

// MARK: - Make MuscleGroup Codable
extension MuscleGroup: Codable {
    // MuscleGroup already conforms to String, CaseIterable
    // String-based enums automatically get Codable conformance
}

// MARK: - Make EnergyLevel Codable
extension EnergyLevel: Codable {
    // EnergyLevel already conforms to String, CaseIterable
    // String-based enums automatically get Codable conformance
}

struct UserWorkoutPreferences: Codable {
    var preferredDuration: Int = 30
    var preferredIntensity: IntensityLevel = .moderate
    var availableEquipment: Set<Equipment> = []
    var lastWorkoutDate: Date?
    var totalWorkoutsCompleted: Int = 0
    var preferredWorkoutTimes: [String] = []
    var fitnessGoals: [String] = []
    
    // MARK: - Custom Codable Implementation (if needed for Set)
    enum CodingKeys: String, CodingKey {
        case preferredDuration
        case preferredIntensity
        case availableEquipment
        case lastWorkoutDate
        case totalWorkoutsCompleted
        case preferredWorkoutTimes
        case fitnessGoals
    }
    
    init() {
        // Default initializer with default values
    }
    
    init(
        preferredDuration: Int = 30,
        preferredIntensity: IntensityLevel = .moderate,
        availableEquipment: Set<Equipment> = [],
        lastWorkoutDate: Date? = nil,
        totalWorkoutsCompleted: Int = 0,
        preferredWorkoutTimes: [String] = [],
        fitnessGoals: [String] = []
    ) {
        self.preferredDuration = preferredDuration
        self.preferredIntensity = preferredIntensity
        self.availableEquipment = availableEquipment
        self.lastWorkoutDate = lastWorkoutDate
        self.totalWorkoutsCompleted = totalWorkoutsCompleted
        self.preferredWorkoutTimes = preferredWorkoutTimes
        self.fitnessGoals = fitnessGoals
    }
    
    // Custom decoding to handle Set<EquipmentOption>
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        preferredDuration = try container.decodeIfPresent(Int.self, forKey: .preferredDuration) ?? 30
        preferredIntensity = try container.decodeIfPresent(IntensityLevel.self, forKey: .preferredIntensity) ?? .moderate
        
        // Decode Set<Equipment> from Array
        let equipmentArray = try container.decodeIfPresent([Equipment].self, forKey: .availableEquipment) ?? []
        availableEquipment = Set(equipmentArray)
        
        lastWorkoutDate = try container.decodeIfPresent(Date.self, forKey: .lastWorkoutDate)
        totalWorkoutsCompleted = try container.decodeIfPresent(Int.self, forKey: .totalWorkoutsCompleted) ?? 0
        preferredWorkoutTimes = try container.decodeIfPresent([String].self, forKey: .preferredWorkoutTimes) ?? []
        fitnessGoals = try container.decodeIfPresent([String].self, forKey: .fitnessGoals) ?? []
    }
    
    // Custom encoding to handle Set<EquipmentOption>
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(preferredDuration, forKey: .preferredDuration)
        try container.encode(preferredIntensity, forKey: .preferredIntensity)
        
        // Encode Set<Equipment> as Array
        let equipmentArray = Array(availableEquipment)
        try container.encode(equipmentArray, forKey: .availableEquipment)
        
        try container.encodeIfPresent(lastWorkoutDate, forKey: .lastWorkoutDate)
        try container.encode(totalWorkoutsCompleted, forKey: .totalWorkoutsCompleted)
        try container.encode(preferredWorkoutTimes, forKey: .preferredWorkoutTimes)
        try container.encode(fitnessGoals, forKey: .fitnessGoals)
    }
}

struct ExerciseAlternative {
    let id: String
    let name: String
    let difficulty: String
    let equipment: [Equipment]
    let muscleGroups: [MuscleGroup]
}

struct WorkoutSuggestion {
    let type: SuggestionType
    let title: String
    let description: String
    let impact: SuggestionImpact
    
    enum SuggestionType {
        case addCardio, recovery, progression, muscleBalance, equipment
    }
    
    enum SuggestionImpact {
        case positive, neutral, challenging
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .blue
            case .challenging: return .orange
            }
        }
    }
}

enum GenerationStep: String, CaseIterable {
    case idle = "Ready"
    case analyzing = "Analyzing preferences"
    case selecting = "Selecting exercises"
    case calculating = "Calculating sets & reps"
    case personalizing = "Personalizing intensity"
    case finalizing = "Finalizing workout"
    case complete = "Complete"
}

enum IntensityAdjustment {
    case increase, decrease, addSets, reduceSets
}

// MARK: - Service Dependencies
class UserPreferencesService {
    private let userDefaultsKey = "userWorkoutPreferences"
    
    func loadPreferences() -> UserWorkoutPreferences {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let preferences = try? JSONDecoder().decode(UserWorkoutPreferences.self, from: data) else {
            return UserWorkoutPreferences()
        }
        return preferences
    }
    
    func savePreferences(_ preferences: UserWorkoutPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
