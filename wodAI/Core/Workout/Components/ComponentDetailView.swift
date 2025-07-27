//
//  ComponentDetailView.swift
//  wodAI
//
//  Detailed view for a single component showing all information
//

import SwiftUI

struct ComponentDetailView: View {
    let component: Component
    @Binding var isCompleted: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Component Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(component.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color("PrimaryText"))
                            
                            Spacer()
                            
                            CompletionToggle(isCompleted: $isCompleted)
                        }
                        
                        if !component.description.isEmpty {
                            Text(component.description)
                                .font(.body)
                                .foregroundColor(Color("SecondaryText"))
                                .lineSpacing(4)
                        }
                    }
                    
                    // Definition Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(Color("BrandPrimary"))
                                .font(.title3)
                            
                            Text("Workout Definition")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("PrimaryText"))
                        }
                        
                        Text(component.definition)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color("PrimaryText"))
                            .lineSpacing(6)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("InteractiveSurface"))
                            )
                    }
                    
                    // Energy Systems Section
                    if let energySystems = component.energySystems, !energySystems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(Color("Warning"))
                                    .font(.title3)
                                
                                Text("Energy Systems")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("PrimaryText"))
                            }
                            
                            FlowLayout(spacing: 8) {
                                ForEach(energySystems, id: \.self) { system in
                                    EnergySystemChip(system: system)
                                }
                            }
                        }
                    }
                    
                    // Target Fitness Domains Section
                    if let domains = component.targetFitnessDomains, !domains.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .foregroundColor(Color("Success"))
                                    .font(.title3)
                                
                                Text("Target Fitness Domains")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("PrimaryText"))
                            }
                            
                            FlowLayout(spacing: 8) {
                                ForEach(domains, id: \.self) { domain in
                                    FitnessDomainChip(domain: domain)
                                }
                            }
                        }
                    }
                    
                    // Completion Status
                    CompletionStatusCard(isCompleted: isCompleted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color("Background"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            isCompleted.toggle()
                        }
                    }) {
                        Text(isCompleted ? "Mark Incomplete" : "Mark Complete")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isCompleted ? Color("Warning") : Color("Success"))
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CompletionToggle: View {
    @Binding var isCompleted: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isCompleted.toggle()
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }) {
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color("Success") : Color("Border"), lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Circle()
                        .fill(Color("Success"))
                        .frame(width: 32, height: 32)
                        .transition(.scale.combined(with: .opacity))
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "checkmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}

struct EnergySystemChip: View {
    let system: String
    
    var body: some View {
        Text(system.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color("Warning"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color("Warning").opacity(0.15))
            )
    }
}

struct FitnessDomainChip: View {
    let domain: String
    
    var body: some View {
        Text(domain.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color("Success"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color("Success").opacity(0.15))
            )
    }
}

struct CompletionStatusCard: View {
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title)
                .foregroundColor(isCompleted ? Color("Success") : Color("SecondaryText"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isCompleted ? "Component Completed!" : "Not Yet Completed")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                Text(isCompleted ? "Great job finishing this component!" : "Mark this component as complete when you finish it")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCompleted ? Color("Success").opacity(0.1) : Color("Surface2"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Color("Success").opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                     y: result.positions[index].y + bounds.minY),
                         proposal: ProposedViewSize(result.sizes[index]))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        
        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                sizes.append(size)
                
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    ComponentDetailView(
        component: Component(
            name: "WOD - Olympic Conditioning",
            order: 1,
            definition: """
            3 rounds for time:
            7 Power cleans (225 lbs)
            7 Ring muscle-ups
            500m row
            10 Box jumps (30 inch)
            """,
            description: "High-intensity workout combining heavy Olympic lifting with gymnastics and cardio",
            targetFitnessDomains: ["strength", "power", "endurance"],
            energySystems: ["glycolytic", "oxidative"]
        ),
        isCompleted: .constant(false)
    )
}
