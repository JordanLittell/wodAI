//
//  WorkoutsView.swift
//  wodAI
//
//  A comprehensive view for browsing completed and favorite workouts
//

import SwiftUI
import WodAiAPI

struct WorkoutsView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var completedWorkouts: [CompletedWorkout] = []
    @State private var showingWorkoutDetail: CompletedWorkout?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    
                    // Content
                    if isLoading {
                        LoadingView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if filteredCompletedWorkouts.isEmpty {
                                    EmptyStateView(
                                        icon: "dumbbell",
                                        title: "No Completed Workouts",
                                        message: "Complete your first workout to see it here!"
                                    )
                                    .padding(.top, 60)
                                } else {
                                    ForEach(filteredCompletedWorkouts) { workout in
                                        WorkoutCard(workout: workout) {
                                            showingWorkoutDetail = workout
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadWorkouts()
            }
            .sheet(item: $showingWorkoutDetail) { workout in
                WorkoutDetailView(workout: workout)
                    .environmentObject(workoutGenerator)
            }
        }
    }
    
    // MARK: - Filtered Lists
    private var filteredCompletedWorkouts: [CompletedWorkout] {
        if searchText.isEmpty {
            return completedWorkouts
        }
        return completedWorkouts.filter { workout in
            workout.format.localizedCaseInsensitiveContains(searchText) ||
            workout.definition.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Data Loading
    private func loadWorkouts() {
        isLoading = true
        
        // Simulate loading with mock data for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Mock completed workouts
            completedWorkouts = [
                CompletedWorkout(
                    id: "1",
                    format: "AMRAP 20",
                    definition: "20 min AMRAP:\n10 Push-ups\n15 Air Squats\n20 Sit-ups",
                    completedAt: Date().addingTimeInterval(-86400), // Yesterday
                    duration: 1200
                ),
                CompletedWorkout(
                    id: "2",
                    format: "For Time",
                    definition: "21-15-9:\nThrusters (95/65)\nPull-ups",
                    completedAt: Date().addingTimeInterval(-172800), // 2 days ago
                    duration: 480
                ),
                CompletedWorkout(
                    id: "3",
                    format: "EMOM 15",
                    definition: "Every minute for 15 minutes:\n5 Burpees\n10 Kettlebell Swings\nMax Double Unders",
                    completedAt: Date().addingTimeInterval(-259200), // 3 days ago
                    duration: 900
                )
            ]
            
            isLoading = false
        }
        
        // TODO: Replace with actual API call
        // fetchCompletedWorkouts()
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryText)
            
            TextField("Search workouts...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.primaryText)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(12)
        .background(Color(.surface))
        .cornerRadius(12)
    }
}

// MARK: - Workout Card
struct WorkoutCard: View {
    let workout: CompletedWorkout
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.format)
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        Text(formatDate(workout.completedAt))
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                }
                
                // Definition Preview
                Text(workout.definition)
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Footer
                HStack {
                    // Duration
                    Label(formatDuration(workout.duration), systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    // Repeat indicator
                    if workout.repeatCount > 1 {
                        Label("\(workout.repeatCount)x", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                    }
                    
                    // Action hint
                    Text("Tap to view")
                        .font(.caption)
                        .foregroundColor(.brandPrimary)
                }
            }
            .padding()
            .background(Color(.surface))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if remainingSeconds == 0 {
            return "\(minutes)m"
        }
        return "\(minutes)m \(remainingSeconds)s"
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Spacer()
        }
    }
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: CompletedWorkout
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingRepeatOptions = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Workout Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Format and Date
                        Text(workout.format)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                        
                        // Completion Info
                        HStack(spacing: 20) {
                            Label(formatDate(workout.completedAt), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                            
                            Label(formatDuration(workout.duration), systemImage: "timer")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                        }
                        
                        Divider()
                        
                        // Definition
                        Text("Workout")
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        Text(workout.definition)
                            .font(.body)
                            .foregroundColor(.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.surface))
                    .cornerRadius(16)
                    
                    // Statistics Card (if available)
                    if workout.repeatCount > 1 {
                        StatisticsCard(workout: workout)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: repeatWorkout) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Repeat This Workout")
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
                        
                        Button(action: shareWorkout) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Workout")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.surface))
                            .foregroundColor(.brandPrimary)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.background))
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func repeatWorkout() {
        // Set the workout in the generator
        workoutGenerator.workout = Workout(
            definition: workout.definition,
            stimulus: "",
            muscles: "",
            format: workout.format,
            id: workout.id
        )
        
        // Dismiss and navigate to home
        dismiss()
        
        // Post notification to switch to home tab
        NotificationCenter.default.post(
            name: .navigateToTab,
            object: AppTab.home
        )
    }
    
    private func shareWorkout() {
        let shareText = """
        Check out this workout from wodAI!
        
        \(workout.format)
        
        \(workout.definition)
        
        Completed: \(formatDate(workout.completedAt))
        Duration: \(formatDuration(workout.duration))
        
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Statistics Card
struct StatisticsCard: View {
    let workout: CompletedWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Times Completed",
                    value: "\(workout.repeatCount)",
                    icon: "arrow.clockwise"
                )
                
                StatItem(
                    title: "Avg Duration",
                    value: formatDuration(workout.averageDuration ?? workout.duration),
                    icon: "timer"
                )
                
                if let bestTime = workout.bestTime {
                    StatItem(
                        title: "Best Time",
                        value: formatDuration(bestTime),
                        icon: "trophy"
                    )
                }
            }
        }
        .padding()
        .background(Color(.surface))
        .cornerRadius(16)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandPrimary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data Model
struct CompletedWorkout: Identifiable {
    let id: String
    let format: String
    let definition: String
    let completedAt: Date
    let duration: Int // in seconds
    var repeatCount: Int = 1
    var averageDuration: Int?
    var bestTime: Int?
}

// MARK: - Preview
struct WorkoutsView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutsView()
            .environmentObject(EnhancedWorkoutGeneratorViewModel())
    }
}
