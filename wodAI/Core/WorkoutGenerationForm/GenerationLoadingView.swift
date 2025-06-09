//
//  GenerationLoadingView.swift
//  wodAI
//
//  Created by Jordan Littell on 6/8/25.
//
import SwiftUI

struct GenerationLoadingView: View {
    @State private var animationStep = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private let loadingSteps = [
        "Analyzing your preferences...",
        "Selecting optimal exercises...",
        "Calculating sets and reps...",
        "Personalizing intensity...",
        "Finalizing your workout..."
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            // Animated AI Brain Icon
            ZStack {
                // Outer pulse rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i * 30), height: 120 + CGFloat(i * 30))
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.3),
                            value: pulseScale
                        )
                }
                
                // Central brain icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 3) * 0.1)
            }
            
            // Loading Steps
            VStack(spacing: 20) {
                Text("Creating Your Perfect Workout")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    ForEach(0..<loadingSteps.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            // Step indicator
                            ZStack {
                                Circle()
                                    .fill(stepColor(for: index))
                                    .frame(width: 24, height: 24)
                                
                                if index < animationStep {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                } else if index == animationStep {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.6)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Step text
                            Text(loadingSteps[index])
                                .font(.subheadline)
                                .foregroundColor(index <= animationStep ? .primary : .secondary)
                                .animation(.easeInOut, value: animationStep)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            startAnimations()
        }
    }
    
    private func stepColor(for index: Int) -> Color {
        if index < animationStep {
            return .green
        } else if index == animationStep {
            return .blue
        } else {
            return .gray
        }
    }
    
    private func startAnimations() {
        // Start pulse animation
        withAnimation {
            pulseScale = 1.5
        }
        
        // Animate through steps
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if animationStep < loadingSteps.count - 1 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationStep += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
}
