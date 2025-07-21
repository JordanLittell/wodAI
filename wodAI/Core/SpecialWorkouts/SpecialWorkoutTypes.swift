//
//  SpecialWorkoutTypes.swift
//  wodAI
//
//  Special workout types for hero and girl WODs
//

import Foundation

// MARK: - Special Workout Categories
enum SpecialWorkoutCategory: String, CaseIterable {
    case hero = "Hero"
    case girls = "Girls"
    
    var displayName: String {
        switch self {
        case .hero:
            return "Hero WODs"
        case .girls:
            return "Girl WODs"
        }
    }
    
    var description: String {
        switch self {
        case .hero:
            return "Honor fallen heroes"
        case .girls:
            return "Classic benchmarks"
        }
    }
    
    var iconName: String {
        switch self {
        case .hero:
            return "star.fill"
        case .girls:
            return "crown.fill"
        }
    }
    
    var gradientColors: (start: String, end: String) {
        switch self {
        case .hero:
            return ("HeroStart", "HeroEnd")
        case .girls:
            return ("EnergyStart", "EnergyEnd")
        }
    }
}

// MARK: - Special Workout Data
struct SpecialWorkout: Identifiable {
    let id = UUID()
    let name: String
    let category: SpecialWorkoutCategory
    let description: String
    let definition: String
    let story: String?
    let difficulty: WorkoutDifficulty
    let estimatedDuration: Int // in minutes
    let equipment: [String]
    let movements: [String]
    
    enum WorkoutDifficulty: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case elite = "Elite"
        
        var color: String {
            switch self {
            case .beginner:
                return "Success"
            case .intermediate:
                return "Warning"
            case .advanced:
                return "BrandSecondary"
            case .elite:
                return "HeroEnd"
            }
        }
    }
}

// MARK: - Special Workouts Database
class SpecialWorkoutsDatabase {
    static let shared = SpecialWorkoutsDatabase()
    
    private init() {}
    
    // MARK: - Hero WODs
    let heroWorkouts: [SpecialWorkout] = [
        SpecialWorkout(
            name: "Murph",
            category: .hero,
            description: "The most famous Hero WOD",
            definition: "For time:\n1 mile run\n100 pull-ups\n200 push-ups\n300 air squats\n1 mile run\n\n*Partition the pull-ups, push-ups, and squats as needed. Start and finish with a mile run. If you've got a 20 lb vest or body armor, wear it.",
            story: "This workout was one of Mike's favorites and he'd named it 'Body Armor.' From here on it will be referred to as 'Murph' in honor of the focused warrior and great American who wanted nothing more in life than to serve this great country and the beautiful people who make it what it is.",
            difficulty: .advanced,
            estimatedDuration: 45,
            equipment: ["Pull-up bar", "Running track"],
            movements: ["Run", "Pull-ups", "Push-ups", "Air squats"]
        ),
        SpecialWorkout(
            name: "Fran",
            category: .girls,
            description: "The benchmark of benchmarks",
            definition: "21-15-9 reps for time of:\nThrusters (95/65 lb)\nPull-ups",
            story: nil,
            difficulty: .intermediate,
            estimatedDuration: 8,
            equipment: ["Barbell", "Pull-up bar"],
            movements: ["Thrusters", "Pull-ups"]
        ),
        SpecialWorkout(
            name: "Grace",
            category: .girls,
            description: "Power and speed",
            definition: "For time:\n30 clean and jerks (135/95 lb)",
            story: nil,
            difficulty: .intermediate,
            estimatedDuration: 5,
            equipment: ["Barbell"],
            movements: ["Clean and jerk"]
        ),
        SpecialWorkout(
            name: "Isabel",
            category: .girls,
            description: "Pure power",
            definition: "For time:\n30 snatches (135/95 lb)",
            story: nil,
            difficulty: .advanced,
            estimatedDuration: 4,
            equipment: ["Barbell"],
            movements: ["Snatch"]
        ),
        SpecialWorkout(
            name: "Helen",
            category: .girls,
            description: "Run, swing, pull",
            definition: "3 rounds for time:\n400m run\n21 kettlebell swings (53/35 lb)\n12 pull-ups",
            story: nil,
            difficulty: .intermediate,
            estimatedDuration: 12,
            equipment: ["Kettlebell", "Pull-up bar", "Running track"],
            movements: ["Run", "Kettlebell swings", "Pull-ups"]
        ),
        SpecialWorkout(
            name: "Cindy",
            category: .girls,
            description: "The bodyweight classic",
            definition: "As many rounds as possible in 20 minutes:\n5 pull-ups\n10 push-ups\n15 air squats",
            story: nil,
            difficulty: .beginner,
            estimatedDuration: 20,
            equipment: ["Pull-up bar"],
            movements: ["Pull-ups", "Push-ups", "Air squats"]
        ),
        SpecialWorkout(
            name: "Chad",
            category: .hero,
            description: "In honor of Navy SEAL Chad Michael Wilkinson",
            definition: "For time:\n1000 box step-ups (20 in)\n\n*Wearing a 45 lb plate",
            story: "Chad Michael Wilkinson, 27, of Chesapeake, Va., died Oct. 29, 2018, in Chattanooga, Tenn. Chad was a Navy SEAL assigned to an East Coast-based Naval Special Warfare unit.",
            difficulty: .advanced,
            estimatedDuration: 60,
            equipment: ["Box", "Weight plate"],
            movements: ["Box step-ups"]
        ),
        SpecialWorkout(
            name: "DT",
            category: .hero,
            description: "In honor of USAF SSgt Timothy P. Davis",
            definition: "5 rounds for time:\n12 deadlifts (155/105 lb)\n9 hang power cleans (155/105 lb)\n6 push jerks (155/105 lb)",
            story: "U.S. Air Force Staff Sergeant Timothy P. Davis, 28, was killed on February, 20 2009, supporting operations in Afghanistan. He was on his second tour of duty.",
            difficulty: .intermediate,
            estimatedDuration: 15,
            equipment: ["Barbell"],
            movements: ["Deadlifts", "Hang power cleans", "Push jerks"]
        )
    ]
    
    // MARK: - Computed Properties
    var allWorkouts: [SpecialWorkout] {
        return heroWorkouts
    }
    
    func workouts(for category: SpecialWorkoutCategory) -> [SpecialWorkout] {
        return allWorkouts.filter { $0.category == category }
    }
    
    func workout(named name: String) -> SpecialWorkout? {
        return allWorkouts.first { $0.name.lowercased() == name.lowercased() }
    }
}
