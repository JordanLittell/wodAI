//
//  Equipment.swift
//  wodAI
//
//  A piece of gym equipment, as EquipmentManager caches it and gym profiles
//  list it.
//

import Foundation

struct Equipment: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let category: String?
    
    var icon: String {
        switch name.lowercased() {
        case "barbell", "barbells": return "barbell"
        case "pull-up bar", "pullup bar", "pull up bar": return "arrow.up.and.down"
        case "dumbbell", "dumbbells": return "dumbbell"
        case "kettlebell", "kettlebells": return "figure.strengthtraining.traditional"
        case "rowing machine", "erg", "rower": return "figure.rowing"
        case "assault bike", "bike": return "bicycle"
        case "jump rope", "rope": return "figure.jumprope"
        case "box", "jump box": return "cube.box"
        case "wall ball", "medicine ball": return "soccerball"
        case "ab mat": return "figure.core.training"
        case "ghd", "ghd machine": return "figure.strengthtraining.traditional"
        case "bands", "resistance bands": return "oval.portrait"
        case "sled": return "triangle"
        default: return "dumbbell"
        }
    }
}



