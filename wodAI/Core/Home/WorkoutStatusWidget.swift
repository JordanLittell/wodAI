//
//  WorkoutStatusWidget.swift
//  wodAI
//
//  A compact widget showing workout status on the home page
//

import SwiftUI
import WodAiAPI

struct WorkoutStatusWidget: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @EnvironmentObject var wodSessionManager: WODSessionManager
    
    var body: some View {
        if wodSessionManager.isActive {
            // Active workout widget
            ActiveWorkoutWidget()
        } else if workoutGenerator.workout != nil {
            // Ready to start widget
            WorkoutReadyWidget()
                .environmentObject(workoutGenerator)
        }
    }
}

// MARK: - Active Workout Widget
struct ActiveWorkoutWidget: View {
    @EnvironmentObject var wodSessionManager: WODSessionManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            StatusIndicator(phase: wodSessionManager.sessionPhase)
                .frame(width: 40, height: 40)
            
            // Workout info
            VStack(alignment: .leading, spacing: 4) {
                Text("Active WOD")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                HStack(spacing: 12) {
                    // Timer
                    Label(formatTime(wodSessionManager.elapsedTime), systemImage: "timer")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                    
                    // Status
                    Text("• \(wodSessionManager.sessionPhase.rawValue)")
                        .font(.caption)
                        .foregroundColor(wodSessionManager.sessionPhase.color)
                }
            }
            
            Spacer()
            
            // Quick action button
            Button(action: handleQuickAction) {
                Image(systemName: quickActionIcon)
                    .font(.title3)
                    .foregroundColor(.brandPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color(.interactiveSurface))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.surface))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var quickActionIcon: String {
        switch wodSessionManager.sessionPhase {
        case .active:
            return "pause.fill"
        case .paused:
            return "play.fill"
        default:
            return "chevron.right"
        }
    }
    
    private func handleQuickAction() {
        switch wodSessionManager.sessionPhase {
        case .active:
            wodSessionManager.pauseWOD()
        case .paused:
            wodSessionManager.resumeWOD()
        default:
            break
        }
    }
}

// MARK: - Status Indicator with Pulsing Animation
struct StatusIndicator: View {
    let phase: WODPhase
    
    var body: some View {
        ZStack {
            // Only show pulsing rings when active
            if phase == .active {
                // Create 3 pulsing rings with different delays
                ForEach(0..<2) { index in
                    PulsingRing(delay: Double(index) * 0.4)
                }
            }
            
            // Main status dot
            Circle()
                .fill(phase.color)
                .frame(width: 12, height: 12)
        }
    }
}

// MARK: - Pulsing Ring Component
struct PulsingRing: View {
    let delay: Double
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .stroke(Color.green, lineWidth: 1.5)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: 2)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    scale = 2
                    opacity = 0
                }
            }
    }
}

// MARK: - Workout Ready Widget
struct WorkoutReadyWidget: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Ready indicator
            Image(systemName: "bolt.circle.fill")
                .font(.title2)
                .foregroundColor(.heroStart)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout Ready")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                if let workout = workoutGenerator.workout {
                    Text(workout.format)
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // View button
            Text("View")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.brandPrimary)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.brandPrimary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(.heroStart).opacity(0.1), Color(.heroEnd).opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.heroStart.opacity(0.3), .heroEnd.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(16)
    }
}
