//
//  ActivityView.swift
//  wodAI
//

import SwiftUI
import Apollo
import WodAiAPI

struct ActivityView: View {
    @State private var completedWorkouts: [CompletedHiitEntry]
    @State private var isLoading = false
    @State private var error: Error?

    private let network = Network.shared

    init(previewEntries: [CompletedHiitEntry]? = nil) {
        self._completedWorkouts = State(initialValue: previewEntries ?? [])
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            if isLoading && completedWorkouts.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .tint(Color("BrandPrimary"))
            } else if let error = error, completedWorkouts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(Color("Warning"))
                    Text("Unable to load activity")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                    Button("Try Again") { loadActivity() }
                        .foregroundColor(Color("BrandPrimary"))
                }
                .padding()
            } else if completedWorkouts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 56))
                        .foregroundColor(Color("TertiaryText"))
                    Text("No completed workouts yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    Text("Complete a workout and it will appear here")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(completedWorkouts) { entry in
                            CompletedHiitCard(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadActivity() }
    }

    private func loadActivity() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        network.client.fetch(
            query: CompletedHiitWorkoutsQuery(),
            cachePolicy: .fetchIgnoringCacheCompletely
        ) { result in
            Task { @MainActor in
                isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.completedHiitWorkouts {
                        completedWorkouts = data.map { item in
                            CompletedHiitEntry(
                                id: item.id,
                                completedAt: DateParser().parseDate(item.completedAt) ?? Date(),
                                workoutId: item.workout.id,
                                displayText: item.workout.displayText,
                                stimulus: item.workout.stimulus,
                                constraintType: item.workout.constraintType,
                                constraintMagnitude: item.workout.constraintMagnitude
                            )
                        }
                        .sorted { $0.completedAt > $1.completedAt }
                    }
                    if let errors = graphQLResult.errors {
                        let messages = errors.compactMap { $0.message }.joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "CompletedHiitWorkouts")
                        error = NSError(domain: "Activity", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Failed to load activity"])
                    }
                case .failure(let networkError):
                    TelemetryService.captureError(networkError, tags: ["operation": "CompletedHiitWorkouts"])
                    error = networkError
                }
            }
        }
    }
}

struct CompletedHiitEntry: Identifiable {
    let id: Int
    let completedAt: Date
    let workoutId: Int
    let displayText: String
    let stimulus: String
    let constraintType: String
    let constraintMagnitude: Int
}

struct CompletedHiitCard: View {
    let entry: CompletedHiitEntry

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.completedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(constraintLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("BrandPrimary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("BrandPrimary").opacity(0.12))
                        .cornerRadius(6)

                    Text(entry.stimulus)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("Success"))
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

    private var constraintLabel: String {
        "\(entry.constraintMagnitude) \(entry.constraintType)"
    }
}

#Preview("Activity list") {
    NavigationStack {
        ActivityView(previewEntries: [
            CompletedHiitEntry(
                id: 1,
                completedAt: Date().addingTimeInterval(-3600),
                workoutId: 101,
                displayText: "21-15-9:\nThrusters (95/65 lb)\nPull-ups",
                stimulus: "Lactic Threshold",
                constraintType: "reps",
                constraintMagnitude: 45
            ),
            CompletedHiitEntry(
                id: 2,
                completedAt: Date().addingTimeInterval(-86400),
                workoutId: 102,
                displayText: "3 Rounds:\n400m Run\n21 Kettlebell Swings (53/35 lb)\n12 Pull-ups",
                stimulus: "Aerobic Endurance",
                constraintType: "rounds",
                constraintMagnitude: 3
            ),
            CompletedHiitEntry(
                id: 3,
                completedAt: Date().addingTimeInterval(-172800),
                workoutId: 103,
                displayText: "AMRAP 20:\n5 Pull-ups\n10 Push-ups\n15 Air Squats",
                stimulus: "Aerobic Capacity",
                constraintType: "minutes",
                constraintMagnitude: 20
            )
        ])
    }
}

#Preview("Empty state") {
    NavigationStack {
        ActivityView(previewEntries: [])
    }
}
