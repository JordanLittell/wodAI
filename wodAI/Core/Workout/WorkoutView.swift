//
//  WorkoutView.swift
//  wodAI
//
//  Enhanced Workout Preview with Tweaking Options
//  Created by Jordan Littell on 4/16/25.
//
import SwiftUI
import WodAiAPI

struct WorkoutView: View {
    @EnvironmentObject var wgvm: EnhancedWorkoutGeneratorViewModel
    @ObservedObject private var sessionManager = WODSessionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showTimer: Bool = false
    @State private var showingTweakOptions: Bool = false
    @State private var isRegenerating: Bool = false
    @State private var showingActiveWOD: Bool = false
    @State private var isUpdatingWOD: Bool = false
    
    var body: some View {
        if wgvm.generating {
            WorkoutLaunchAnimation()
        } else {
            
            if showingActiveWOD {
                ActiveWODView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        workoutHeader
                        
                        // Main Workout Display - Full Width
                        if let workout = wgvm.workout {
                            EnhancedWorkoutDefinitionView(workout: workout, onShare: shareWorkout, isUpdating: isUpdatingWOD)
                            
                            // WOD Session Status Banner (if active)
                            if sessionManager.isActive {
                                wodSessionStatusBanner
                            }
                            
                            workoutTweakingSection
                                .opacity(sessionManager.sessionPhase == .active ? 0.6 : 1.0)
                                .disabled(sessionManager.sessionPhase == .active)
                            
                            
                            startWODButton
                        }
                    }
                    .padding(.horizontal, 8) // Reduced horizontal padding for more width
                    .padding(.bottom, sessionManager.isActive ? 120 : 20) // Account for mini-player
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Dismiss") {
                            dismiss()
                        }
                        .foregroundColor(.brandPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - WOD Session Status Banner
    private var wodSessionStatusBanner: some View {
        Button(action: {
            showingActiveWOD = true
        }) {
            HStack(spacing: 12) {
                // Status indicator
                Image(systemName: sessionManager.sessionPhase.icon)
                    .foregroundColor(sessionManager.sessionPhase.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout \(sessionManager.sessionPhase.rawValue)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryText)
                    
                    Text("Tap to view full workout • \(formatTime(sessionManager.elapsedTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Quick action button
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
                        .padding(8)
                        .background(
                            Circle()
                                .fill(sessionManager.sessionPhase.color.opacity(0.1))
                        )
                }
                .onTapGesture {
                    // Prevent the button tap from triggering the parent button
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(sessionManager.sessionPhase.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(sessionManager.sessionPhase.color.opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Header Section
    private var workoutHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Workout")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("Generated just for you")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Workout type indicator
                if let workout = wgvm.workout {
                    workoutTypeChip(format: workout.format)
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Workout Type Chip
    private func workoutTypeChip(format: String) -> some View {
        Text(format.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
    
    
    // MARK: - Workout Metadata
    private func workoutMetadata(workout: Workout) -> some View {
        VStack(spacing: 8) {
            Divider()
            
            if !workout.stimulus.isEmpty {
                HStack {
                    Label("Stimulus", systemImage: "bolt.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Spacer()
                }
                
                Text(workout.stimulus)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !workout.muscles.isEmpty {
                HStack {
                    Label("Target Muscles", systemImage: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Spacer()
                }
                
                Text(workout.muscles)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Start WOD Button
    private var startWODButton: some View {
        Group {
            if sessionManager.sessionPhase == .notStarted, let workout = wgvm.workout {
                // Use the StartWODButton component with countdown
                StartWODButton(workout: workout) {
                    sessionManager.startWOD(workout)
                    showingActiveWOD = true
                }
                .padding(.horizontal, 8)
            } else {
                // Use existing button for other states
                Button(action: {
                    handleWODButtonAction()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: wodButtonIcon)
                            .font(.title3)
                        
                        Text(wodButtonText)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: wodButtonColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .disabled(wgvm.updating)
                .padding(.horizontal, 8)
            }
        }
    }
    
    // MARK: - WOD Button Helpers
    private var wodButtonIcon: String {
        switch sessionManager.sessionPhase {
        case .notStarted:
            return "play.fill"
        case .active:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    private var wodButtonText: String {
        switch sessionManager.sessionPhase {
        case .notStarted:
            return "Start WOD"
        case .active:
            return "Pause WOD"
        case .paused:
            return "Resume WOD"
        case .completed:
            return "WOD Complete"
        }
    }
    
    private var wodButtonColors: [Color] {
        switch sessionManager.sessionPhase {
        case .notStarted:
            return [.green, .blue]
        case .active:
            return [.orange, .red]
        case .paused:
            return [.blue, .green]
        case .completed:
            return [.purple, .blue]
        }
    }
    
    private func handleWODButtonAction() {
        // Add haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        switch sessionManager.sessionPhase {
        case .notStarted:
            // Start a new WOD session and navigate to ActiveWODView
            wgvm.startWODSession()
            showingActiveWOD = true
            
        case .active:
            // Pause the current session
            sessionManager.pauseWOD()
            
        case .paused:
            // Resume the paused session and navigate to ActiveWODView
            sessionManager.resumeWOD()
            showingActiveWOD = true
            
        case .completed:
            // Session is complete, start a new one and navigate to ActiveWODView
            wgvm.startWODSession()
            showingActiveWOD = true
        }
    }
    
    // MARK: - Workout Tweaking Section
    private var workoutTweakingSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Quick Tweaks")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingTweakOptions.toggle()
                    }
                }) {
                    Image(systemName: showingTweakOptions ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            if showingTweakOptions {
                tweakOptionsGrid
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Tweak Options Grid
    private var tweakOptionsGrid: some View {
        VStack(spacing: 12) {
            // Duration adjustments
            HStack(spacing: 12) {
                TweakOptionButton(
                    title: "Shorter",
                    subtitle: "Less time",
                    icon: "minus.circle.fill",
                    color: .orange,
                    isLoading: isUpdatingWOD
                ) {
                    adjustDuration(shorter: true)
                }
                
                TweakOptionButton(
                    title: "Longer",
                    subtitle: "More time",
                    icon: "plus.circle.fill",
                    color: .blue,
                    isLoading: isUpdatingWOD
                ) {
                    adjustDuration(shorter: false)
                }
            }
            
            // Intensity adjustments
            HStack(spacing: 12) {
                TweakOptionButton(
                    title: "Less Intense",
                    subtitle: "Easier",
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    isLoading: isUpdatingWOD
                ) {
                    adjustIntensity(increase: false)
                }
                
                TweakOptionButton(
                    title: "More Intense",
                    subtitle: "Harder",
                    icon: "arrow.up.circle.fill",
                    color: .red,
                    isLoading: isUpdatingWOD
                ) {
                    adjustIntensity(increase: true)
                }
            }
            
            // Regenerate button
            TweakOptionButton(
                title: "Regenerate",
                subtitle: "Brand new workout",
                icon: "arrow.clockwise.circle.fill",
                color: .purple,
                isLoading: isUpdatingWOD,
                isFullWidth: true
            ) {
                regenerateWorkout()
            }
        }
    }
    
    // MARK: - Action Methods
    private func adjustDuration(shorter: Bool) {
        guard wgvm.workout != nil else { return }
        
        let adjustment = shorter ? -10 : 10
        let instruction = shorter ? 
            "Make this workout shorter by about \(abs(adjustment)) minutes while maintaining effectiveness" :
            "Extend this workout by about \(adjustment) minutes with additional exercises or sets"
        
        // Use the existing update method from WorkoutGeneratorViewModel
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
        
        // Set updating state
        // Note: We'll need to access the updating property if available
        
        // Create update input
        let input = UpdateWodInput(
            id: GraphQLNullable(stringLiteral: workout.id),
            instructions: GraphQLNullable(stringLiteral: instruction)
        )
        
        // Perform the update via Network
        Network.shared.client.perform(mutation: UpdateWodMutation(
            updateWodId: workout.id,
            input: input
        )) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let graphqlResult):
                    if let errors = graphqlResult.errors, !errors.isEmpty {
                        print("Update error: \(errors.first?.message ?? "Unknown error")")
                    } else if let updatedWod = graphqlResult.data?.updateWod {
                        // Update the workout in the view model
                        let updatedWorkout = Workout(
                            definition: updatedWod.definition,
                            stimulus: "",
                            muscles: "",
                            format: updatedWod.format,
                            id: updatedWod.id
                        )
                        wgvm.workout = updatedWorkout
                        isUpdatingWOD = false
                    }
                    
                case .failure(let error):
                    print("Network error: \(error.localizedDescription)")
                }
            }
        }
    }

    
    private func regenerateWorkout() {
        isUpdatingWOD = true
        
        // Use the last generation preferences to create a new workout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            wgvm.generateQuickWorkout(type: .intelligent)
            isUpdatingWOD = false
        }
    }
    
    private func shareWorkout() {
        guard let workout = wgvm.workout else { return }
        
        let shareText = """
        Check out this workout I got from wodAI!
        
        \(workout.format.uppercased())
        
        \(workout.definition)
        
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
}

// MARK: - Tweak Option Button Component
struct TweakOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let isFullWidth: Bool
    let action: () -> Void
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isLoading: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: isFullWidth ? 12 : 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: color))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(isFullWidth ? .title2 : .title3)
                }
                
                if isFullWidth {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                } else {
                    VStack(spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primaryText)
                            .lineLimit(1)
                        
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isFullWidth ? 56 : 44)
            .padding(.horizontal, isFullWidth ? 16 : 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaledButtonStyle())
        .disabled(isLoading)
    }
}

#Preview {
    WorkoutView()
        .environmentObject(EnhancedWorkoutGeneratorViewModel(
            generating: false,
            workout: WorkoutFixture.workout
        ))
}

// MARK: - Enhanced Workout Definition View Component
struct EnhancedWorkoutDefinitionView: View {
    let workout: Workout
    let onShare: () -> Void
    let isUpdating: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Workout Details")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Show updating indicator or share button
                if isUpdating {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                        
                        Text("Updating...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    // Sharing button
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
            }
            
            // Main Content Area
            ZStack {
                // Normal workout content
                if !isUpdating {
                    workoutContent
                        .transition(.opacity)
                } else {
                    // Updating state overlay
                    updatingStateView
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isUpdating)
        }
        .padding(.horizontal, 4) // Minimal horizontal padding
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity) // Full width container
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Normal Workout Content
    private var workoutContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Format Title with enhanced styling
            HStack {
                Text(workout.format.uppercased())
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.brandPrimary)
                
                Spacer()
                
                // Workout type badge
                Text("AI Generated")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.purple)
                    )
            }
            
            // Definition Text with enhanced formatting and full width
            Text(workout.definition)
                .font(.body)
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.primaryText)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Optional stimulus and muscles info
            if !workout.stimulus.isEmpty || !workout.muscles.isEmpty {
                EnhancedWorkoutMetadata(workout: workout)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity) // Ensure full width usage
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
    
    // MARK: - Updating State View
    private var updatingStateView: some View {
        VStack(spacing: 24) {
            // Large updating indicator
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                
                Text("Updating Workout")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
            }
            
            // Dimmed workout preview
            VStack(alignment: .leading, spacing: 12) {
                // Format title (dimmed)
                HStack {
                    Text(workout.format.uppercased())
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.brandPrimary)
                        .opacity(0.4)
                    
                    Spacer()
                }
                
                // Definition text (dimmed and blurred)
                Text(workout.definition)
                    .font(.body)
                    .lineSpacing(10)
                    .foregroundColor(.primaryText)
                    .opacity(0.3)
                    .blur(radius: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200) // Ensure adequate height for the updating state
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
}

// MARK: - Enhanced Workout Metadata Component
struct EnhancedWorkoutMetadata: View {
    let workout: Workout
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
            
            if !workout.stimulus.isEmpty {
                HStack {
                    Label("Stimulus", systemImage: "bolt.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Spacer()
                }
                
                Text(workout.stimulus)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !workout.muscles.isEmpty {
                HStack {
                    Label("Target Muscles", systemImage: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Spacer()
                }
                
                Text(workout.muscles)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
