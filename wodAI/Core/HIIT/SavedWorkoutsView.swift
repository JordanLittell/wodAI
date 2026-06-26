//
//  SavedWorkoutsView.swift
//  wodAI

import SwiftUI
import Apollo
import WodAiAPI

struct SavedWorkoutsView: View {
    @State private var savedWorkouts: [SavedHiitEntry] = []
    @State private var isLoading = false
    @State private var error: Error?

    private let network = Network.shared

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            if isLoading && savedWorkouts.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .tint(Color("BrandPrimary"))
            } else if let error = error, savedWorkouts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(Color("Warning"))
                    Text("Unable to load saved workouts")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                    Button("Try Again") { loadSaved() }
                        .foregroundColor(Color("BrandPrimary"))
                }
                .padding()
            } else if savedWorkouts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 56))
                        .foregroundColor(Color("TertiaryText"))
                    Text("No saved workouts yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    Text("Bookmark a workout and it will appear here")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(savedWorkouts) { entry in
                            NavigationLink(value: entry.toWorkoutItem()) {
                                SavedHiitCard(entry: entry)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: HIITWorkoutItem.self) { workout in
            HIITWorkoutView(preloaded: workout)
        }
        .onAppear { loadSaved() }
    }

    private func loadSaved() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        network.client.fetch(
            query: SavedHiitWorkoutsQuery(),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { result in
            Task { @MainActor in
                isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.savedHiitWorkouts {
                        savedWorkouts = data.map { item in
                            SavedHiitEntry(
                                id: item.id,
                                savedAt: DateParser().parseDate(item.savedAt) ?? Date(),
                                workoutId: item.workout.id,
                                format: item.workout.format,
                                displayText: item.workout.displayText,
                                stimulus: item.workout.stimulus,
                                constraintType: item.workout.constraintType,
                                constraintMagnitude: item.workout.constraintMagnitude
                            )
                        }
                        .sorted { $0.savedAt > $1.savedAt }
                    }
                    if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "SavedHiitWorkouts")
                        error = NSError(domain: "SavedWorkouts", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Failed to load saved workouts"])
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "SavedHiitWorkouts"])
                    error = networkError
                }
            }
        }
    }
}

struct SavedHiitEntry: Identifiable {
    let id: Int
    let savedAt: Date
    let workoutId: Int
    let format: String?
    let displayText: String
    let stimulus: String
    let constraintType: String
    let constraintMagnitude: Int
}

struct SavedHiitCard: View {
    let entry: SavedHiitEntry

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.savedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if let format = entry.format {
                        Text(format)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("BrandPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color("BrandPrimary").opacity(0.12))
                            .cornerRadius(6)
                    }
                    Text(entry.stimulus)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(Color("BrandPrimary"))
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(Color("SecondaryText"))
                }
            }

            Text(entry.displayText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color("PrimaryText"))
                .lineLimit(4)
                .truncationMode(.tail)
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }
}

extension SavedHiitEntry {
    func toWorkoutItem() -> HIITWorkoutItem {
        HIITWorkoutItem(
            id: workoutId,
            format: format,
            displayText: displayText,
            stimulus: stimulus,
            constraintType: constraintType,
            constraintMagnitude: constraintMagnitude,
            tags: []
        )
    }
}

#Preview("Saved list") {
    NavigationStack {
        SavedWorkoutsView()
    }
}
