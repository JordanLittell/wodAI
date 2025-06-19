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
    var equipment: Set<Equipment>  // Changed from Set<EquipmentOption> to Set<Equipment>
    var isSelected: Bool
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "building.2",
        equipment: Set<Equipment> = [],
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
