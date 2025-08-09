//
//  Workout.swift
//  wodAI
//
//  Updated to support asynchronous workout generation and scheduling
//

import Foundation

// MARK: - Workout Status Enum
enum WorkoutStatus: String, CaseIterable, Codable {
    case pending = "PENDING"
    case generating = "GENERATING" 
    case completed = "COMPLETED"
    case failed = "FAILED"
    
    var displayName: String {
        switch self {
        case .pending: return "Scheduled"
        case .generating: return "Generating..."
        case .completed: return "Ready"
        case .failed: return "Error"
        }
    }
    
    var isGenerating: Bool {
        return self == .generating
    }
    
    var isReady: Bool {
        return self == .completed
    }
}

// MARK: - Rest Day Enum
enum RestDay: String, CaseIterable, Codable {
    case monday = "MONDAY"
    case tuesday = "TUESDAY"
    case wednesday = "WEDNESDAY"
    case thursday = "THURSDAY"
    case friday = "FRIDAY"
    case saturday = "SATURDAY"
    case sunday = "SUNDAY"
    
    var displayName: String {
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

// MARK: - Component Model
struct Component: Codable, Identifiable {
    let id: UUID = UUID()
    let name: String
    let order: Int
    let definition: String
    let description: String
    let equipment: [String]?
    let muscles: [String]
    let movements: [String]
    let stimulus: String?
    let targetFitnessDomains: [String]?
    let energySystems: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case order
        case definition
        case description
        case equipment
        case muscles
        case movements
        case stimulus
        case targetFitnessDomains
        case energySystems
    }
}

// MARK: - Workout Model
struct Workout: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let coaching: String?
    let stimulus: String?
    let scheduledDate: Date?  // NEW: Date this workout is scheduled for
    let status: WorkoutStatus // NEW: Generation status
    let components: [Component]
    let completedAt: Date?
    let completed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case coaching
        case stimulus
        case scheduledDate
        case status
        case components
        case completedAt
        case completed
    }
    
    // Computed properties for UI logic
    var isScheduledForToday: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return Calendar.current.isDateInToday(scheduledDate)
    }
    
    var isScheduledForFuture: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return scheduledDate > Date()
    }
    
    var canBeStarted: Bool {
        return status.isReady && !completed
    }
    
    var shouldShowLoadingState: Bool {
        return status.isGenerating
    }
    
    // Equatable conformance
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Workout Schedule Response
struct WorkoutScheduleResponse: Codable {
    let success: Bool
    let message: String
    let scheduledDates: [Date]
}

// MARK: - Example/Preview Data
extension Workout {
    static let example = Workout(
        id: "example-1",
        name: "Elite Olympic Conditioning",
        description: "This workout is appropriate for an elite 30-year-old male athlete weighing 180 pounds due to its heavy loads, complex movements, and high-intensity nature. The combination of Olympic lifting, gymnastics, and cardio aligns with CrossFit's methodology of constantly varied, functional movements performed at high intensity.",
        coaching: "Maintain proper form on the Olympic lifts, especially as fatigue sets in. Focus on efficient transitions between movements.",
        stimulus: "High-intensity workout combining heavy Olympic lifting with gymnastics and cardio to test strength, power, and endurance",
        scheduledDate: Date(),
        status: .completed,
        components: [
            Component(
                name: "WOD - Olympic Conditioning",
                order: 1,
                definition: """
                3 rounds for time:
                7 Power cleans (225 lbs)
                7 Ring muscle-ups
                500m row
                10 Box jumps (30 inch)
                """,
                description: "High-intensity workout combining heavy Olympic lifting with gymnastics and cardio to test strength, power, and endurance",
                equipment: ["Barbell", "Bumper Plates", "Pull-up Bar", "Rower", "Box"],
                muscles: ["Quadriceps", "hamstrings", "glutes", "core", "shoulders", "back", "triceps", "chest"],
                movements: ["Power clean", "Ring muscle-up", "Row", "Box jump"],
                stimulus: "High-intensity workout combining heavy Olympic lifting with gymnastics and cardio to test strength, power, and endurance",
                targetFitnessDomains: ["strength", "power"],
                energySystems: ["glycolytic", "oxidative"]
            )
        ],
        completedAt: nil,
        completed: false
    )
    
    static let generatingExample = Workout(
        id: "generating-1",
        name: "Generating Workout...",
        description: "AI is crafting your perfect workout based on your recent activity and goals.",
        coaching: nil,
        stimulus: nil,
        scheduledDate: Date(),
        status: .generating,
        components: [],
        completedAt: nil,
        completed: false
    )
    
    static let failedExample = Workout(
        id: "failed-1",
        name: "Workout Generation Failed",
        description: "We encountered an issue generating your workout. Please try again.",
        coaching: nil,
        stimulus: nil,
        scheduledDate: Date(),
        status: .failed,
        components: [],
        completedAt: nil,
        completed: false
    )
}
