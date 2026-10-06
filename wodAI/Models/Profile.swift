//
//  Profile.swift
//  wodAI
//
//  Created by Jordan Littell on 5/3/25.
//

import Foundation
import WodAiAPI

struct Profile : Codable, Identifiable {
    let email: String;
    let firstName: String;
    let lastName: String;
    
//    let weightUnit: Weight;
//    let weightValue: Int;
//    let heightUnit: Height;
//    let heightValue: Int;
    
    let age: Int;
//    let level: FitnessLevel;
    
    let id: String;
    
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case email = "email"
        case firstName = "firstName"
        case lastName = "lastName"
//        case weightUnit = "weightUnit"
//        case weightValue = "weightValue"
//        case heightUnit = "heightUnit"
//        case heightValue = "heightValue"
        case age = "age"
//        case level = "level"
    }
    
    
}
