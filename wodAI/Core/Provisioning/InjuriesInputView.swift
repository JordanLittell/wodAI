//
//  InjuriesInputView.swift
//  wodAI
//
//  Created for WodAI provisioning workflow
//

import SwiftUI

struct InjuriesInputView: View {
    @ObservedObject var viewModel: ProvisioningViewModel
    @State private var showAddInjurySheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Question
            VStack(spacing: 16) {
                Image(systemName: "bandage.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color("BrandPrimary"))
                
                Text("Do you have any injuries or limitations?")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("PrimaryText"))
                    .multilineTextAlignment(.center)
                
                Text("We'll modify your workouts to work around any issues")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            
            // Quick Selection Buttons
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.provisioningData.hasInjuries = false
                    viewModel.removeInjuries();
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("No Injuries")
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        !viewModel.provisioningData.hasInjuries ? 
                        Color("BrandPrimary") : Color("Surface2")
                    )
                    .foregroundColor(
                        !viewModel.provisioningData.hasInjuries ? 
                        .white : Color("PrimaryText")
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    viewModel.provisioningData.hasInjuries = true
                    showAddInjurySheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                        Text("Add Injury")
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.provisioningData.hasInjuries ? 
                        Color("BrandPrimary") : Color("Surface2")
                    )
                    .foregroundColor(
                        viewModel.provisioningData.hasInjuries ? 
                        .white : Color("PrimaryText")
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Injuries List
            if !viewModel.provisioningData.getInjuries().isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("Current Injuries")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Spacer()
                    }
                    
                    ForEach(Array(viewModel.provisioningData.getInjuries().enumerated()), id: \.offset) { index, injury in
                        InjuryCard(
                            injury: Injury.from(input: injury),
                            onDelete: {
                                viewModel.removeInjury(at: index)
                                if viewModel.provisioningData.getInjuries().isEmpty {
                                    viewModel.provisioningData.hasInjuries = false
                                }
                            }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Info Card
            if viewModel.provisioningData.hasInjuries && viewModel.provisioningData.getInjuries().isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color("Warning"))
                    
                    Text("Tap 'Add Injury' to specify your limitations")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color("Warning").opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.top, 20)
        .sheet(isPresented: $showAddInjurySheet) {
            AddInjurySheet(viewModel: viewModel)
        }
    }
}

// MARK: - Injury Card
struct InjuryCard: View {
    let injury: Injury
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Severity Indicator
            Circle()
                .fill(severityColor(injury.severity))
                .frame(width: 12, height: 12)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(injury.bodyPart.capitalized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("•")
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text(injury.severity.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(Color("SecondaryText"))
                }
                
                if let description = injury.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color("SecondaryText"))
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }
    
    private func severityColor(_ severity: Injury.InjurySeverity) -> Color {
        switch severity {
        case .minor: return Color("Success")
        case .moderate: return Color("Warning")
        case .severe: return Color("Error")
        }
    }
}

// MARK: - Add Injury Sheet
struct AddInjurySheet: View {
    @ObservedObject var viewModel: ProvisioningViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedBodyPart: BodyPart = .shoulder
    @State private var selectedSeverity: Injury.InjurySeverity = .minor
    @State private var description: String = ""
    @State private var useCustomBodyPart = false
    @State private var customBodyPart: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Body Part Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Body Part", systemImage: "figure.stand")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(BodyPart.allCases.filter { $0 != .other }, id: \.self) { bodyPart in
                                BodyPartButton(
                                    title: bodyPart.displayName,
                                    isSelected: selectedBodyPart == bodyPart && !useCustomBodyPart,
                                    action: {
                                        selectedBodyPart = bodyPart
                                        useCustomBodyPart = false
                                        customBodyPart = ""
                                    }
                                )
                            }
                            
                            BodyPartButton(
                                title: "Other",
                                isSelected: useCustomBodyPart,
                                action: {
                                    useCustomBodyPart = true
                                    selectedBodyPart = .other
                                }
                            )
                        }
                        
                        if useCustomBodyPart {
                            TextField("Specify body part", text: $customBodyPart)
                                .padding()
                                .background(Color("Surface2"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("Border"), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Severity Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Severity", systemImage: "gauge")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        VStack(spacing: 12) {
                            ForEach(Injury.InjurySeverity.allCases, id: \.self) { severity in
                                SeverityButton(
                                    severity: severity,
                                    isSelected: selectedSeverity == severity,
                                    action: {
                                        selectedSeverity = severity
                                    }
                                )
                            }
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Additional Details (Optional)", systemImage: "text.alignleft")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color("Surface2"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("Border"), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Add Injury")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let bodyPart = useCustomBodyPart ? customBodyPart : selectedBodyPart.rawValue
                        let injury = Injury(
                            bodyPart: bodyPart,
                            severity: selectedSeverity,
                            description: description.isEmpty ? nil : description
                        )
                        viewModel.addInjury(injury)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color("BrandPrimary"))
                    .disabled(useCustomBodyPart && customBodyPart.isEmpty)
                }
            }
        }
    }
}

// MARK: - Body Part Button
struct BodyPartButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color("BrandPrimary") : Color("Surface"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color("Border"), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Severity Button
struct SeverityButton: View {
    let severity: Injury.InjurySeverity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(severityColor)
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(severity.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(severityDescription)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color("BrandPrimary") : Color("Border"))
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("BrandPrimary") : Color("Border"), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityColor: Color {
        switch severity {
        case .minor: return Color("Success")
        case .moderate: return Color("Warning")
        case .severe: return Color("Error")
        }
    }
    
    private var severityDescription: String {
        switch severity {
        case .minor: return "Slight discomfort, can work around it"
        case .moderate: return "Noticeable pain, needs modifications"
        case .severe: return "Significant limitation, avoid this area"
        }
    }
}

#Preview {
    InjuriesInputView(viewModel: ProvisioningViewModel())
}
