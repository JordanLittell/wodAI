//
//  IntensityLevel.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

enum IntensityLevel: String, CaseIterable {
    case light = "light"
    case moderate = "moderate"
    case intense = "intense"
    case brutal = "brutal"
    
    var weightMultiplier: Double {
        switch self {
        case .light: return 0.6
        case .moderate: return 0.8
        case .intense: return 1.0
        case .brutal: return 1.3
        }
    }
    
    var color: Color {
        switch self {
        case .light: return .green
        case .moderate: return .blue
        case .intense: return .orange
        case .brutal: return .red
        }
    }
}
