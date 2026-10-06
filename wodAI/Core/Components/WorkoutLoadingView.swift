//
//  WorkoutLoadingView.swift
//  wodAI
//
//  Loading state view for workout generation
//

import SwiftUI

struct WorkoutLoadingView: View {
    let workout: Workout?
    
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color("Surface2"), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color("BrandPrimary"), Color("BrandSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(animationPhase))
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: animationPhase
                    )
                
                Image(systemName: "bolt.fill")
                    .font(.title3)
                    .foregroundColor(Color("BrandPrimary"))
                    .scaleEffect(1.0 + sin(animationPhase * .pi / 90) * 0.1)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: animationPhase
                    )
            }
            
            VStack(spacing: 12) {
                Text("Generating your workout...")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                
                Text("Our AI is crafting the perfect workout for you based on your recent activity and goals.")
                    .font(.body)
                    .foregroundColor(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                if let workout = workout, !workout.name.isEmpty {
                    Text("Workout: \(workout.name)")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                        .padding(.top, 8)
                }
            }
            
            // Generation status indicators
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color("BrandPrimary"))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == Int(animationPhase / 60) % 3 ? 1.5 : 1.0)
                        .opacity(index == Int(animationPhase / 60) % 3 ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(),
                            value: animationPhase
                        )
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color("Surface"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            animationPhase = 360
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        WorkoutLoadingView(workout: Workout.generatingExample)
            .padding()
        
        WorkoutLoadingView(workout: nil)
            .padding()
    }
    .background(Color("Background"))
}
