//
//  WorkoutsView.swift
//  wodAI
//
//  A comprehensive view for browsing completed and favorite workouts
//

import SwiftUI
import WodAiAPI
import Apollo

struct WorkoutsView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var completedWorkouts: [CompletedWorkout] = []
    @State private var showingWorkoutDetail: CompletedWorkout?
    @State private var currentPage = 1
    @State private var hasMore = true
    @State private var error: Error?
    
    private let network = Network.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    
                    // Content
                    if isLoading && completedWorkouts.isEmpty {
                        LoadingView()
                    } else if let error = error, completedWorkouts.isEmpty {
                        ErrorStateView(error: error) {
                            loadWorkouts()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if filteredCompletedWorkouts.isEmpty {
                                    EmptyStateView(
                                        icon: "dumbbell",
                                        title: searchText.isEmpty ? "No Completed Workouts" : "No Results",
                                        message: searchText.isEmpty ? "Complete your first workout to see it here!" : "Try a different search term"
                                    )
                                    .padding(.top, 60)
                                } else {
                                    ForEach(filteredCompletedWorkouts) { workout in
                                        WorkoutCard(workout: workout) {
                                            showingWorkoutDetail = workout
                                        }
                                    }
                                    
                                    // Load more button
                                    if hasMore && searchText.isEmpty {
                                        Button(action: loadMoreWorkouts) {
                                            if isLoading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                    .frame(height: 50)
                                            } else {
                                                Text("Load More")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(Color("BrandPrimary"))
                                                    .frame(height: 50)
                                            }
                                        }
                                        .disabled(isLoading)
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
            workout.name.localizedCaseInsensitiveContains(searchText) ||
            workout.definition.localizedCaseInsensitiveContains(searchText) ||
            (workout.muscles?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    // MARK: - Data Loading
    private func loadWorkouts() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentPage = 1
        
        network.client.fetch(query: CompletedWodsQuery(page: GraphQLNullable(integerLiteral: currentPage))) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.completedWods {
                        self.completedWorkouts = data.wods.enumerated().map { index, wod in
                            CompletedWorkout(
                                id: "\(self.currentPage)-\(index)", // Generate a unique ID
                                name: wod.name,
                                definition: wod.definition,
                                muscles: wod.muscles.joined(separator: ", "),
                                completedAt: self.parseDate(wod.updatedAt) ?? Date()
                            )
                        }
                        self.hasMore = data.hasMore
                        self.currentPage = data.currentPage
                    }
                    
                    if let errors = graphQLResult.errors {
                        print("GraphQL errors: \(errors)")
                        self.error = NSError(
                            domain: "WorkoutsView",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to load workouts"]
                        )
                    }
                    
                case .failure(let error):
                    print("Network error loading workouts: \(error)")
                    self.error = error
                }
            }
        }
    }
    
    private func loadMoreWorkouts() {
        guard !isLoading && hasMore else { return }
        
        isLoading = true
        let nextPage = currentPage + 1
        
        network.client.fetch(query: CompletedWodsQuery(page: GraphQLNullable(integerLiteral: nextPage))) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.completedWods {
                        let newWorkouts = data.wods.enumerated().map { index, wod in
                            CompletedWorkout(
                                id: "\(nextPage)-\(index)",
                                name: wod.name,
                                definition: wod.definition,
                                muscles: wod.muscles.joined(separator: ", "),
                                completedAt: self.parseDate(wod.updatedAt) ?? Date()
                            )
                        }
                        self.completedWorkouts.append(contentsOf: newWorkouts)
                        self.hasMore = data.hasMore
                        self.currentPage = data.currentPage
                    }
                    
                case .failure(let error):
                    print("Error loading more workouts: \(error)")
                }
            }
        }
    }
    
    private func parseDate(_ dateTime: WodAiAPI.DateTime?) -> Date? {
        guard let dateTime = dateTime else { return nil }
        
        // DateTime is likely a typealias for String in the generated code
        let dateString = String(describing: dateTime)
        
        // Try multiple date formats
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("SecondaryText"))
            
            TextField("Search workouts...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(Color("PrimaryText"))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("SecondaryText"))
                }
            }
        }
        .padding(12)
        .background(Color("Surface"))
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
                        Text(workout.name)
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                            .lineLimit(1)
                        
                        Text(formatDate(workout.completedAt))
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    
                    Spacer()
                    
                    if let muscles = workout.muscles, !muscles.isEmpty {
                        Text(muscles)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color("BrandPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("BrandPrimary").opacity(0.1))
                            .cornerRadius(6)
                            .lineLimit(1)
                    }
                }
                
                // Definition Preview with gradient fade
                ZStack(alignment: .bottomTrailing) {
                    Text(workout.definition)
                        .font(.subheadline)
                        .foregroundColor(Color("PrimaryText"))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Gradient fade effect
                    if workout.definition.count > 100 {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("Surface").opacity(0),
                                Color("Surface").opacity(0.8),
                                Color("Surface")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 100)
                        .allowsHitTesting(false)
                        
                        Text("...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("SecondaryText"))
                            .padding(.trailing, 4)
                    }
                }
                
                // Footer
                HStack {
                    // Action hint
                    Text("Tap to view full workout")
                        .font(.caption)
                        .foregroundColor(Color("BrandPrimary"))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                }
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(Color("Warning"))
            
            VStack(spacing: 8) {
                Text("Unable to Load Workouts")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: retry) {
                Text("Try Again")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color("BrandPrimary"))
                    .cornerRadius(10)
            }
        }
        .padding(40)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(Color("SecondaryText"))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
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
                .tint(Color("BrandPrimary"))
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
                        // Name and Date
                        Text(workout.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        // Completion Info
                        HStack(spacing: 20) {
                            Label(formatDate(workout.completedAt), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(Color("SecondaryText"))
                            
                            if let muscles = workout.muscles, !muscles.isEmpty {
                                Label(muscles, systemImage: "figure.strengthtraining.traditional")
                                    .font(.subheadline)
                                    .foregroundColor(Color("SecondaryText"))
                            }
                        }
                        
                        Divider()
                        
                        // Definition
                        Text("Workout")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Text(workout.definition)
                            .font(.body)
                            .foregroundColor(Color("PrimaryText"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color("Surface"))
                    .cornerRadius(16)
                    
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
                                    colors: [Color("HeroStart"), Color("HeroEnd")],
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
                            .background(Color("Surface"))
                            .foregroundColor(Color("BrandPrimary"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("Border"), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
            }
        }
    }
    
    private func repeatWorkout() {
        // Set the workout in the generator
        workoutGenerator.workout = Workout(
            definition: workout.definition,
            stimulus: "",
            muscles: workout.muscles ?? "",
            format: workout.name,
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
        
        \(workout.name)
        
        \(workout.definition)
        
        Completed: \(formatDate(workout.completedAt))
        \(workout.muscles.map { "Muscles: \($0)" } ?? "")
        
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
}

// MARK: - Data Model
struct CompletedWorkout: Identifiable {
    let id: String
    let name: String
    let definition: String
    let muscles: String?
    let completedAt: Date
}

// MARK: - Preview
struct WorkoutsView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutsView()
            .environmentObject(EnhancedWorkoutGeneratorViewModel())
    }
}
