//
//  GeneratingView.swift
//  wodAI
//
//  Created by Jordan Littell on 4/26/25.
//
import SwiftUI

struct WorkoutLaunchAnimation: View {
    @State private var isAnimating = false
    @State private var showFirstText = false
    @State private var pulseEffect = false
    @State private var shimmerOffset: CGFloat = -0.25
    
    var body: some View {
        ZStack {
            // Add a background color so text is visible
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Text centered horizontally with shimmer effect
                ShimmeringText(text: "Creating something epic!", isShimmering: showFirstText)
                    .font(.title)
                    .opacity(showFirstText ? 1 : 0)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 1.2), value: showFirstText)
                
                Spacer()
                
                // Pulse effect centered horizontally
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseEffect ? 1 : 0)
                    
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.blue.opacity(0.8 - Double(i) * 0.2), lineWidth: 4)
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseEffect ? 1 + Double(i) * 0.4 : 1)
                            .opacity(pulseEffect ? 0 : 0.8)
                            .animation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.3),
                                value: pulseEffect
                            )
                    }
                    
                    // Center icon
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .opacity(pulseEffect ? 1 : 0)
                        .scaleEffect(pulseEffect ? 1 : 0.5)
                        .animation(.spring(response: 0.7), value: pulseEffect)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    func startAnimationSequence() {
        isAnimating = true
        
        // First text appears
        withAnimation {
            showFirstText = true
        }
        
        // Pulse animation starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                pulseEffect = true
            }
        }
    }
}

// Shimmering text component
struct ShimmeringText: View {
    let text: String
    let isShimmering: Bool
    @State private var shimmerOffset: CGFloat = -0.25
    
    var body: some View {
        ZStack {
            Text(text)
                .foregroundColor(.white)
            
            // Shimmer effect overlay (only visible when isShimmering is true)
            if isShimmering {
                Text(text)
                    .foregroundColor(.white)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: shimmerOffset - 0.2),
                                .init(color: .white.opacity(0.5), location: shimmerOffset),
                                .init(color: .white, location: shimmerOffset + 0.05),
                                .init(color: .white.opacity(0.5), location: shimmerOffset + 0.1),
                                .init(color: .clear, location: shimmerOffset + 0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            shimmerOffset = 1.25
                        }
                    }
            }
        }
    }
}

// Preview
struct WorkoutLaunchAnimation_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLaunchAnimation()
    }
}
