//
//  Workout.swift
//  wodAI
//
//  Updated to support component-based workout structure
//

import Foundation

// MARK: - Component Model
struct Component: Codable, Identifiable {
    let id : UUID = UUID()
    let name: String
    let order: Int
    let definition: String
    let description: String

    let targetFitnessDomains: [String]?
    let energySystems: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case order
        case definition
        case description
        case targetFitnessDomains
        case energySystems
    }
}

// MARK: - Workout Model
struct Workout: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let components: [Component]
    let completedAt: Date?
    let completed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case components
        case completedAt
        case completed
    }
    
    // Equatable conformance
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Example/Preview Data
extension Workout {
    static let example = Workout(
        id: "example-1",
        name: "Elite Olympic Conditioning",
        description: "This workout is appropriate for an elite 30-year-old male athlete weighing 180 pounds due to its heavy loads, complex movements, and high-intensity nature. The combination of Olympic lifting, gymnastics, and cardio aligns with CrossFit's methodology of constantly varied, functional movements performed at high intensity.",
        components: [t
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
                targetFitnessDomains: ["strength", "power"],
                energySystems: ["glycolytic", "oxidative"]
            )
        ],
        completedAt: nil,
        completed: false
    )
}
