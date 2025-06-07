//
//  ProfileView.swift
//  wodAI
//
//  Enhanced Profile View with improved data management and height selector
//

import SwiftUI
import WodAiAPI

// MARK: - Gender Extension for Display Names
extension Gender {
    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
}

struct ProfileView: View {
    
    @StateObject private var profileViewModel = ProfileViewModel(
        weight: .lbs,
        weightValue: 150,
        height: .inches,
        heightValue: 67, // 5'7"
        level: .intermediate,
        age: 25,
        gender: .male
    )
    
    @EnvironmentObject var authManager: AuthManager
    
    @State private var index = 1 // Default to "Intermediate"
    @State var levels = ["Beginner", "Intermediate", "Advanced", "Elite", "Pro"]
    
    // Enhanced state variables for user profile
    @State private var age = 30
    @State private var heightFeet = 5
    @State private var heightInches = 7
    @State private var weight = 150.0 // In lbs
    @State private var selectedGender: Gender = .male
    @State private var genders: [Gender] = [.male, .female]
    
    @State private var fitnessGoal = "Build muscle"
    @State private var goals = ["Build muscle", "Lose weight", "Improve endurance", "Maintain fitness", "Athletic performance"]
    @State private var workoutsPerWeek = 3
    @State private var notificationsEnabled = true
    @State private var saving = false
    @State private var loading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var currentUserId: Int = 1 // This should be fetched from auth or user context
    
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
                        EnhancedHeightSelectorView(feet: $heightFeet, inches: $heightInches)
                    } label: {
                        HStack {
                            Text("Height")
                            Spacer()
                            Text(getHeightString())
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
                                ForEach(genders, id: \.self) { gender in
                                    Text(gender.displayName)
                                        .tag(gender)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                        .navigationTitle("Gender")
                    } label: {
                        HStack {
                            Text("Gender")
                            Spacer()
                            Text(selectedGender.displayName)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Fitness Goals")) {
                    NavigationLink {
                        Form {
                            Picker("Goal", selection: $fitnessGoal) {
                                ForEach(goals, id: \.self) { goal in
                                    Text(goal)
                                        .tag(goal)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                        .navigationTitle("Fitness Goal")
                    } label: {
                        HStack {
                            Text("Primary Goal")
                            Spacer()
                            Text(fitnessGoal)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("App Settings")) {
                    Toggle("Workout Notifications", isOn: $notificationsEnabled)
                }
                
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            if saving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Saving...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Profile")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(saving ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(saving)
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .padding()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Profile Update", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadUserProfile()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func getFitnessLevel() -> FitnessLevel {
        switch levels[index] {
            case "Elite": return FitnessLevel.elite
            case "Advanced": return FitnessLevel.advanced
            case "Beginner": return FitnessLevel.beginner
            case "Intermediate": return FitnessLevel.intermediate
            case "Pro": return FitnessLevel.pro
            
        default:
            return FitnessLevel.intermediate
        }
    }
    
    func getHeightString() -> String {
        return "\(heightFeet)' \(heightInches)\""
    }
    
    // MARK: - Profile Management
    
    func saveProfile() {
        guard !saving else { return }
        
        saving = true
        
        let totalInches = Double((heightFeet * 12) + heightInches)
        let weightInput = WeightInput(value: weight, unit: GraphQLEnum(Weight.lbs))
        let heightInput = HeightInput(value: totalInches, unit: GraphQLEnum(Height.inches))
        
        let input = UpdateUserInput(
            age: GraphQLNullable(integerLiteral: age),
            gender: GraphQLNullable(selectedGender),
            fitnessLevel: GraphQLNullable(getFitnessLevel()),
            goal: GraphQLNullable(stringLiteral: fitnessGoal),
            weight: GraphQLNullable(weightInput),
            height: GraphQLNullable(heightInput)
        )
        
        Network.shared.client.perform(mutation: UpdateUserMutation(updateUserId: currentUserId, input: input)) { result in
            DispatchQueue.main.async {
                self.saving = false
                
                switch result {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors, !errors.isEmpty {
                        self.alertMessage = "Failed to save profile: \(errors.first?.message ?? "Unknown error")"
                        self.showAlert = true
                    } else {
                        // Update local state with saved values
                        self.updateLocalProfileData(from: graphqlResult.data?.updateUser)
                        self.alertMessage = "Profile saved successfully!"
                        self.showAlert = true
                    }
                    
                case .failure(let error):
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    func updateLocalProfileData(from userData: UpdateUserMutation.Data.UpdateUser?) {
        guard let user = userData else { return }
        
        if let userAge = user.age {
            self.age = userAge
        }
        
//        if let userGender = user.gender {
//            self.selectedGender = userGender
//        }
        
        if let userHeight = user.height {
            let totalInches = Int(userHeight.value)
            self.heightFeet = totalInches / 12
            self.heightInches = totalInches % 12
        }
        
        if let userWeight = user.weight {
            self.weight = userWeight.value
        }
        
//        if let level = user.fitnessLevel {
//            // Update fitness level index
//            switch level {
//            case .beginner: self.index = 0
//            case .intermediate: self.index = 1
//            case .advanced: self.index = 2
//            case .elite: self.index = 3
//            case .pro: self.index = 4
//            }
//        }
        
        if let goal = user.goal {
            self.fitnessGoal = goal
        }
    }
    
    // MARK: - Data Loading
    
    func loadUserProfile() {
        // TODO: Implement loading user profile from backend
        // This should fetch the current user's data and populate the form
        // For now, we'll use default values
        loading = false
        
        // Example of what this might look like:
        // Network.shared.client.fetch(query: GetUserQuery(id: currentUserId)) { result in
        //     // Handle user data loading
        // }
    }
}

// MARK: - Enhanced Height Selector View
struct EnhancedHeightSelectorView: View {
    @Binding var feet: Int
    @Binding var inches: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Height Display
                VStack(spacing: 8) {
                    Text("Select Your Height")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(feet)' \(inches)\"")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("(\(getTotalInches()) inches total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Dual Picker
                VStack(spacing: 20) {
                    Text("Adjust with pickers below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 40) {
                        // Feet Picker
                        VStack {
                            Text("Feet")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Picker("Feet", selection: $feet) {
                                ForEach(3...8, id: \.self) { foot in
                                    Text("\(foot)")
                                        .font(.title2)
                                        .tag(foot)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                        
                        // Inches Picker
                        VStack {
                            Text("Inches")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Picker("Inches", selection: $inches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch)")
                                        .font(.title2)
                                        .tag(inch)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                    }
                }
                
                // Height Range Info
                VStack(spacing: 8) {
                    Text("Common Height Range")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        HeightRangeItem(height: "4' 0\"", label: "Short")
                        Spacer()
                        HeightRangeItem(height: "5' 7\"", label: "Average")
                        Spacer()
                        HeightRangeItem(height: "6' 8\"", label: "Tall")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Quick Set Buttons
                VStack(spacing: 12) {
                    Text("Quick Select")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        QuickHeightButton(feet: 5, inches: 0, currentFeet: $feet, currentInches: $inches)
                        QuickHeightButton(feet: 5, inches: 4, currentFeet: $feet, currentInches: $inches)
                        QuickHeightButton(feet: 5, inches: 8, currentFeet: $feet, currentInches: $inches)
                        QuickHeightButton(feet: 5, inches: 10, currentFeet: $feet, currentInches: $inches)
                        QuickHeightButton(feet: 6, inches: 0, currentFeet: $feet, currentInches: $inches)
                        QuickHeightButton(feet: 6, inches: 2, currentFeet: $feet, currentInches: $inches)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func getTotalInches() -> Int {
        return (feet * 12) + inches
    }
}

// MARK: - Supporting Views
struct HeightRangeItem: View {
    let height: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(height)
                .font(.caption)
                .fontWeight(.medium)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct QuickHeightButton: View {
    let feet: Int
    let inches: Int
    @Binding var currentFeet: Int
    @Binding var currentInches: Int
    
    private var isSelected: Bool {
        currentFeet == feet && currentInches == inches
    }
    
    var body: some View {
        Button(action: {
            currentFeet = feet
            currentInches = inches
        }) {
            Text("\(feet)' \(inches)\"")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthManager())
    }
}

struct EnhancedHeightSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedHeightSelectorView(feet: .constant(5), inches: .constant(7))
    }
}
