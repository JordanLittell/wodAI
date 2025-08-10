//
//  ProvisioningModels.swift
//  wodAI
//
//  Created for WodAI provisioning workflow
//

import Foundation
import WodAiAPI

// MARK: - Gender
enum Gender: String, CaseIterable, Codable {
    case male = "MALE"
    case female = "FEMALE"
    case other = "OTHER"
    case preferNotToSay = "PREFER_NOT_TO_SAY"
    
    var displayName: String {
        switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .other: return "Other"
            case .preferNotToSay: return "Prefer not to say"
        }
    }
    
    var icon: String {
        switch self {
            case .male: return "person.fill"
            case .female: return "person.fill"
            case .other: return "person.2.fill"
            case .preferNotToSay: return "questionmark.circle.fill"
        }
    }
    
    var toGraphQL: WodAiAPI.Gender {
        switch self {
            case .male: return WodAiAPI.Gender.male
            case .female: return WodAiAPI.Gender.female
            case .other: return WodAiAPI.Gender.male // Default fallback
            case .preferNotToSay: return WodAiAPI.Gender.male // Default fallback
        }
    }
}



// MARK: - Fitness Level
enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"
    case elite = "ELITE"
    case pro = "PRO"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .elite: return "Elite"
        case .pro: return "Pro"
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
        case .pro:
            return "Professional level athlete"
        }
    }
    
    var toGraphQL: WodAiAPI.FitnessLevel {
        switch self {
            case .beginner: return WodAiAPI.FitnessLevel.beginner
            case .intermediate: return WodAiAPI.FitnessLevel.intermediate
            case .advanced: return WodAiAPI.FitnessLevel.advanced
            case .elite: return WodAiAPI.FitnessLevel.elite
            case .pro: return WodAiAPI.FitnessLevel.pro
        }
    }
    
    var detailedDescription: String {
        switch self {
        case .beginner:
            return "You train 1-3 hours per week. You're new to CrossFit or fitness in general. Most movements need significant scaling - lighter weights, assisted movements, and modified ranges of motion. You focus on learning proper form and building basic fitness capacity."
        case .intermediate:
            return "You train 3-6 hours per week. You've been doing CrossFit for 6+ months and can perform most WODs with some scaling. You can do basic movements like air squats, push-ups, and pull-ups but still need modifications for advanced gymnastics and heavy lifting."
        case .advanced:
            return "You train 6-10 hours per week. You regularly do RX workouts without much difficulty and can perform advanced gymnastics such as ring muscle-ups. You are capable of handling intense WODs that are over 20 minutes and have solid strength across all major lifts."
        case .elite:
            return "You train 10-15 hours per week. You consistently perform RX+ workouts and compete in local CrossFit competitions. You have advanced skills in Olympic lifting, gymnastics, and can maintain high intensity for extended periods. You rarely need to scale movements."
        case .pro:
            return "You train 15+ hours per week. You compete at regional or national CrossFit competitions. You excel in all aspects of fitness and can perform complex movements under extreme fatigue. You often exceed RX standards and serve as a benchmark for others."
        }
    }
    
    var weeklyHours: String {
        switch self {
        case .beginner: return "1-3 hours/week"
        case .intermediate: return "3-6 hours/week"
        case .advanced: return "6-10 hours/week"
        case .elite: return "10-15 hours/week"
        case .pro: return "15+ hours/week"
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

// MARK: - Enhanced Time Duration Options
enum TimeDuration: String, CaseIterable, Codable {
    case thirtyMinutes = "30_minutes"
    case fortyFiveMinutes = "45_minutes"
    case oneHour = "60_minutes"
    case oneAndHalfHours = "90_minutes"
    case twoOrMoreHours = "120_plus_minutes"
    
    var displayName: String {
        switch self {
        case .thirtyMinutes: return "30 min"
        case .fortyFiveMinutes: return "45 min"
        case .oneHour: return "1 hour"
        case .oneAndHalfHours: return "1.5 hours"
        case .twoOrMoreHours: return "2+ hours"
        }
    }
    
    var minutes: Int {
        switch self {
        case .thirtyMinutes: return 30
        case .fortyFiveMinutes: return 45
        case .oneHour: return 60
        case .oneAndHalfHours: return 90
        case .twoOrMoreHours: return 120
        }
    }
}

// MARK: - Equipment Options
enum EquipmentOption: String, CaseIterable, Codable {
    case barbell = "barbell"
    case pullUpBar = "pull_up_bar"
    case erg = "erg"
    case ski = "ski"
    case assaultBike = "assault_bike"
    case kettlebell = "kettlebell"
    case dumbbell = "dumbbell"
    case abMat = "ab_mat"
    case wallBall = "wall_ball"
    case jumpRope = "jump_rope"
    case box = "box"
    case ghdMachine = "ghd_machine"
    case bands = "bands"
    case sled = "sled"
    
    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .pullUpBar: return "Pull-up Bar"
        case .erg: return "Erg"
        case .ski: return "Ski"
        case .assaultBike: return "Assault Bike"
        case .kettlebell: return "Kettlebell"
        case .dumbbell: return "Dumbbell"
        case .abMat: return "Ab Mat"
        case .wallBall: return "Wall Ball"
        case .jumpRope: return "Jump Rope"
        case .box: return "Box"
        case .ghdMachine: return "GHD Machine"
        case .bands: return "Bands"
        case .sled: return "Sled"
        }
    }
    
    var icon: String {
        switch self {
        case .barbell: return "barbell"
        case .pullUpBar: return "arrow.up.and.down"
        case .erg, .ski: return "figure.rowing"
        case .assaultBike: return "bicycle"
        case .kettlebell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell"
        case .abMat: return "figure.core.training"
        case .wallBall: return "soccerball"
        case .jumpRope: return "figure.jumprope"
        case .box: return "cube.box"
        case .ghdMachine: return "figure.strengthtraining.traditional"
        case .bands: return "oval.portrait"
        case .sled: return "triangle"
        }
    }
    
    // Default equipment set for typical CrossFit gym
    static let defaultEquipment: Set<EquipmentOption> = [
        .barbell, .pullUpBar, .erg, .ski, .assaultBike, .kettlebell,
        .dumbbell, .abMat, .wallBall, .jumpRope, .box, .ghdMachine, .bands, .sled
    ]
}

// MARK: - Days of Week
enum DayOfWeek: String, CaseIterable, Codable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"
    
    var displayName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    var fullName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}

// MARK: - DayOfWeek GraphQL Conversion Extension
extension DayOfWeek {
    
    /// Converts individual iOS DayOfWeek to GraphQL RestDay
    var toGraphQLRestDay: WodAiAPI.RestDay {
        switch self {
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        case .sunday: return .sunday
        }
    }
    
    /// Creates GraphQLEnum wrapper for RestDay
    var toGraphQLEnum: GraphQLEnum<WodAiAPI.RestDay> {
        return GraphQLEnum(self.toGraphQLRestDay)
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
    
    static func from(input: InjuryInput) -> Injury {
        Injury(
            bodyPart: input.bodyPart,
            severity: InjurySeverity.init(rawValue: input.severity.rawValue) ?? .minor,
            description: input.description.unwrapped
        )
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


struct ProvisionUserResponse: Codable {
    let success: Bool
    let message: String?
    let userId: String?
}


