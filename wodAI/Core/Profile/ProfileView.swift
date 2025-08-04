//
//  ProfileView.swift
//  wodAI
//
//  Redesigned Profile View with MVVM architecture and proper data loading
//

import SwiftUI
import WodAiAPI

// MARK: - Gender Extension for Display Names
extension WodAiAPI.Gender {
    var display: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
}

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    // UI State
    @State private var editingHeight = false
    @State private var editingWeight = false
    @State private var editingSessionDuration = false
    @State private var editingActiveDays = false
    @State private var heightFeet = 5
    @State private var heightInches = 7
    
    private let fitnessLevels: [(WodAiAPI.FitnessLevel, String, String)] = [
        (.beginner, "Beginner", "New to fitness"),
        (.intermediate, "Intermediate", "Workout 2-3x/week"),
        (.advanced, "Advanced", "Workout 4-5x/week"),
        (.elite, "Elite", "Workout 6+x/week"),
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
                
                if viewModel.isLoading {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(.brandPrimary)))
                            .scaleEffect(1.5)
                        
                        Text("Loading your profile...")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                    }
                } else {
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
                                            isSelected: viewModel.level == level,
                                            action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    viewModel.level = level
                                                    viewModel.hasUnsavedChanges = true
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
                                        value: "\(viewModel.age) years",
                                        icon: "calendar"
                                    ) {
                                        HStack {
                                            Stepper("", value: $viewModel.age, in: 16...100)
                                                .labelsHidden()
                                                .onChange(of: viewModel.age) { _, _ in
                                                    viewModel.hasUnsavedChanges = true
                                                }
                                            Text("\(viewModel.age)")
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
                                                        viewModel.setHeightFromFeetAndInches(feet: heightFeet, inches: heightInches)
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
                                                        viewModel.setHeightFromFeetAndInches(feet: heightFeet, inches: heightInches)
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
                                        value: "\(Int(viewModel.weight)) lbs",
                                        icon: "scalemass"
                                    ) {
                                        if editingWeight {
                                            VStack(spacing: 8) {
                                                HStack {
                                                    Text("\(Int(viewModel.weight)) lbs")
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
                                                
                                                Slider(value: Binding<Double>(
                                                    get: { Double(viewModel.weight) },
                                                    set: { viewModel.weight = Int($0) }
                                                ), in: 50...400, step: 1)
                                                .tint(.brandPrimary)
                                                .onChange(of: viewModel.weight) { _, _ in
                                                    viewModel.hasUnsavedChanges = true
                                                }
                                            }
                                        } else {
                                            Button(action: {
                                                withAnimation {
                                                    editingWeight = true
                                                }
                                            }) {
                                                HStack {
                                                    Text("\(Int(viewModel.weight)) lbs")
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
                                        value: viewModel.gender.display,
                                        icon: "person"
                                    ) {
                                        Picker("Gender", selection: $viewModel.gender) {
                                            Text("Male").tag(WodAiAPI.Gender.male)
                                            Text("Female").tag(WodAiAPI.Gender.female)
                                        }
                                        .pickerStyle(.segmented)
                                        .onChange(of: viewModel.gender) { _, _ in
                                            viewModel.hasUnsavedChanges = true
                                        }
                                    }
                                }
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Workout Preferences")
                                        .font(.headline)
                                        .foregroundColor(.primaryText)
                                    
                                    MetricRow(
                                        title: "Session duration",
                                        value: "\(viewModel.sessionDuration) minutes",
                                        icon: "clock"
                                    ) {
                                        if editingSessionDuration {
                                            VStack(spacing: 8) {
                                                HStack {
                                                    Text(viewModel.displayDuration())
                                                        .font(.body.monospacedDigit())
                                                        .foregroundColor(.primaryText)
                                                    
                                                    Spacer()
                                                    
                                                    Button("Done") {
                                                        withAnimation {
                                                            editingSessionDuration = false
                                                        }
                                                    }
                                                    .font(.subheadline)
                                                    .foregroundColor(.brandPrimary)
                                                }
                                                
                                                Slider(value: Binding<Double>(
                                                    get: { Double(viewModel.sessionDuration) },
                                                    set: { viewModel.sessionDuration = Int($0) }
                                                ), in: 0...200, step: 5)
                                                    .tint(.brandPrimary)
                                                    .onChange(of: viewModel.sessionDuration) { _, _ in
                                                        viewModel.hasUnsavedChanges = true
                                                    }
                                            }
                                        } else {
                                            Button(action: {
                                                withAnimation {
                                                    editingSessionDuration = true
                                                }
                                            }) {
                                                HStack {
                                                    Text(viewModel.displayDuration())
                                                        .foregroundColor(.primaryText)
                                                    Image(systemName: "pencil")
                                                        .font(.caption)
                                                        .foregroundColor(.brandPrimary)
                                                }
                                            }
                                        }
                                    }
                                    
                                    MetricRow(
                                        title: "Active days per week",
                                        value: "\(viewModel.activeDays) days",
                                        icon: "dumbbell"
                                    ) {
                                        if editingActiveDays {
                                            VStack(spacing: 8) {
                                                HStack {
                                                    Text("\(viewModel.activeDays) days")
                                                        .font(.body.monospacedDigit())
                                                        .foregroundColor(.primaryText)
                                                    
                                                    Spacer()
                                                    
                                                    Button("Done") {
                                                        withAnimation {
                                                            editingActiveDays = false
                                                        }
                                                    }
                                                    .font(.subheadline)
                                                    .foregroundColor(.brandPrimary)
                                                }
                                                
                                                Slider(value: Binding<Double>(
                                                    get: { Double(viewModel.activeDays) },
                                                    set: { viewModel.activeDays = Int($0) }
                                                ), in: 0...7, step: 1)
                                                .tint(.brandPrimary)
                                                .onChange(of: viewModel.activeDays) { _, _ in
                                                    viewModel.hasUnsavedChanges = true
                                                }
                                            }
                                        } else {
                                            Button(action: {
                                                withAnimation {
                                                    editingActiveDays = true
                                                }
                                            }) {
                                                HStack {
                                                    Text("\(viewModel.activeDays) per week")
                                                        .foregroundColor(.primaryText)
                                                    Image(systemName: "pencil")
                                                        .font(.caption)
                                                        .foregroundColor(.brandPrimary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Save Button
                            if viewModel.hasUnsavedChanges {
                                Button(action: { viewModel.saveProfile() }) {
                                    HStack {
                                        if viewModel.isSaving {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                        Text(viewModel.isSaving ? "Saving..." : "Save Changes")
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
                                .disabled(viewModel.isSaving)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            // Sign Out Button
                            VStack(spacing: 16) {
                                Divider()
                                    .padding(.vertical, 8)
                                
                                Button(action: signOut) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.body)
                                        Text("Sign Out")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.surface))
                                    .foregroundColor(.error)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.error).opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.top, 20)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                VStack {
                    if viewModel.showSuccessToast {
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
                .animation(.spring(), value: viewModel.showSuccessToast)
            )
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.loadUserProfile()
                // Update height UI values from view model
                let (feet, inches) = viewModel.getHeightFeetAndInches()
                heightFeet = feet
                heightInches = inches
            }
            .onChange(of: viewModel.height) { _, _ in
                // Update UI when height changes from data load
                let (feet, inches) = viewModel.getHeightFeetAndInches()
                heightFeet = feet
                heightInches = inches
            }
        }
    }
    
    // MARK: - Sign Out
    private func signOut() {
        // Clear any unsaved changes
        viewModel.hasUnsavedChanges = false
        
        // Sign out through auth manager
        authManager.signOut()
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

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthManager())
    }
}
