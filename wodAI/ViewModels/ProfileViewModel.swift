//
//  ProfileViewModel.swift
//  wodAI
//
//  Created by Jordan Littell on 4/26/25.
//

import WodAiAPI
import Foundation

@MainActor
class ProfileViewModel : ObservableObject {
    @Published var weight: Weight = Weight.lbs
    @Published var weightValue : Int = 150
    
    @Published var height: Height = Height.inches;
    @Published var heightValue = 60
    
    @Published var level: FitnessLevel = FitnessLevel.intermediate
    
    @Published var age: Int = 25;
    @Published var gender: Gender = Gender.male;
    
    init(weight: Weight, weightValue: Int, height: Height, heightValue: Int = 60, level: FitnessLevel, age: Int, gender: Gender) {
        self.weight = weight
        self.weightValue = weightValue
        self.height = height
        self.heightValue = heightValue
        self.level = level
        self.age = age
        self.gender = gender
    }
    
    // load profile
    
    // update profile
    
}
