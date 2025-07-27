//
//  ComponentCard.swift
//  wodAI
//
//  Created by Jordan Littell on 7/22/25.
//

import SwiftUI

struct ComponentCard: View {
    let component: Component
    let workoutId: String
    let isUpdating: Bool
    @StateObject private var completionManager = ComponentCompletionManager.shared
    @State private var showingDetail: Bool = false
    
    private var isCompleted: Bool {
        completionManager.isCompleted(workoutId: workoutId, componentOrder: component.order)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and completion toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(component.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isCompleted ? Color("Success") : Color("PrimaryText"))
                }
                
                Spacer()
                
                // Completion toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        completionManager.toggleCompleted(workoutId: workoutId, componentOrder: component.order)
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? Color("Success") : Color("Border"), lineWidth: 2)
                            .fill(Color("disabled"))
                            .frame(width: 28, height: 28)
                        
                        if isCompleted {
                            Circle()
                                .fill(Color("Success"))
                                .frame(width: 28, height: 28)
                                .transition(.scale.combined(with: .opacity))
                            
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(.gray)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                }
            }
            
            // Tappable content area
            Button(action: {
                showingDetail = true
            }) {
                Text(component.definition)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color("PrimaryText"))
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("InteractiveSurface"))
                    )
                    .overlay(
                        isUpdating ? 
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            ) : nil
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isCompleted ? Color("Success").opacity(0.05) : Color("Surface"))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isCompleted ? Color("Success").opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .sheet(isPresented: $showingDetail) {
            ComponentDetailView(
                component: component,
                isCompleted: completionManager.binding(for: workoutId, componentOrder: component.order)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ComponentCard(
            component: Component(
                name: "Warm-up",
                order: 1,
                definition: "5 min row\n10 PVC pass-throughs\n10 Overhead squats (empty bar)",
                description: "Prepare the body for the workout",
                targetFitnessDomains: ["flexibility", "mobility"],
                energySystems: ["aerobic"]
            ),
            workoutId: "preview-workout-1",
            isUpdating: false
        )
        
        ComponentCard(
            component: Component(
                name: "Strength",
                order: 2,
                definition: "Back Squat\n5-5-3-3-1-1\nWork up to a heavy single",
                description: "Build strength in the posterior chain",
                targetFitnessDomains: ["strength"],
                energySystems: ["phosphagen"]
            ),
            workoutId: "preview-workout-1",
            isUpdating: true
        )
    }
    .padding()
    .background(Color("Background"))
}
