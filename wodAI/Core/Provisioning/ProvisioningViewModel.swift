//
//  ProvisioningViewModel.swift
//  wodAI
//
//  Consolidated view model for collecting all user provisioning data
//

import Foundation
import SwiftUI
import Combine
import WodAiAPI

class ProvisioningViewModel: ObservableObject {
    @Published var currentStep: ProvisioningStep = .equipment
    @Published var provisioningData = ConsolidatedProvisioningData()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var availableEquipment: [Equipment] = []
    
    // MARK: - Dependencies
    private let provisioningProvider: ProvisioningProvider
    private let provisioningService: ProvisioningService
    private let equipmentManager: EquipmentManager
    private var cancellables = Set<AnyCancellable>()

    init(provisioningProvider: ProvisioningProvider = AuthState.shared,
         provisioningService: ProvisioningService = ProvisioningService.shared,
         equipmentManager: EquipmentManager = EquipmentManager.shared) {
        self.provisioningProvider = provisioningProvider
        self.provisioningService = provisioningService
        self.equipmentManager = equipmentManager

        equipmentManager.$equipment
            .receive(on: DispatchQueue.main)
            .sink { [weak self] equipment in
                self?.availableEquipment = equipment
            }
            .store(in: &cancellables)
    }
    
    enum ProvisioningStep: Int, CaseIterable {
        case equipment = 0
        case gender = 1
        case fitnessLevel = 2

        var title: String {
            switch self {
            case .equipment: return "What equipment do you have?"
            case .gender: return "What is your gender?"
            case .fitnessLevel: return "What is your fitness level?"
            }
        }

        var subtitle: String {
            switch self {
            case .equipment: return "We'll only show workouts with equipment you have access to"
            case .gender: return "This helps us tailor your workout programming"
            case .fitnessLevel: return "Where are you in your fitness journey?"
            }
        }

        var icon: String {
            switch self {
            case .equipment: return "dumbbell"
            case .gender: return "person.2"
            case .fitnessLevel: return "trophy"
            }
        }
    }
    
    var progress: Double {
        let currentIndex = Double(currentStep.rawValue)
        let totalSteps = Double(ProvisioningStep.allCases.count)
        return (currentIndex + 1) / totalSteps
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .equipment:
            return !provisioningData.availableEquipment.isEmpty
        case .gender:
            return provisioningData.gender != nil
        case .fitnessLevel:
            return provisioningData.fitnessLevel != nil
        }
    }

    var isLastStep: Bool {
        return currentStep == .fitnessLevel
    }
    
    func nextStep() {
        if isLastStep {
            submitProvisioning()
        } else if let nextStep = ProvisioningStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = nextStep
            }
        }
    }
    
    func previousStep() {
        if let previousStep = ProvisioningStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = previousStep
            }
        }
    }
    
    // MARK: - Update Methods
    func updateAge(_ age: Double) {
        provisioningData.age = Int(age)
    }
    
    func updateHeight(feet: Double, inches: Double) {
        provisioningData.heightFeet = Int(feet)
        provisioningData.heightInches = Int(inches)
    }
    
    func updateWeight(_ weight: Double) {
        provisioningData.weight = Int(weight)
    }
    
    func toggleRestDay(_ day: DayOfWeek) {
        if provisioningData.restDays.contains(day) {
            provisioningData.restDays.remove(day)
        } else if provisioningData.restDays.count < 3 {
            provisioningData.restDays.insert(day)
        }
    }
    
    func toggleEquipment(_ equipment: Equipment) {
        if provisioningData.availableEquipment.contains(equipment) {
            provisioningData.availableEquipment.remove(equipment)
        } else {
            provisioningData.availableEquipment.insert(equipment)
        }
    }
    
    func selectAllEquipment() {
        provisioningData.availableEquipment = Set(availableEquipment)
    }
    
    func clearAllEquipment() {
        provisioningData.availableEquipment.removeAll()
    }
    
    func loadEquipment() {
        equipmentManager.fetchEquipment()
    }
    
    func addInjury(_ injury: Injury) {
        provisioningData.injuries.append(injury)
    }
    
    func removeInjury(at index: Int) {
        provisioningData.injuries.remove(at: index)
    }
    
    func removeInjuries() {
        provisioningData.injuries.removeAll()
    }
    
    // MARK: - Submission
    private func submitProvisioning() {
        guard provisioningData.isComplete else {
            errorMessage = "Please complete all required fields"
            showError = true
            return
        }
        
        isLoading = true
        
        let request = ProvisionUserInput(
            age: 25,
            heightInches: 67,
            weight: 150,
            gender: GraphQLEnum(provisioningData.gender!.toGraphQL),
            fitnessLevel: GraphQLEnum(provisioningData.fitnessLevel!.toGraphQL),
            workoutDuration: 60,
            benchmarks: [],
            injuries: GraphQLNullable.none,
            availableEquipment: provisioningData.graphQLEquipment(),
            sessionDurationMinutes: 60,
            restDays: []
        )
        
        Task {
            do {
                let response = try await provisioningService.provisionUser(request: request)
                
                await MainActor.run {
                    self.isLoading = false

                    if response.success {
                        self.provisioningProvider.completeProvisioning()
                        TelemetryService.captureMessage("provisioning.completed")
                        NotificationCenter.default.post(name: .userDidCompleteProvisioning, object: nil)
                    } else {
                        self.errorMessage = response.message ?? "Provisioning failed"
                        self.showError = true
                        TelemetryService.captureMessage("provisioning.failed", level: .error, tags: ["error": self.errorMessage])
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    TelemetryService.captureError(error)
                }
            }
        }
    }
}

// MARK: - Data Models

struct ConsolidatedProvisioningData: Codable {
    // Basic Information
    var age: Int = 25
    var heightFeet: Int = 5
    var heightInches: Int = 0
    var weight: Int = 150
    var gender: Gender?
    var hasInjuries = false
    
    // Fitness Information
    var fitnessLevel: FitnessLevel?
    var restDays: Set<DayOfWeek> = []
    var gymFrequency: GymFrequency?
    
    // Health Information
    var injuries: [Injury] = []
    
    // Equipment
    var availableEquipment: Set<Equipment> = []
    
    var totalHeightInches: Int {
        return heightFeet * 12 + heightInches
    }
    
    func getInjuries () -> [WodAiAPI.InjuryInput] {
        return injuries.compactMap { injury in
            
            return InjuryInput(
                bodyPart: injury.bodyPart,
                severity: GraphQLEnum(InjurySeverity(
                    rawValue: injury.severity.rawValue
                )?.rawValue ?? ""),
                description: GraphQLNullable.some(injury.description ?? "")
            )
        }
    }
    
    var isComplete: Bool {
        return gender != nil &&
               fitnessLevel != nil &&
               !availableEquipment.isEmpty
    }
    
    func graphQLRestDays() -> [GraphQLEnum<WodAiAPI.RestDay>] {
        return restDays.compactMap { iosDayOfWeek in
            let graphQLRestDay: WodAiAPI.RestDay
            
            switch iosDayOfWeek {
            case .monday: graphQLRestDay = .monday
            case .tuesday: graphQLRestDay = .tuesday
            case .wednesday: graphQLRestDay = .wednesday
            case .thursday: graphQLRestDay = .thursday
            case .friday: graphQLRestDay = .friday
            case .saturday: graphQLRestDay = .saturday
            case .sunday: graphQLRestDay = .sunday
            }
            
            return GraphQLEnum(graphQLRestDay)
        }
    }
    
    func graphQLEquipment() -> [GraphQLEnum<WodAiAPI.FitnessEquipment>] {
        return availableEquipment.compactMap { equipment in
            // Map Equipment to GraphQL FitnessEquipment
            // This mapping depends on your Equipment model and GraphQL schema
            switch equipment.name.lowercased() {
            case "barbell", "barbells":
                return GraphQLEnum(WodAiAPI.FitnessEquipment.barbells)
            case "pull-up bar", "pullup bar", "pull up bar":
                return GraphQLEnum(WodAiAPI.FitnessEquipment.pullUpBars)
            case "dumbbell", "dumbbells":
                return GraphQLEnum(WodAiAPI.FitnessEquipment.dumbbells)
            case "kettlebell", "kettlebells":
                return GraphQLEnum(WodAiAPI.FitnessEquipment.kettlebells)
            default:
                return GraphQLEnum(WodAiAPI.FitnessEquipment.barbells) // Default fallback
            }
        }
    }
}

enum GymFrequency: String, CaseIterable, Codable {
    case rarely = "rarely"
    case onceAWeek = "once_a_week"
    case twiceAWeek = "twice_a_week"
    case threeTimesAWeek = "three_times_a_week"
    case fourTimesAWeek = "four_times_a_week"
    case fiveTimesAWeek = "five_times_a_week"
    case sixTimesAWeek = "six_times_a_week"
    case daily = "daily"
    
    var displayName: String {
        switch self {
        case .rarely: return "Rarely (< 1x/week)"
        case .onceAWeek: return "Once a week"
        case .twiceAWeek: return "Twice a week"
        case .threeTimesAWeek: return "3 times a week"
        case .fourTimesAWeek: return "4 times a week"
        case .fiveTimesAWeek: return "5 times a week"
        case .sixTimesAWeek: return "6 times a week"
        case .daily: return "Every day"
        }
    }
    
    var description: String {
        switch self {
        case .rarely: return "Just getting started or very busy schedule"
        case .onceAWeek: return "Light activity, maintenance focused"
        case .twiceAWeek: return "Beginner friendly, sustainable pace"
        case .threeTimesAWeek: return "Most popular choice for steady progress"
        case .fourTimesAWeek: return "Serious about fitness goals"
        case .fiveTimesAWeek: return "Advanced training schedule"
        case .sixTimesAWeek: return "Elite level commitment"
        case .daily: return "Professional athlete or extreme dedication"
        }
    }
    
    var sessionDurationMinutes: Int {
        switch self {
        case .rarely, .onceAWeek: return 90
        case .twiceAWeek, .threeTimesAWeek: return 60
        case .fourTimesAWeek, .fiveTimesAWeek: return 45
        case .sixTimesAWeek, .daily: return 30
        }
    }
}

// MARK: - Equipment Model (if not already defined)
struct Equipment: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let category: String?
    
    var icon: String {
        switch name.lowercased() {
        case "barbell", "barbells": return "barbell"
        case "pull-up bar", "pullup bar", "pull up bar": return "arrow.up.and.down"
        case "dumbbell", "dumbbells": return "dumbbell"
        case "kettlebell", "kettlebells": return "figure.strengthtraining.traditional"
        case "rowing machine", "erg", "rower": return "figure.rowing"
        case "assault bike", "bike": return "bicycle"
        case "jump rope", "rope": return "figure.jumprope"
        case "box", "jump box": return "cube.box"
        case "wall ball", "medicine ball": return "soccerball"
        case "ab mat": return "figure.core.training"
        case "ghd", "ghd machine": return "figure.strengthtraining.traditional"
        case "bands", "resistance bands": return "oval.portrait"
        case "sled": return "triangle"
        default: return "dumbbell"
        }
    }
}



struct InjuryRow: View {
    let injury: Injury
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(injury.bodyPart)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("PrimaryText"))
                
                Text(injury.severity.displayName)
                    .font(.caption)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.1))
                    .cornerRadius(4)
                
                if let description = injury.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Color("Warning"))
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }
    
    private var severityColor: Color {
        switch injury.severity {
        case .minor: return Color("Success")
        case .moderate: return Color("Warning")
        case .severe: return Color("Warning")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidCompleteProvisioning = Notification.Name("userDidCompleteProvisioning")
}
