//
//  ProfileView.swift
//  wodAI
//
//  Redesigned Profile View with efficient inline editing and proper design system usage
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
        heightValue: 67,
        level: .intermediate,
        age: 25,
        gender: .male
    )
    
    @EnvironmentObject var authManager: AuthManager
    
    // State variables
    @State private var fitnessLevel = FitnessLevel.intermediate
    @State private var age = 30
    @State private var heightFeet = 5
    @State private var heightInches = 7
    @State private var weight = 150.0
    @State private var selectedGender: Gender = .male
    @State private var fitnessGoal = "Build muscle"
    @State private var notificationsEnabled = true
    
    @State private var saving = false
    @State private var hasUnsavedChanges = false
    @State private var showSuccessToast = false
    @State private var editingHeight = false
    @State private var editingWeight = false
    @State private var loading = true
    @State private var currentUserId: Int = 1
    
    private let fitnessLevels: [(FitnessLevel, String, String)] = [
        (.beginner, "Beginner", "New to fitness"),
        (.intermediate, "Intermediate", "Workout 2-3x/week"),
        (.advanced, "Advanced", "Workout 4-5x/week"),
        (.elite, "Elite", "Workout 6+x/week"),
        (.pro, "Pro", "Competitive athlete")
    ]
    
    private let goals = [
        ("Build muscle", "figure.arms.open"),
        ("Lose weight", "scalemass"),
        ("Improve endurance", "figure.run"),
        ("Maintain fitness", "heart.fill"),
        ("Athletic performance", "sportscourt.fill")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.background)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quick Setup Header
                        VStack(spacing: 8) {
                            Text("Let's personalize your experience")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("This helps us create better workouts for you")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // Fitness Level Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fitness Level")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            VStack(spacing: 8) {
                                ForEach(fitnessLevels, id: \.0) { level, title, description in
                                    FitnessLevelCard(
                                        title: title,
                                        description: description,
                                        isSelected: fitnessLevel == level,
                                        action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                fitnessLevel = level
                                                hasUnsavedChanges = true
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Body Metrics Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Body Metrics")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            // Inline form fields
                            VStack(spacing: 12) {
                                // Age
                                MetricRow(
                                    title: "Age",
                                    value: "\(age) years",
                                    icon: "calendar"
                                ) {
                                    HStack {
                                        Stepper("", value: $age, in: 16...100)
                                            .labelsHidden()
                                            .onChange(of: age) { _, _ in
                                                hasUnsavedChanges = true
                                            }
                                        Text("\(age)")
                                            .font(.body.monospacedDigit())
                                            .foregroundColor(.primaryText)
                                    }
                                }
                                
                                // Height
                                MetricRow(
                                    title: "Height",
                                    value: "\(heightFeet)' \(heightInches)\"",
                                    icon: "ruler"
                                ) {
                                    if editingHeight {
                                        HStack(spacing: 16) {
                                            // Feet picker
                                            HStack(spacing: 4) {
                                                Picker("Feet", selection: $heightFeet) {
                                                    ForEach(3...8, id: \.self) { ft in
                                                        Text("\(ft)'").tag(ft)
                                                    }
                                                }
                                                .pickerStyle(.menu)
                                                .onChange(of: heightFeet) { _, _ in
                                                    hasUnsavedChanges = true
                                                }
                                            }
                                            
                                            // Inches picker
                                            HStack(spacing: 4) {
                                                Picker("Inches", selection: $heightInches) {
                                                    ForEach(0...11, id: \.self) { inch in
                                                        Text("\(inch)\"").tag(inch)
                                                    }
                                                }
                                                .pickerStyle(.menu)
                                                .onChange(of: heightInches) { _, _ in
                                                    hasUnsavedChanges = true
                                                }
                                            }
                                            
                                            Button("Done") {
                                                withAnimation {
                                                    editingHeight = false
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.brandPrimary)
                                        }
                                    } else {
                                        Button(action: {
                                            withAnimation {
                                                editingHeight = true
                                            }
                                        }) {
                                            HStack {
                                                Text("\(heightFeet)' \(heightInches)\"")
                                                    .foregroundColor(.primaryText)
                                                Image(systemName: "pencil")
                                                    .font(.caption)
                                                    .foregroundColor(.brandPrimary)
                                            }
                                        }
                                    }
                                }
                                
                                // Weight
                                MetricRow(
                                    title: "Weight",
                                    value: "\(Int(weight)) lbs",
                                    icon: "scalemass"
                                ) {
                                    if editingWeight {
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("\(Int(weight)) lbs")
                                                    .font(.title3.monospacedDigit())
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primaryText)
                                                
                                                Spacer()
                                                
                                                Button("Done") {
                                                    withAnimation {
                                                        editingWeight = false
                                                    }
                                                }
                                                .font(.subheadline)
                                                .foregroundColor(.brandPrimary)
                                            }
                                            
                                            Slider(value: $weight, in: 50...400, step: 1)
                                                .tint(.brandPrimary)
                                                .onChange(of: weight) { _, _ in
                                                    hasUnsavedChanges = true
                                                }
                                        }
                                    } else {
                                        Button(action: {
                                            withAnimation {
                                                editingWeight = true
                                            }
                                        }) {
                                            HStack {
                                                Text("\(Int(weight)) lbs")
                                                    .foregroundColor(.primaryText)
                                                Image(systemName: "pencil")
                                                    .font(.caption)
                                                    .foregroundColor(.brandPrimary)
                                            }
                                        }
                                    }
                                }
                                
                                // Gender
                                MetricRow(
                                    title: "Gender",
                                    value: selectedGender.displayName,
                                    icon: "person"
                                ) {
                                    Picker("Gender", selection: $selectedGender) {
                                        Text("Male").tag(Gender.male)
                                        Text("Female").tag(Gender.female)
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: selectedGender) { _, _ in
                                        hasUnsavedChanges = true
                                    }
                                }
                            }
                        }
                        
                        // Fitness Goals
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Primary Goal")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(goals, id: \.0) { goal, icon in
                                    GoalCard(
                                        title: goal,
                                        icon: icon,
                                        isSelected: fitnessGoal == goal,
                                        action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                fitnessGoal = goal
                                                hasUnsavedChanges = true
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Notifications
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $notificationsEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.brandPrimary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Workout Reminders")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primaryText)
                                        
                                        Text("Get motivated with daily reminders")
                                            .font(.caption)
                                            .foregroundColor(.secondaryText)
                                    }
                                }
                            }
                            .tint(.brandPrimary)
                            .onChange(of: notificationsEnabled) { _, _ in
                                hasUnsavedChanges = true
                            }
                            .padding()
                            .background(Color(.surface))
                            .cornerRadius(12)
                        }
                        
                        // Save Button
                        if hasUnsavedChanges {
                            Button(action: saveProfile) {
                                HStack {
                                    if saving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text(saving ? "Saving..." : "Save Changes")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.heroStart, .heroEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(saving)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                // Success Toast
                VStack {
                    if showSuccessToast {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.success)
                            Text("Profile saved successfully!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color(.surface))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .padding()
                .animation(.spring(), value: showSuccessToast)
            )
            .onAppear {
                loadUserProfile()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func getHeightString() -> String {
        return "\(heightFeet)' \(heightInches)\""
    }
    
    // MARK: - Save Profile
    func saveProfile() {
        guard !saving else { return }
        
        saving = true
        
        let totalInches = Double((heightFeet * 12) + heightInches)
        let weightInput = WeightInput(value: weight, unit: GraphQLEnum(WeightUnit.lbs))
        let heightInput = HeightInput(value: totalInches, unit: GraphQLEnum(HeightUnit.inches))
        
        let input = UpdateUserInput(
            age: GraphQLNullable(integerLiteral: age),
            gender: GraphQLNullable(selectedGender),
            fitnessLevel: GraphQLNullable(fitnessLevel),
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
                        let errorMessage = errors.first?.message ?? "Unknown error"
                        if errorMessage.contains("authorized") {
                            authManager.signOut()
                        }
                        // Handle error silently or show inline error
                    } else {
                        self.hasUnsavedChanges = false
                        self.showSuccessToast = true
                        
                        // Hide toast after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showSuccessToast = false
                        }
                        
                        // Update local state with saved values
                        self.updateLocalProfileData(from: graphqlResult.data?.updateUser)
                    }
                    
                case .failure(let error):
                    // Handle error silently or show inline error
                    print("Network error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateLocalProfileData(from userData: UpdateUserMutation.Data.UpdateUser?) {
        guard let user = userData else { return }
        
        if let userAge = user.age {
            self.age = userAge
        }
        
        if let userHeight = user.height {
            let totalInches = Int(userHeight.value)
            self.heightFeet = totalInches / 12
            self.heightInches = totalInches % 12
        }
        
        if let userWeight = user.weight {
            self.weight = userWeight.value
        }
        
        if let goal = user.goal {
            self.fitnessGoal = goal
        }
    }
    
    // MARK: - Data Loading
    func loadUserProfile() {
        // TODO: Implement loading user profile from backend
        loading = false
    }
}

// MARK: - Supporting Views

struct FitnessLevelCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primaryText)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(
                        colors: [Color(.surface), Color(.surface)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(.border), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricRow<Content: View>: View {
    let title: String
    let value: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                content
            }
            .padding()
            .background(Color(.surface))
            .cornerRadius(12)
        }
    }
}

struct GoalCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .brandPrimary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? LinearGradient(
                        colors: [.brandPrimary, .brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) : LinearGradient(
                        colors: [Color(.surface), Color(.surface)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(.border), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Height Selector View (kept for reference but not used in new design)
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

// MARK: - Supporting Views for Height Selector
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
