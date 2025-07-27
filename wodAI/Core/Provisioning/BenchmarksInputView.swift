//
//  BenchmarksInputView.swift
//  wodAI
//
//  Created for WodAI provisioning workflow
//

import SwiftUI

struct BenchmarksInputView: View {
    @ObservedObject var viewModel: ProvisioningViewModel
    @FocusState private var focusedField: BenchmarkType?
    
    var body: some View {
        VStack(spacing: 20) {
            // Info card
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("BrandPrimary"))
                
                Text("Select at least one benchmark to help us calibrate your workouts")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(Color("BrandPrimary").opacity(0.1))
            .cornerRadius(12)
            
            // Benchmarks list
            VStack(spacing: 16) {
                ForEach(BenchmarkType.allCases, id: \.self) { benchmark in
                    BenchmarkInputCard(
                        benchmark: benchmark,
                        isSelected: viewModel.selectedBenchmarks.contains(benchmark),
                        value: viewModel.benchmarkInputs[benchmark] ?? "",
                        onToggle: {
                            viewModel.toggleBenchmark(benchmark)
                        },
                        onValueChange: { value in
                            viewModel.benchmarkInputs[benchmark] = value
                        },
                        isFocused: focusedField == benchmark,
                        onFocusChange: { isFocused in
                            if isFocused {
                                focusedField = benchmark
                            }
                        }
                    )
                }
            }
            
            // Tips
            if !viewModel.selectedBenchmarks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("SecondaryText"))
                    
                    if viewModel.selectedBenchmarks.contains(.runMile) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(Color("SecondaryText"))
                            Text("Enter run time as MM:SS (e.g., 7:30)")
                                .font(.caption)
                                .foregroundColor(Color("SecondaryText"))
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                        Text("Enter your current personal best or recent performance")
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                    }
                }
                .padding()
                .background(Color("Surface2"))
                .cornerRadius(8)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Benchmark Input Card
struct BenchmarkInputCard: View {
    let benchmark: BenchmarkType
    let isSelected: Bool
    let value: String
    let onToggle: () -> Void
    let onValueChange: (String) -> Void
    let isFocused: Bool
    let onFocusChange: (Bool) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Selection Header
            Button(action: onToggle) {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: benchmark.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? Color("BrandPrimary") : Color("SecondaryText"))
                        .frame(width: 24)
                    
                    // Title
                    Text(benchmark.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("PrimaryText"))
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? Color("BrandPrimary") : Color("Border"))
                }
                .padding(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Input Field (shown when selected)
            if isSelected {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color("Border"))
                    
                    HStack(spacing: 12) {
                        if benchmark == .runMile {
                            // Time input for running
                            TimeInputField(
                                value: value,
                                onValueChange: onValueChange
                            )
                            .focused($isTextFieldFocused)
                        } else {
                            // Numeric input for weights/reps
                            TextField("Enter value", text: Binding(
                                get: { value },
                                set: { onValueChange($0) }
                            ))
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .frame(width: 100)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color("Surface2"))
                            .cornerRadius(8)
                            .focused($isTextFieldFocused)
                        }
                        
                        // Unit label
                        Text(benchmark.unit)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("SecondaryText"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onChange(of: isTextFieldFocused) { _, isFocused in
            onFocusChange(isFocused)
        }
    }
}

// MARK: - Time Input Field
struct TimeInputField: View {
    let value: String
    let onValueChange: (String) -> Void
    
    @State private var minutes: String = ""
    @State private var seconds: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case minutes, seconds
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Minutes
            TextField("00", text: $minutes)
                .keyboardType(.numberPad)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color("Surface2"))
                .cornerRadius(8)
                .focused($focusedField, equals: .minutes)
                .onChange(of: minutes) { _, newValue in
                    // Limit to 2 digits
                    if newValue.count > 2 {
                        minutes = String(newValue.prefix(2))
                    }
                    updateValue()
                    
                    // Auto-advance to seconds field
                    if newValue.count == 2 && focusedField == .minutes {
                        focusedField = .seconds
                    }
                }
            
            Text(":")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("PrimaryText"))
            
            // Seconds
            TextField("00", text: $seconds)
                .keyboardType(.numberPad)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .frame(width: 40)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color("Surface2"))
                .cornerRadius(8)
                .focused($focusedField, equals: .seconds)
                .onChange(of: seconds) { _, newValue in
                    // Limit to 2 digits and max 59
                    if newValue.count > 2 {
                        seconds = String(newValue.prefix(2))
                    }
                    if let sec = Int(seconds), sec > 59 {
                        seconds = "59"
                    }
                    updateValue()
                }
        }
        .onAppear {
            // Parse existing value
            let components = value.split(separator: ":")
            if components.count == 2 {
                minutes = String(components[0])
                seconds = String(components[1])
            }
        }
    }
    
    private func updateValue() {
        let formattedMinutes = minutes.isEmpty ? "0" : minutes
        let formattedSeconds = seconds.isEmpty ? "00" : (seconds.count == 1 ? "0\(seconds)" : seconds)
        onValueChange("\(formattedMinutes):\(formattedSeconds)")
    }
}

#Preview {
    BenchmarksInputView(viewModel: ProvisioningViewModel())
}
