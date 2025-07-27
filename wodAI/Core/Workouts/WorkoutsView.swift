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
    @State private var completedWorkouts: [Workout] = []
    @State private var showingWorkoutDetail: Workout?
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
                                if completedWorkouts.isEmpty {
                                    EmptyStateView(
                                        icon: "dumbbell",
                                        title: "No Results",
                                        message: "Complete your first workout to see it here!"
                                    )
                                    .padding(.top, 60)
                                } else {
                                    ForEach(completedWorkouts) { workout in
                                        WorkoutInfoCard(workout: workout) {
                                            
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
                            return Workout(
                                id: wod.id,
                                name: wod.name,
                                description: wod.description,
                                components:  wod.components.map { component in
                                    Component(
                                        name: component.name,
                                        order: 1,
                                        definition: component.definition,
                                        description: "",
                                        targetFitnessDomains: [],
                                        energySystems: [])
                                },
                                completedAt: DateParser().parseDate(wod.completedAt),
                                completed: true)
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
                            return Workout(
                                id: wod.id,
                                name: wod.name,
                                description: wod.description,
                                components:  wod.components.map { component in
                                    Component(
                                        name: component.name,
                                        order: 1,
                                        definition: component.definition,
                                        description: "",
                                        targetFitnessDomains: [],
                                        energySystems: [])
                                },
                                completedAt: DateParser().parseDate(wod.completedAt),
                                completed: true)
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
                    .background(Color.error)
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
