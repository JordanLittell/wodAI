//
//  MuscleGroup.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

enum MuscleGroup: String, CaseIterable {
    case chest, back, shoulders, arms, legs, core, glutes, cardio
    
    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .shoulders: return .orange
        case .arms: return .purple
        case .legs: return .green
        case .core: return .yellow
        case .glutes: return .pink
        case .cardio: return .mint
        }
    }
}
