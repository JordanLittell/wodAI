//
//  Workout.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import Foundation

struct Workout: Codable, Identifiable {
    let definition, stimulus, muscles, format: String
    let id: String;
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case format = "format"
        case definition = "definition"
        case stimulus = "stimulus"
        case muscles = "muscles"
    }
}
