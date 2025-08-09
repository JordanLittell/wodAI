//
//  ProvisioningModels.swift
//  wodAI
//
//  Created for WodAI provisioning workflow
//

import Foundation

// MARK: - Gender
enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    case preferNotToSay = "prefer_not_to_say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

// MARK: - Fitness Level
enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"
    case elite = "ELITE"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .elite: return "Elite"
        }
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "New to fitness or returning after a break"
        case .intermediate:
            return "Consistent training for 6+ months"
        case .advanced:
            return "Training consistently for 2+ years"
        case .elite:
            return "Competitive athlete or 5+ years experience"
        }
    }
}

// MARK: - Workout Duration
enum WorkoutDuration: String, CaseIterable, Codable {
    case thirtyMinutes = "30_minutes"
    case fortyFiveMinutes = "45_minutes"
    case sixtyMinutes = "60_minutes"
    case ninetyMinutes = "90_minutes"
    
    var displayName: String {
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .fortyFiveMinutes: return "45 minutes"
        case .sixtyMinutes: return "60 minutes"
        case .ninetyMinutes: return "90 minutes"
        }
    }
    
    var minutes: Int {
        switch self {
        case .thirtyMinutes: return 30
        case .fortyFiveMinutes: return 45
        case .sixtyMinutes: return 60
        case .ninetyMinutes: return 90
        }
    }
}

// MARK: - Benchmark Type
enum BenchmarkType: String, CaseIterable, Codable {
    case squat = "squat"
    case deadlift = "deadlift"
    case benchPress = "bench_press"
    case overheadPress = "overhead_press"
    case pullUps = "pull_ups"
    case runMile = "run_mile"
    
    var displayName: String {
        switch self {
        case .squat: return "Back Squat"
        case .deadlift: return "Deadlift"
        case .benchPress: return "Bench Press"
        case .overheadPress: return "Overhead Press"
        case .pullUps: return "Pull-ups"
        case .runMile: return "1 Mile Run"
        }
    }
    
    var unit: String {
        switch self {
        case .squat, .deadlift, .benchPress, .overheadPress:
            return "lbs"
        case .pullUps:
            return "reps"
        case .runMile:
            return "min:sec"
        }
    }
    
    var icon: String {
        switch self {
        case .squat: return "figure.strengthtraining.traditional"
        case .deadlift: return "figure.strengthtraining.traditional"
        case .benchPress: return "figure.strengthtraining.traditional"
        case .overheadPress: return "figure.strengthtraining.traditional"
        case .pullUps: return "arrow.up.and.down"
        case .runMile: return "figure.run"
        }
    }
}

// MARK: - Benchmark Value
struct BenchmarkValue: Codable {
    let type: BenchmarkType
    let value: String // Store as string to handle both numbers and time formats
    
    var numericValue: Double? {
        if type == .runMile {
            // Convert "min:sec" to total seconds
            let components = value.split(separator: ":")
            guard components.count == 2,
                  let minutes = Double(components[0]),
                  let seconds = Double(components[1]) else { return nil }
            return minutes * 60 + seconds
        } else {
            return Double(value)
        }
    }
}

// MARK: - Injury Type
struct Injury: Codable {
    let bodyPart: String
    let severity: InjurySeverity
    let description: String?
    
    enum InjurySeverity: String, CaseIterable, Codable {
        case minor = "minor"
        case moderate = "moderate"
        case severe = "severe"
        
        var displayName: String {
            switch self {
            case .minor: return "Minor"
            case .moderate: return "Moderate"
            case .severe: return "Severe"
            }
        }
    }
}

// MARK: - Common Body Parts
enum BodyPart: String, CaseIterable, Codable {
    case shoulder = "shoulder"
    case knee = "knee"
    case back = "back"
    case wrist = "wrist"
    case ankle = "ankle"
    case hip = "hip"
    case elbow = "elbow"
    case neck = "neck"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .shoulder: return "Shoulder"
        case .knee: return "Knee"
        case .back: return "Back"
        case .wrist: return "Wrist"
        case .ankle: return "Ankle"
        case .hip: return "Hip"
        case .elbow: return "Elbow"
        case .neck: return "Neck"
        case .other: return "Other"
        }
    }
}

// MARK: - Provisioning Data
struct ProvisioningData: Codable {
    var gender: Gender?
    var fitnessLevel: FitnessLevel?
    var workoutDuration: WorkoutDuration?
    var benchmarks: [BenchmarkValue] = []
    var injuries: [Injury] = []
    var hasInjuries: Bool = false
    
    var isComplete: Bool {
        return gender != nil &&
               fitnessLevel != nil &&
               workoutDuration != nil &&
               !benchmarks.isEmpty
    }
}

// MARK: - API Models
struct ProvisionUserRequest: Codable {
    let gender: Gender
    let fitnessLevel: FitnessLevel
    let workoutDuration: Int // in minutes
    let benchmarks: [BenchmarkData]
    let injuries: [InjuryData]
    
    struct BenchmarkData: Codable {
        let type: String
        let value: Double
        let unit: String
    }
    
    struct InjuryData: Codable {
        let bodyPart: String
        let severity: String
        let description: String?
    }
}

struct ProvisionUserResponse: Codable {
    let success: Bool
    let message: String?
    let userId: String?
}
