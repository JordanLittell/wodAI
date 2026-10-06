//
//  GymProfile.swift
//  wodAI

import Foundation

struct GymProfile: Identifiable, Equatable {
    let id: Int
    var name: String
    var equipment: [Equipment]
    var isActive: Bool
}

struct GymProfileIcon {
    static let icons = [
        "house.fill", "building.2.fill", "bolt.fill", "bed.double.fill",
        "creditcard.fill", "figure.walk", "sportscourt.fill", "dumbbell.fill",
        "figure.run", "figure.strengthtraining.traditional", "figure.outdoor.cycle",
        "figure.yoga", "figure.boxing", "figure.wrestling",
        "mountain.2.fill", "water.waves", "location.fill"
    ]
}
