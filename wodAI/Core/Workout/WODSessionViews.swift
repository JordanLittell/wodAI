//
//  WODSessionViews.swift
//  wodAI
//
//  UI Components for WOD Session System
//

import SwiftUI

// MARK: - WOD Mini-Player
struct WODMiniPlayer: View {
    @ObservedObject private var sessionManager = WODSessionManager.shared
    @State private var showFullWOD = false
    
    var body: some View {
        if sessionManager.isActive, let wod = sessionManager.currentWOD {
            VStack(spacing: 0) {
                // Top border indicator
                Rectangle()
                    .fill(sessionManager.sessionPhase.color)
                    .frame(height: 3)
                
                // Mini player bar
                Button(action: { showFullWOD = true }) {
                    HStack(spacing: 12) {
                        // Phase indicator
                        Image(systemName: sessionManager.sessionPhase.icon)
                            .foregroundColor(sessionManager.sessionPhase.color)
                            .font(.title3)
                        
                        // WOD info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(wod.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(sessionManager.sessionPhase.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Time
                        Text(formatTime(sessionManager.elapsedTime))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(sessionManager.sessionPhase.color)
                        
                        // Quick action button with better tap target
                        Button(action: quickAction) {
                            Image(systemName: quickActionIcon)
                                .font(.title3)
                                .foregroundColor(sessionManager.sessionPhase.color)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
            )
            .clipShape(Rectangle())
            .clipped()
            .sheet(isPresented: $showFullWOD) {
                ActiveWODView()
            }
        }
    }
    
    private var quickActionIcon: String {
        switch sessionManager.sessionPhase {
        case .active: return "pause.fill"
        case .paused: return "play.fill"
        default: return "play.fill"
        }
    }
    
    private func quickAction() {
        switch sessionManager.sessionPhase {
        case .active:
            sessionManager.pauseWOD()
        case .paused:
            sessionManager.resumeWOD()
        default:
            break
        }
    }
}

// MARK: - Full Active WOD View
struct ActiveWODView: View {
    @ObservedObject var sessionManager = WODSessionManager.shared
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.background)
                    .ignoresSafeArea()
                
                if let wod = sessionManager.currentWOD {
                    VStack(spacing: 24) {
                        // Timer Section - Primary Focus
                        TimerDisplay()
                            .padding(.top, 20)
                        
                        // Workout Components
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(wod.components.sorted(by: { $0.order < $1.order })) { component in
                                    WODDefinitionCard(definition: component.definition)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        Spacer()
                        
                        // Control Buttons
                        WODControls()
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Active WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Minimize") { 
                        dismiss() 
                    }
                    .foregroundColor(.brandPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("End") {
                        sessionManager.completeWOD()
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

// MARK: - Timer Display
struct TimerDisplay: View {
    @ObservedObject var sessionManager = WODSessionManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Large Timer
            Text(formatTime(sessionManager.elapsedTime))
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundColor(.primaryText)
            
            // Status Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(sessionManager.sessionPhase.color)
                    .frame(width: 10, height: 10)
                
                Text(sessionManager.sessionPhase.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(sessionManager.sessionPhase.color)
            }
        }
    }
}

// MARK: - WOD Definition Card
struct WODDefinitionCard: View {
    let definition: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.brandPrimary)
                Text("WORKOUT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondaryText)
                Spacer()
            }
            
            Text(definition)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.surface))
        .cornerRadius(12)
    }
}

// MARK: - WOD Controls
struct WODControls: View {
    @ObservedObject var sessionManager = WODSessionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack(spacing: 16) {
            // Pause/Resume Button
            Button(action: togglePauseResume) {
                HStack {
                    Image(systemName: sessionManager.sessionPhase == .active ? "pause.fill" : "play.fill")
                    Text(sessionManager.sessionPhase == .active ? "Pause" : "Resume")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    sessionManager.sessionPhase == .active ? 
                    Color.orange : Color.green
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Complete Button
            Button(action: {
                sessionManager.completeWOD()
                dismiss()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.heroStart, .heroEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private func togglePauseResume() {
        if sessionManager.sessionPhase == .active {
            sessionManager.pauseWOD()
        } else {
            sessionManager.resumeWOD()
        }
    }
}

// MARK: - Start WOD Button Component
struct StartWODButton: View {
    let workout: Workout
    let onStart: (() -> Void)?
    @ObservedObject private var sessionManager = WODSessionManager.shared
    @State private var showingCountdown = false
    @State private var countdownValue = 5
    @State private var countdownTimer: Timer?
    
    init(workout: Workout, onStart: (() -> Void)? = nil) {
        self.workout = workout
        self.onStart = onStart
    }
    
    var body: some View {
        ZStack {
            // Main Button
            Button(action: {
                startCountdown()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start WOD")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.heroStart, .heroEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(sessionManager.isActive || showingCountdown)
            .opacity(showingCountdown ? 0.3 : 1.0)
            
            // Countdown Overlay
            if showingCountdown {
                CountdownView(value: countdownValue)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingCountdown)
    }
    
    private func startCountdown() {
        showingCountdown = true
        countdownValue = 5
        
        // Start countdown timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                // Countdown finished
                timer.invalidate()
                countdownTimer = nil
                showingCountdown = false

                onStart?()
            }
        }
    }
}

// MARK: - Countdown View
struct CountdownView: View {
    let value: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background blur
            Circle()
                .fill(.black.opacity(0.8))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
            
            // Countdown number
            Text("\(value)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onChange(of: value) { _, _ in
            // Pulse animation on value change
            withAnimation(.easeOut(duration: 0.1)) {
                scale = 1.2
            }
            withAnimation(.easeIn(duration: 0.1).delay(0.1)) {
                scale = 1.0
            }
        }
    }
}
