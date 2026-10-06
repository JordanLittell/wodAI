//
//  WorkoutFixture.swift
//  wodAI
//
//  Updated with component-based workout structure
//

import Foundation

class WorkoutFixture {
    static var workout: Workout = Workout(
        id: "239048-23094-234",
        name: "CrossFit Total Domination",
        description: "This workout is designed to create a complete full-body challenge across multiple energy systems. It begins with a high-volume metabolic conditioning piece, transitions to a strength-endurance triplet, and finishes with complex gymnastics movements. Athletes should experience both cardiovascular and muscular fatigue, with the final gymnastics section testing technical proficiency under significant systemic fatigue.",
        coaching: "Focus on maintaining good form throughout all components",
        stimulus: "Multi-modal full-body challenge",
        scheduledDate: Date(),
        status: .completed,
        components: [
            Component(
                name: "Part A - Metabolic Conditioning",
                order: 1,
                definition: """
                For Time:
                50-40-30-20-10
                Calorie Row
                Wall Balls (20/14 lbs to 10/9 ft target)
                """,
                description: "High-volume metabolic conditioning",
                equipment: ["Rower", "Medicine Ball"],
                muscles: ["Full Body"],
                movements: ["Row", "Wall Ball"],
                stimulus: "Sustained aerobic power",
                targetFitnessDomains: ["cardiovascular endurance"],
                energySystems: ["oxidative"]
            ),
            Component(
                name: "Part B - Strength Endurance",
                order: 2,
                definition: """
                5 Rounds:
                7 Power Cleans (155/105 lbs)
                7 Front Rack Lunges (155/105 lbs)
                7 Bar Facing Burpees
                """,
                description: "Strength endurance triplet",
                equipment: ["Barbell", "Plates"],
                muscles: ["Full Body", "Legs", "Core"],
                movements: ["Power Clean", "Lunge", "Burpee"],
                stimulus: "Strength endurance with barbell",
                targetFitnessDomains: ["strength", "muscular endurance"],
                energySystems: ["glycolytic"]
            ),
            Component(
                name: "Part C - Gymnastics Finisher",
                order: 3,
                definition: """
                Finish with:
                30 Toes-to-Bar
                20 Ring Dips
                10 Bar Muscle-ups
                """,
                description: "Gymnastics finisher under fatigue",
                equipment: ["Pull-up Bar", "Rings"],
                muscles: ["Core", "Shoulders", "Arms"],
                movements: ["Toes-to-Bar", "Ring Dip", "Muscle-up"],
                stimulus: "Gymnastics under systemic fatigue",
                targetFitnessDomains: ["coordination", "agility"],
                energySystems: ["phosphagen"]
            )
        ],
        completedAt: nil,
        completed: false
    )
    
    // Keep legacy format for backward compatibility
    static var legacyWorkout: Workout {
        workout
    }
}
