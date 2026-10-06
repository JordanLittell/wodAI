//
//  EnergyLevel.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

enum EnergyLevel: String, CaseIterable {
    case tired = "tired"
    case low = "low energy"
    case good = "feeling good"
    case energized = "energized"
    case pumped = "pumped up"
    
    var emoji: String {
        switch self {
        case .tired: return "😴"
        case .low: return "🫤"
        case .good: return "😊"
        case .energized: return "😃"
        case .pumped: return "🔥"
        }
    }
    
    var skillLevel: Int {
        switch self {
        case .tired: return 3
        case .low: return 5
        case .good: return 7
        case .energized: return 8
        case .pumped: return 10
        }
    }
}
