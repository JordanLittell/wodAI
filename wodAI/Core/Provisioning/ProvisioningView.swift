//
//  ProvisioningView.swift
//  wodAI
//
//  Consolidated provisioning workflow for collecting user information
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
                    
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: viewModel.currentStep.icon)
                                .font(.title2)
                                .foregroundColor(Color("BrandPrimary"))
                            
                            Text(viewModel.currentStep.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color("PrimaryText"))
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text(viewModel.currentStep.subtitle)
                                .font(.subheadline)
                                .foregroundColor(Color("SecondaryText"))
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Content
                    ScrollView {
                        VStack {
                            Group {
                                switch viewModel.currentStep {
                                case .equipment:
                                    EquipmentSelectionView(viewModel: viewModel)
                                case .gender:
                                    GenderSelectionView(viewModel: viewModel)
                                case .fitnessLevel:
                                    FitnessLevelSelectionView(viewModel: viewModel)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120) // Space for buttons
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
                                    Text(viewModel.isLastStep ? "Complete Setup" : "Continue")
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
    @ObservedObject var viewModel: ProvisioningViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Gender.allCases, id: \.self) { gender in
                SelectionCard(
                    title: gender.displayName,
                    isSelected: viewModel.provisioningData.gender == gender,
                    icon: gender.icon
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.provisioningData.gender = gender
                    }
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Fitness Level Selection View
struct FitnessLevelSelectionView: View {
    @ObservedObject var viewModel: ProvisioningViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(FitnessLevel.allCases, id: \.self) { level in
                SelectionCard(
                    title: level.displayName,
                    subtitle: level.description,
                    isSelected: viewModel.provisioningData.fitnessLevel == level,
                    icon: fitnessIcon(for: level)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.provisioningData.fitnessLevel = level
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
        case .pro: return "crown.fill"
        }
    }
}

// MARK: - Equipment Selection View
struct EquipmentSelectionView: View {
    @ObservedObject var viewModel: ProvisioningViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Quick select buttons
            HStack(spacing: 12) {
                Button("Select All") {
                    viewModel.selectAllEquipment()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("BrandPrimary").opacity(0.1))
                .foregroundColor(Color("BrandPrimary"))
                .cornerRadius(8)
                
                Button("Clear All") {
                    viewModel.clearAllEquipment()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("Surface2"))
                .foregroundColor(Color("SecondaryText"))
                .cornerRadius(8)
                
                Spacer()
            }
            
            // Equipment grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(viewModel.availableEquipment), id: \.self) { equipment in
                    EquipmentCard(
                        equipment: equipment,
                        isSelected: viewModel.provisioningData.availableEquipment.contains(equipment),
                        onTap: { viewModel.toggleEquipment(equipment) }
                    )
                }
            }
        }
        .padding(.top, 20)
        .onAppear {
            viewModel.loadEquipment()
        }
    }
}

// MARK: - Reusable Components

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

struct EquipmentCard: View {
    let equipment: Equipment
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: equipment.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color("SecondaryText"))
                
                Text(equipment.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding()
            .background(isSelected ? Color("BrandPrimary") : Color("Surface2"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("BrandPrimary") : Color("Border"), lineWidth: 1)
            )
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
