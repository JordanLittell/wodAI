//
//  ProfileView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/19/25.
//

import SwiftUI
import WodAiAPI

struct ProfileView: View {
    
    @State private var index = 0
    @State var levels = ["Elite", "Intermediate", "Advanced", "Pro", "Beginner", "RX"]
    
    // Additional state variables for user profile
    @State private var age = 30
    @State private var height = 55.0 // In inches
    @State private var weight = 70.0 // In lbs
    @State private var selectedGender = "Male"
    @State private var selectedUnit = "imperial"
    @State private var genders = ["Male", "Female"]
    
    @State private var fitnessGoal = "Build muscle"
    @State private var goals = ["Build muscle", "Lose weight", "Improve endurance", "Maintain fitness", "Athletic performance"]
    @State private var workoutsPerWeek = 3
    @State private var notificationsEnabled = true
    @State private var saving = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Fitness Level")) {
                    Picker("Level", selection: $index) {
                        ForEach(0 ..< levels.count, id: \.self) {
                            Text(self.levels[$0])
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Personal Information")) {
                    NavigationLink {
                        // Age selector view
                        Form {
                            Stepper("Age: \(age)", value: $age, in: 16...100)
                        }
                        .navigationTitle("Age")
                    } label: {
                        HStack {
                            Text("Age")
                            Spacer()
                            Text("\(age)")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    NavigationLink {
                        // Height selector view
                        Form {
                            VStack {
                                Text(getHeight())
                                    .font(.title2)
                                    .padding()
                                
                                Slider(value: $height, in: 48...120, step: 1)
                                    .padding(.horizontal)
                                
                                HStack {
                                    Text("4 ft")
                                    Spacer()
                                    Text("10 ft")
                                }
                                .padding(.horizontal)
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                        }
                        .navigationTitle("Height")
                    } label: {
                        HStack {
                            Text("Height")
                            Spacer()
                            Text(getHeight())
                                .foregroundColor(.gray)
                        }
                    }
                    
                    NavigationLink {
                        // Weight selector view
                        Form {
                            VStack {
                                Text("\(Int(weight)) lbs")
                                    .font(.title2)
                                    .padding()
                                    
                                Slider(value: $weight, in: 40...400, step: 0.5)
                                    .padding(.horizontal)
                                    
                                HStack {
                                    Text("40 lbs")
                                    Spacer()
                                    Text("400 lbs")
                                }
                                .padding(.horizontal)
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                        }
                        .navigationTitle("Weight")
                    } label: {
                        HStack {
                            Text("Weight")
                            Spacer()
                            Text("\(Int(weight)) lbs")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    NavigationLink {
                        // Gender selector view
                        Form {
                            Picker("Gender", selection: $selectedGender) {
                                ForEach(genders, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                        .navigationTitle("Gender")
                    } label: {
                        HStack {
                            Text("Gender")
                            Spacer()
                            Text(selectedGender)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("App Settings")) {
                    Toggle("Workout Notifications", isOn: $notificationsEnabled)
                }
                
                Section {
                    Button(action: {
                        saving = true
                        let weightInput = WeightInput(value: weight, unit: GraphQLEnum(Weight.lbs));
                        let input = UpdateUserInput(
                            age: GraphQLNullable(integerLiteral: age),
                            gender: GraphQLNullable(Gender.male),
                            fitnessLevel: GraphQLNullable(getFitnessLevel()),
                            weight: GraphQLNullable(weightInput),
                            height: GraphQLNullable(
                                HeightInput(value: height, unit: GraphQLEnum(Height.inches))
                            )
                        )
                        Network.shared.client.perform(mutation: UpdateUserMutation(updateUserId: 1, input: input)) { result in
                            switch result {
                            case .success(_):
                                print(result)
                                self.saving = false
                            case .failure(let error):
                                print(error.localizedDescription)
                                self.saving = false
                            }
                        }
                    }) {
                        Text("\(saving ? "Saving..." : "Save Profile")")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .padding()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func getFitnessLevel() -> FitnessLevel {
        switch levels[0] {
            case "Elite": return FitnessLevel.elite
            case "Advanced": return FitnessLevel.advanced
            case "Beginner": return FitnessLevel.beginner
            case "Intermediate": return FitnessLevel.intermediate
            case "Pro": return FitnessLevel.pro
            
        default:
            return FitnessLevel.intermediate
        }
    }
    
    func getHeight() -> String {
        if selectedUnit == "imperial" {
            let feet =  String(format: "%.0f", height/12)
            let inches = String(format: "%.0f", Int(height) % 12)
            return "\(feet)ft \(inches)in"
        } else {
            return "\(selectedUnit) cm"
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
