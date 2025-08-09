//
//  ProvisioningView.swift
//  wodAI
//
//  Created for WodAI provisioning workflow
//

import SwiftUI

struct ProvisioningView: View {
    @StateObject private var viewModel = ProvisioningViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Background"),
                        Color("Surface")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    ProgressBarView(progress: viewModel.progress)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Text(viewModel.currentStep.title)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("PrimaryText"))
                                
                                Text(viewModel.currentStep.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(Color("SecondaryText"))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 24)
                            
                            // Step Content
                            Group {
                                switch viewModel.currentStep {
                                case .gender:
                                    GenderSelectionView(provisioningData: $viewModel.provisioningData)
                                case .fitnessLevel:
                                    FitnessLevelSelectionView(provisioningData: $viewModel.provisioningData)
                                case .workoutDuration:
                                    WorkoutDurationSelectionView(provisioningData: $viewModel.provisioningData)
                                case .benchmarks:
                                    BenchmarksInputView(viewModel: viewModel)
                                case .injuries:
                                    InjuriesInputView(viewModel: viewModel)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for buttons
                    }
                    
                    // Navigation Buttons
                    VStack(spacing: 12) {
                        // Primary Action Button
                        Button(action: {
                            viewModel.nextStep()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(viewModel.currentStep == .injuries ? "Complete Setup" : "Continue")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("BrandPrimary"),
                                    Color("BrandSecondary")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color("BrandPrimary").opacity(0.3), radius: 8, x: 0, y: 4)
                        .disabled(!viewModel.canProceed || viewModel.isLoading)
                        .opacity(viewModel.canProceed ? 1.0 : 0.6)
                        
                        // Back Button (if not on first step)
                        if viewModel.currentStep.rawValue > 0 {
                            Button(action: {
                                viewModel.previousStep()
                            }) {
                                Text("Back")
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("PrimaryText"))
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .background(
                        Color("Surface")
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                    )
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidCompleteProvisioning)) { _ in
                // Provisioning complete, dismiss this view
                dismiss()
            }
        }
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("Surface2"))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("BrandPrimary"),
                                Color("BrandSecondary")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Gender Selection View
struct GenderSelectionView: View {
    @Binding var provisioningData: ProvisioningData
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Gender.allCases, id: \.self) { gender in
                SelectionCard(
                    title: gender.displayName,
                    isSelected: provisioningData.gender == gender,
                    icon: genderIcon(for: gender)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        provisioningData.gender = gender
                    }
                }
            }
        }
        .padding(.top, 20)
    }
    
    private func genderIcon(for gender: Gender) -> String {
        switch gender {
        case .male: return "person.fill"
        case .female: return "person.fill"
        case .other: return "person.2.fill"
        case .preferNotToSay: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Fitness Level Selection View
struct FitnessLevelSelectionView: View {
    @Binding var provisioningData: ProvisioningData
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(FitnessLevel.allCases, id: \.self) { level in
                SelectionCard(
                    title: level.displayName,
                    subtitle: level.description,
                    isSelected: provisioningData.fitnessLevel == level,
                    icon: fitnessIcon(for: level)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        provisioningData.fitnessLevel = level
                    }
                }
            }
        }
        .padding(.top, 20)
    }
    
    private func fitnessIcon(for level: FitnessLevel) -> String {
        switch level {
        case .beginner: return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced: return "figure.strengthtraining.traditional"
        case .elite: return "trophy.fill"
        }
    }
}

// MARK: - Workout Duration Selection View
struct WorkoutDurationSelectionView: View {
    @Binding var provisioningData: ProvisioningData
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(WorkoutDuration.allCases, id: \.self) { duration in
                SelectionCard(
                    title: duration.displayName,
                    isSelected: provisioningData.workoutDuration == duration,
                    icon: "clock.fill"
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        provisioningData.workoutDuration = duration
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Selection Card Component
struct SelectionCard: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("BrandPrimary").opacity(0.1) : Color("Surface2"))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("PrimaryText"))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color("BrandPrimary") : Color("Border"))
            }
            .padding(20)
            .background(Color("Surface"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("BrandPrimary") : Color("Border"), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color("BrandPrimary").opacity(0.1) : Color.black.opacity(0.02), 
                    radius: isSelected ? 8 : 4, 
                    x: 0, 
                    y: isSelected ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ProvisioningView()
        .environmentObject(AuthManager())
}
