//
//  GymProfile.swift
//  wodAI
//
//  Created by Jordan Littell on 6/9/25.
//

import Foundation

struct GymProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var equipment: Set<EquipmentOption>
    var isSelected: Bool
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "building.2",
        equipment: Set<EquipmentOption> = [],
        isSelected: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.equipment = equipment
        self.isSelected = isSelected
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Default profiles
    static let home = GymProfile(
        name: "Home",
        icon: "house.fill",
        equipment: [.bodyweight, .resistance_bands],
        isSelected: true
    )
    
    static let commercialGym = GymProfile(
        name: "Commercial Gym",
        icon: "building.2.fill",
        equipment: [
            .bodyweight, .dumbbells, .barbell, .pull_up_bar,
            .kettlebells, .resistance_bands, .cable_machine,
            .treadmill, .stationary_bike, .bench, .smith_machine
        ]
    )
    
    static let crossfitBox = GymProfile(
        name: "CrossFit Box",
        icon: "bolt.fill",
        equipment: [
            .bodyweight, .dumbbells, .barbell, .pull_up_bar,
            .kettlebells, .resistance_bands, .rowing_machine,
            .medicine_ball, .foam_roller, .yoga_mat, .bench
        ]
    )
    
    static let hotel = GymProfile(
        name: "Hotel Gym",
        icon: "bed.double.fill",
        equipment: [.bodyweight, .dumbbells, .treadmill, .stationary_bike]
    )
    
    static let budget = GymProfile(
        name: "Budget Gym",
        icon: "creditcard.fill",
        equipment: [
            .bodyweight, .dumbbells, .smith_machine,
            .treadmill, .stationary_bike, .cable_machine
        ]
    )
}

// Icons for gym profiles
struct GymProfileIcon {
    static let icons = [
        "house.fill",
        "building.2.fill",
        "bolt.fill",
        "bed.double.fill",
        "creditcard.fill",
        "figure.walk",
        "sportscourt.fill",
        "dumbbell.fill",
        "figure.run",
        "figure.strengthtraining.traditional",
        "figure.outdoor.cycle",
        "figure.yoga",
        "figure.boxing",
        "figure.wrestling",
        "mountain.2.fill",
        "water.waves",
        "location.fill"
    ]
}
