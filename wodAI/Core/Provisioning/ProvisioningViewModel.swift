//
//  ProvisioningViewModel.swift
//  wodAI
//
//  Created for WodAI provisioning workflow
//

import Foundation
import SwiftUI

class ProvisioningViewModel: ObservableObject {
    @Published var currentStep: ProvisioningStep = .gender
    @Published var provisioningData = ProvisioningData()
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    // Benchmark input states
    @Published var selectedBenchmarks: Set<BenchmarkType> = []
    @Published var benchmarkInputs: [BenchmarkType: String] = [:]
    
    // Injury input states
    @Published var selectedInjuries: [Injury] = []
    @Published var showAddInjurySheet = false
    
    // MARK: - Dependencies
    private let provisioningProvider: ProvisioningProvider
    private let provisioningService: ProvisioningService
    
    init(provisioningProvider: ProvisioningProvider = AuthState.shared,
         provisioningService: ProvisioningService = ProvisioningService.shared) {
        self.provisioningProvider = provisioningProvider
        self.provisioningService = provisioningService
    }
    
    enum ProvisioningStep: Int, CaseIterable {
        case gender = 0
        case fitnessLevel = 1
        case workoutDuration = 2
        case benchmarks = 3
        case injuries = 4
        
        var title: String {
            switch self {
            case .gender: return "Personal Details"
            case .fitnessLevel: return "Fitness Level"
            case .workoutDuration: return "Workout Duration"
            case .benchmarks: return "Performance Benchmarks"
            case .injuries: return "Injuries & Limitations"
            }
        }
        
        var subtitle: String {
            switch self {
            case .gender: return "Help us personalize your experience"
            case .fitnessLevel: return "Where are you in your fitness journey?"
            case .workoutDuration: return "How much time do you have to train?"
            case .benchmarks: return "Help us calibrate your workouts"
            case .injuries: return "Any areas we should be careful with?"
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
        case .gender:
            return provisioningData.gender != nil
        case .fitnessLevel:
            return provisioningData.fitnessLevel != nil
        case .workoutDuration:
            return provisioningData.workoutDuration != nil
        case .benchmarks:
            return !selectedBenchmarks.isEmpty && allSelectedBenchmarksHaveValues
        case .injuries:
            return true // Injuries are optional
        }
    }
    
    private var allSelectedBenchmarksHaveValues: Bool {
        for benchmark in selectedBenchmarks {
            guard let value = benchmarkInputs[benchmark], !value.isEmpty else {
                return false
            }
            
            // Validate the input format
            if benchmark == .runMile {
                // Check for valid time format (mm:ss)
                let components = value.split(separator: ":")
                guard components.count == 2,
                      let minutes = Int(components[0]),
                      let seconds = Int(components[1]),
                      minutes >= 0,
                      seconds >= 0 && seconds < 60 else {
                    return false
                }
            } else {
                // Check for valid numeric input
                guard Double(value) != nil else {
                    return false
                }
            }
        }
        return true
    }
    
    func nextStep() {
        // Save current step data
        switch currentStep {
        case .benchmarks:
            saveBenchmarks()
        case .injuries:
            provisioningData.injuries = selectedInjuries
        default:
            break
        }
        
        if currentStep == .injuries {
            // This is the last step, submit the data
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
    
    private func saveBenchmarks() {
        provisioningData.benchmarks = selectedBenchmarks.compactMap { benchmark in
            guard let value = benchmarkInputs[benchmark], !value.isEmpty else { return nil }
            return BenchmarkValue(type: benchmark, value: value)
        }
    }
    
    func toggleBenchmark(_ benchmark: BenchmarkType) {
        if selectedBenchmarks.contains(benchmark) {
            selectedBenchmarks.remove(benchmark)
            benchmarkInputs[benchmark] = nil
        } else {
            selectedBenchmarks.insert(benchmark)
        }
    }
    
    func addInjury(_ injury: Injury) {
        selectedInjuries.append(injury)
        provisioningData.hasInjuries = true
    }
    
    func removeInjury(at index: Int) {
        selectedInjuries.remove(at: index)
        provisioningData.hasInjuries = !selectedInjuries.isEmpty
    }
    
    private func submitProvisioning() {
        isLoading = true
        
        // Prepare the request
        let benchmarks = provisioningData.benchmarks.compactMap { benchmark -> ProvisionUserRequest.BenchmarkData? in
            guard let numericValue = benchmark.numericValue else { return nil }
            return ProvisionUserRequest.BenchmarkData(
                type: benchmark.type.rawValue,
                value: numericValue,
                unit: benchmark.type.unit
            )
        }
        
        let injuries = provisioningData.injuries.map { injury in
            ProvisionUserRequest.InjuryData(
                bodyPart: injury.bodyPart,
                severity: injury.severity.rawValue,
                description: injury.description
            )
        }
        
        let request = ProvisionUserRequest(
            gender: provisioningData.gender ?? Gender.male,
            fitnessLevel: provisioningData.fitnessLevel ?? FitnessLevel.intermediate,
            workoutDuration: provisioningData.workoutDuration?.minutes ?? 60,
            benchmarks: benchmarks,
            injuries: injuries
        )
        
        Task {
            do {
                let response = try await provisioningService.provisionUser(request: request)
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if response.success {
                        print("✅ User provisioned successfully")
                        
                        // Mark user as provisioned through the provider
                        self.provisioningProvider.completeProvisioning()
                        
                        // Notify the app that provisioning is complete
                        NotificationCenter.default.post(name: .userDidCompleteProvisioning, object: nil)
                    } else {
                        self.errorMessage = response.message ?? "Provisioning failed"
                        self.showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidCompleteProvisioning = Notification.Name("userDidCompleteProvisioning")
}
