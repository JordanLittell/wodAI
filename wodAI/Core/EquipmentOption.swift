//
//  EquipmentOption.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//


enum EquipmentOption: String, CaseIterable {
    case bodyweight = "Bodyweight"
    case dumbbells = "Dumbbells"
    case barbell = "Barbell"
    case kettlebells = "Kettlebells"
    case resistance_bands = "Resistance Bands"
    case pull_up_bar = "Pull-up Bar"
    case cable_machine = "Cable Machine"
    case rowing_machine = "Rowing Machine"
    case treadmill = "Treadmill"
    case stationary_bike = "Stationary Bike"
    case medicine_ball = "Medicine Ball"
    case foam_roller = "Foam Roller"
    case yoga_mat = "Yoga Mat"
    case bench = "Bench"
    case smith_machine = "Smith Machine"
    
    var icon: String {
        switch self {
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .dumbbells: return "dumbbell"
        case .barbell: return "dumbbell.fill"
        case .kettlebells: return "kettlebell"
        case .resistance_bands: return "oval.portrait"
        case .pull_up_bar: return "figure.pull.ups"
        case .cable_machine: return "cable.connector"
        case .rowing_machine: return "figure.rowing"
        case .treadmill: return "figure.run"
        case .stationary_bike: return "figure.cycling"
        case .medicine_ball: return "circle.fill"
        case .foam_roller: return "cylinder.fill"
        case .yoga_mat: return "rectangle.fill"
        case .bench: return "rectangle.and.hand.point.up.left.filled"
        case .smith_machine: return "rectangle.3.group.fill"
        }
    }
}
