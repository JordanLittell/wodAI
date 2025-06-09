//
//  WODSessionManager.swift
//  wodAI
//
//  WOD Session System - Simplified for Current Integration
//  Persistent mini-player for active WOD sessions
//

import SwiftUI
import Combine

// MARK: - WOD Session Manager
@MainActor
class WODSessionManager: ObservableObject {
    static let shared = WODSessionManager()
    
    // MARK: - Published State
    @Published var isActive: Bool = false
    @Published var currentWOD: Workout?
    @Published var sessionPhase: WODPhase = .notStarted
    @Published var elapsedTime: TimeInterval = 0
    
    // MARK: - Timer Management
    private var sessionTimer: Timer?
    private var sessionStartTime: Date?
    private var pausedElapsedTime: TimeInterval = 0
    
    private init() {
        // Restore any active session on app launch
        restoreActiveSession()
    }
    
    // MARK: - Session Control
    func startWOD(_ workout: Workout) {
        // End any existing session first
        endWOD()
        
        // Set active workout
        currentWOD = workout
        
        // Initialize session state
        isActive = true
        sessionPhase = .active
        elapsedTime = 0
        pausedElapsedTime = 0
        
        // Start timer
        startTimer()
        
        // Persist session
        saveActiveSession()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .wodSessionStarted, object: workout)
        
        print("🏋️‍♂️ WOD session started: \(workout.format)")
    }
    
    func pauseWOD() {
        guard sessionPhase == .active else { return }
        
        // Save current elapsed time before pausing
        pausedElapsedTime = elapsedTime
        
        sessionPhase = .paused
        pauseTimer()
        
        NotificationCenter.default.post(name: .wodSessionPaused, object: nil)
        print("⏸️ WOD paused at \(formatTime(elapsedTime))")
    }
    
    func resumeWOD() {
        guard sessionPhase == .paused else { return }
        
        sessionPhase = .active
        resumeTimer()
        
        NotificationCenter.default.post(name: .wodSessionResumed, object: nil)
        print("▶️ WOD resumed")
    }
    
    func completeWOD() {
        guard isActive else { return }
        
        // Stop timer
        stopTimer()
        
        // Mark as completed
        sessionPhase = .completed
        
        // Call the existing markCompleted functionality if available
        NotificationCenter.default.post(name: .wodSessionCompleted, object: currentWOD)
        
        print("✅ WOD completed in \(formatTime(elapsedTime))!")
        
        // Clear session state after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.endWOD()
        }
    }
    
    func endWOD() {
        // Stop timer
        stopTimer()
        
        // Clear session state
        isActive = false
        currentWOD = nil
        elapsedTime = 0
        pausedElapsedTime = 0
        sessionPhase = .notStarted
        
        // Clear persisted session
        clearActiveSession()
        
        print("🛑 WOD session ended")
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        sessionStartTime = Date()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateElapsedTime()
            }
        }
    }
    
    private func pauseTimer() {
        sessionTimer?.invalidate()
    }
    
    private func resumeTimer() {
        // When resuming, adjust the start time to account for paused time
        let pausedDuration = pausedElapsedTime
        sessionStartTime = Date().addingTimeInterval(-pausedDuration)
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateElapsedTime()
            }
        }
    }
    
    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        sessionStartTime = nil
        pausedElapsedTime = 0
    }
    
    private func updateElapsedTime() {
        guard let sessionStartTime = sessionStartTime else { return }
        elapsedTime = Date().timeIntervalSince(sessionStartTime)
    }
    
    // MARK: - Persistence
    private func saveActiveSession() {
        guard let workout = currentWOD else { return }
        
        let sessionData = WODSessionData(
            workout: workout,
            startTime: sessionStartTime ?? Date(),
            elapsedTime: elapsedTime,
            phase: sessionPhase
        )
        
        if let encoded = try? JSONEncoder().encode(sessionData) {
            UserDefaults.standard.set(encoded, forKey: "activeWODSession")
        }
    }
    
    private func restoreActiveSession() {
        guard let data = UserDefaults.standard.data(forKey: "activeWODSession"),
              let sessionData = try? JSONDecoder().decode(WODSessionData.self, from: data) else { return }
        
        // Only restore if session is less than 24 hours old
        let hoursSinceStart = Date().timeIntervalSince(sessionData.startTime) / 3600
        guard hoursSinceStart < 24 else {
            clearActiveSession()
            return
        }
        
        // Restore session state
        currentWOD = sessionData.workout
        sessionStartTime = sessionData.startTime
        elapsedTime = Date().timeIntervalSince(sessionData.startTime)
        pausedElapsedTime = elapsedTime // Preserve the elapsed time when restoring
        sessionPhase = .paused // Always restore as paused
        isActive = true
        
        print("🔄 Restored active WOD session")
    }
    
    private func clearActiveSession() {
        UserDefaults.standard.removeObject(forKey: "activeWODSession")
    }
}

// MARK: - WOD Phase Enum
enum WODPhase: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .notStarted: return "play.circle"
        case .active: return "bolt.circle.fill"
        case .paused: return "pause.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Session Data for Persistence
struct WODSessionData: Codable {
    let workout: Workout
    let startTime: Date
    let elapsedTime: TimeInterval
    let phase: WODPhase
}

// MARK: - Helper Functions
func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let wodSessionStarted = Notification.Name("wodSessionStarted")
    static let wodSessionPaused = Notification.Name("wodSessionPaused")
    static let wodSessionResumed = Notification.Name("wodSessionResumed")
    static let wodSessionCompleted = Notification.Name("wodSessionCompleted")
}

// MARK: - Integration Extension for WorkoutGeneratorViewModel
extension WorkoutGeneratorViewModel {
    func startWODSession() {
        Task { @MainActor in
            WODSessionManager.shared.startWOD(self.workout)
        }
    }
}
