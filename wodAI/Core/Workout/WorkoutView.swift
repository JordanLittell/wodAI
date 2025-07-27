//
//  WorkoutView.swift
//  wodAI
//
//  Enhanced Workout View with Component-based Display
//

import SwiftUI
import WodAiAPI

struct WorkoutView: View {
    @EnvironmentObject var wgvm: EnhancedWorkoutGeneratorViewModel
    @ObservedObject private var sessionManager = WODSessionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingActiveWOD: Bool = false
    @State private var showingTweakOptions: Bool = false
    @State private var isUpdatingWOD: Bool = false
    @State private var isCompletingWorkout: Bool = false
    @State private var showCompletionAlert: Bool = false
    @State private var showingStimulusInfo: Bool = false
    
    var body: some View {
        if wgvm.generating {
            WorkoutLaunchAnimation()
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    workoutHeader
                    
                    if let workout = wgvm.workout {
                        // Progress Overview
                        WorkoutProgressView(workout: workout)
                        
                        ComponentsSection(
                            workout: workout,
                            isUpdating: isUpdatingWOD
                        )
                        
                        if sessionManager.isActive {
                            wodSessionStatusBanner
                        }
                        
                        completeWorkoutButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, sessionManager.isActive ? 120 : 20)
            }
            .background(Color("Background"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let workout = wgvm.workout, !workout.description.isEmpty {
                        Button(action: {
                            showingStimulusInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color("BrandPrimary"))
                                .font(.title3)
                        }
                    }
                }
            }
            .alert("Workout Completed! 🎉", isPresented: $showCompletionAlert) {
                Button("Great!", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Congratulations on completing your workout! Keep up the great work.")
            }
            .sheet(isPresented: $showingStimulusInfo) {
                if let workout = wgvm.workout {
                    WorkoutStimulusSheet(workout: workout)
                }
            }
        }
    }
    
    private var workoutHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let workout = wgvm.workout {
                // Workout Name
                Text(workout.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }
    
    private var wodSessionStatusBanner: some View {
        Button(action: {
            showingActiveWOD = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: sessionManager.sessionPhase.icon)
                    .foregroundColor(sessionManager.sessionPhase.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout \(sessionManager.sessionPhase.rawValue)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("Tap to view • \(formatTime(sessionManager.elapsedTime))")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                Button(action: {
                    if sessionManager.sessionPhase == .active {
                        sessionManager.pauseWOD()
                    } else if sessionManager.sessionPhase == .paused {
                        sessionManager.resumeWOD()
                    }
                }) {
                    Image(systemName: sessionManager.sessionPhase == .active ? "pause.circle.fill" : "play.circle.fill")
                        .foregroundColor(sessionManager.sessionPhase.color)
                        .font(.title2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(sessionManager.sessionPhase.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(sessionManager.sessionPhase.color.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    
    private var completeWorkoutButton: some View {
        Group {
            if let workout = wgvm.workout {
                Button(action: {
                    completeWorkout(workout)
                }) {
                    HStack(spacing: 12) {
                        if isCompletingWorkout {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }
                        
                        Text(isCompletingWorkout ? "Completing..." : "Complete Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if !isCompletingWorkout {
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color("Success"), Color("HeroEnd")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color("Success").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isCompletingWorkout)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Complete Workout Action
    private func completeWorkout(_ workout: Workout) {
        isCompletingWorkout = true
        
        // Stop any active session
        if sessionManager.isActive {
            sessionManager.completeWOD()
        }
        
        print("completing the workout: \(workout.id) \(workout.name)")
        // Call the GraphQL mutation to mark workout as complete
        Network.shared.client.perform(mutation: CompleteWodMutation(completeWodId: workout.id)) { result in
            DispatchQueue.main.async {
                isCompletingWorkout = false
                
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        print("❌ Failed to mark workout as completed: \(errors)")
                    } else if graphQLResult.data?.completeWod.completed == true {
                        print("✅ Workout marked as completed successfully")
                        // Show success alert
                        showCompletionAlert = true
                        
                        // Clear the current workout from the generator
                        wgvm.workout = nil
                        
                        // Post notification that workout was completed
                        NotificationCenter.default.post(name: .workoutCompleted, object: nil)
                    } else {
                        print("⚠️ Unexpected response when completing workout")
                    }
                    
                case .failure(let error):
                    print("Error completing workout: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var wodButtonIcon: String {
        switch sessionManager.sessionPhase {
        case .notStarted: return "play.fill"
        case .active: return "pause.fill"
        case .paused: return "play.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    private var wodButtonText: String {
        switch sessionManager.sessionPhase {
        case .notStarted: return "Start"
        case .active: return "Pause"
        case .paused: return "Resume"
        case .completed: return "Complete"
        }
    }
    
    private var wodButtonColors: [Color] {
        switch sessionManager.sessionPhase {
        case .notStarted: return [Color("Success"), Color("BrandPrimary")]
        case .active: return [.orange, .red]
        case .paused: return [Color("BrandPrimary"), Color("Success")]
        case .completed: return [.purple, Color("BrandPrimary")]
        }
    }
    
    // MARK: - Actions
    private func handleWODButtonAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        switch sessionManager.sessionPhase {
        case .notStarted:
            wgvm.startWODSession()
            showingActiveWOD = true
        case .active:
            sessionManager.pauseWOD()
        case .paused:
            sessionManager.resumeWOD()
            showingActiveWOD = true
        case .completed:
            wgvm.startWODSession()
            showingActiveWOD = true
        }
    }
    
    private func adjustDuration(shorter: Bool) {
        guard wgvm.workout != nil else { return }
        let adjustment = shorter ? -10 : 10
        let instruction = shorter ?
            "Make this workout shorter by about \(abs(adjustment)) minutes while maintaining effectiveness" :
            "Extend this workout by about \(adjustment) minutes with additional exercises or sets"
        updateWorkout(with: instruction)
    }
    
    private func adjustIntensity(increase: Bool) {
        let instruction = increase ?
            "Increase the intensity by adding more challenging variations and reducing rest time" :
            "Decrease the intensity with easier variations and longer rest periods"
        updateWorkout(with: instruction)
    }
    
    private func updateWorkout(with instruction: String) {
        guard let workout = wgvm.workout else { return }
        isUpdatingWOD = true
        
        // Implement the update via Network
        Network.shared.client.perform(mutation: UpdateWodMutation(
            updateWodId: workout.id,
            instructions: instruction
        )) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors, !errors.isEmpty {
                        print("Update error: \(errors.first?.message ?? "Unknown error")")
                    } else if let updatedWod = graphqlResult.data?.updateWod {
                        // Update the workout in the view model
                        // Note: This needs to be adapted based on your actual GraphQL response structure
                        isUpdatingWOD = false
                    }
                    
                case .failure(let error):
                    print("Network error: \(error.localizedDescription)")
                    isUpdatingWOD = false
                }
            }
        }
    }
    
    private func regenerateWorkout() {
        isUpdatingWOD = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            wgvm.generateQuickWorkout(type: .intelligent)
            isUpdatingWOD = false
        }
    }
    
    private func shareWorkout() {
        guard let workout = wgvm.workout else { return }
        
        let shareText = """
        Check out this workout from wodAI!
        
        \(workout.name)
        
        \(workout.components.map { component in
            "\(component.name):\n\(component.definition)"
        }.joined(separator: "\n\n"))
        
        #wodAI #fitness #workout
        """
        
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct ComponentsSection: View {
    let workout: Workout
    let isUpdating: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(workout.components.sorted(by: { $0.order < $1.order })) { component in
                ComponentCard(
                    component: component,
                    workoutId: workout.id,
                    isUpdating: isUpdating
                )
            }
        }
    }
}

struct CoachingSection: View {
    let coaching: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color("BrandSecondary"))
                    .font(.title3)
                
                Text("Coaching Points")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
            }
            
            Text(coaching)
                .font(.body)
                .foregroundColor(Color("SecondaryText"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("Surface2"))
        )
    }
}

struct WorkoutStimulusSheet: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(Color("BrandPrimary"))
                                .font(.title2)
                            
                            Text("Workout Stimulus")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("PrimaryText"))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Stimulus Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(workout.description)
                            .font(.body)
                            .foregroundColor(Color("PrimaryText"))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("Surface2"))
                    )
                    .padding(.horizontal)
                    
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color("Background"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("BrandPrimary"))
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        WorkoutView()
            .environmentObject(EnhancedWorkoutGeneratorViewModel(
                generating: false,
                workout: Workout.example
            ))
    }
}
