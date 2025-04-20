//
//  Workout.swift
//  wodAI
//
//  Created by Jordan Littell on 4/16/25.
//

import Foundation

struct Workout: Codable, Identifiable {
    let definition, stimulus, muscles, title: String
    let id: Int;
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case definition = "definition"
        case stimulus = "stimulus"
        case muscles = "muscles"
    }
}
