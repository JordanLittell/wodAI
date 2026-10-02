//
//  ActivityView.swift
//  wodAI
//

import SwiftUI
import Apollo
import WodAiAPI

struct ActivityView: View {
    @State private var allWorkouts: [CompletedHiitEntry]
    @State private var selectedWeek: ActivityWeek
    @State private var isLoading = false
    @State private var error: Error?
    @StateObject private var stats: ActivityStatsStore
    @StateObject private var recovery = RecoveryStatusStore()

    private let network = Network.shared

    /// Passing `previewStats` makes the charts show it without fetching.
    init(
        previewEntries: [CompletedHiitEntry]? = nil,
        previewStats: ActivityStats? = nil,
        initialWeek: ActivityWeek = ActivityWeek(containing: Date())
    ) {
        self._allWorkouts = State(initialValue: previewEntries ?? [])
        self._selectedWeek = State(initialValue: initialWeek)
        let store = previewEntries != nil || previewStats != nil
            ? ActivityStatsStore(preview: previewStats)
            : ActivityStatsStore()
        self._stats = StateObject(wrappedValue: store)
    }

    /// Completed workouts in the selected week, newest first (`allWorkouts` is already sorted).
    private var weekWorkouts: [CompletedHiitEntry] {
        allWorkouts.filter { selectedWeek.contains($0.completedAt) }
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            if isLoading && allWorkouts.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .tint(Color("BrandPrimary"))
            } else if let error = error, allWorkouts.isEmpty {
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
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        RecoveryStatusCard(status: recovery.status)

                        WeekSelectorBar(
                            week: selectedWeek,
                            canGoForward: !selectedWeek.isCurrentOrFuture(relativeTo: Date()),
                            onPrevious: { changeWeek(by: -1) },
                            onNext: { changeWeek(by: 1) }
                        )

                        chartsSection

                        workoutsSection
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadActivity() }
        // Runs on appear and again whenever the week changes, cancelling the
        // previous week's load.
        .task(id: selectedWeek) { await stats.load(week: selectedWeek) }
        .task { await recovery.load() }
    }

    private var chartsSection: some View {
        VStack(spacing: 12) {
            statCard("Volume", chart: stats.stats?.volume, empty: "No strength sets logged this week")
            statCard("Intensity minutes", chart: stats.stats?.intensity, empty: "No WODs completed this week")
            statCard("Training load", chart: stats.stats?.trainingLoad, empty: "Rate your effort or wear a heart rate monitor to see training load")
            statCard("Muscle load", chart: stats.stats?.muscleLoad, empty: "No training this week")
        }
    }

    private func statCard(_ title: String, chart: StatChart?, empty: String) -> some View {
        StatChartCard(
            title: title,
            chart: chart,
            week: selectedWeek,
            emptyMessage: empty,
            isLoading: stats.isLoading,
            errorMessage: stats.errorMessage,
            onRetry: { Task { await stats.load(week: selectedWeek) } }
        )
    }

    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Workouts")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                Text("\(weekWorkouts.count) completed")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }

            if weekWorkouts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(Color("TertiaryText"))
                    Text("No workouts this week")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(weekWorkouts) { entry in
                        CompletedHiitCard(entry: entry)
                    }
                }
            }
        }
    }

    private func changeWeek(by weeks: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedWeek = selectedWeek.shifted(by: weeks)
        }
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
                        allWorkouts = data.map { item in
                            CompletedHiitEntry(
                                id: item.id,
                                completedAt: DateParser().parseDate(item.completedAt) ?? Date(),
                                workoutId: item.workout.id,
                                displayText: item.workout.displayText,
                                stimulus: item.workout.stimulus,
                                constraintType: item.workout.constraintType,
                                constraintMagnitude: item.workout.constraintMagnitude,
                                avgHeartRate: item.heartRate.map { Int($0.avg.rounded()) },
                                trainingLoad: item.trainingLoad
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
    var avgHeartRate: Int? = nil
    var trainingLoad: Double? = nil
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

            if entry.avgHeartRate != nil || entry.trainingLoad != nil {
                HStack(spacing: 14) {
                    if let bpm = entry.avgHeartRate {
                        Label("\(bpm) avg bpm", systemImage: "heart.fill")
                    }
                    if let load = entry.trainingLoad {
                        Label("Load \(Int(load.rounded()))", systemImage: "flame.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
            }
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

private struct WeekSelectorBar: View {
    let week: ActivityWeek
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous week")

            Spacer()

            Text(week.label())
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
                .contentTransition(.numericText())

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward)
            .opacity(canGoForward ? 1 : 0.3)
            .accessibilityLabel("Next week")
        }
        .foregroundColor(Color("BrandPrimary"))
        .padding(.horizontal, 4)
        .background(Color("Surface"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("Border"), lineWidth: 1)
        )
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
                completedAt: Date().addingTimeInterval(-8 * 86400),
                workoutId: 103,
                displayText: "AMRAP 20:\n5 Pull-ups\n10 Push-ups\n15 Air Squats",
                stimulus: "Aerobic Capacity",
                constraintType: "minutes",
                constraintMagnitude: 20
            )
        ], previewStats: .preview)
    }
}

#Preview("Empty week") {
    NavigationStack {
        ActivityView(previewEntries: [])
    }
}

private extension ActivityStats {
    /// A plausible week for previews: Monday through Wednesday trained.
    static var preview: ActivityStats {
        let week = ActivityWeek(containing: Date())
        let day = { (offset: Int) in week.calendar.date(byAdding: .day, value: offset, to: week.start)! }
        let days = (0..<7).map(day)
        return ActivityStats(
            muscleLoad: StatChart(unit: "%", total: nil, points: .categorical([
                CategoryValue(label: "Legs", value: 38),
                CategoryValue(label: "Back", value: 24),
                CategoryValue(label: "Shoulders", value: 17),
                CategoryValue(label: "Core", value: 12),
                CategoryValue(label: "Arms", value: 9),
            ])),
            volume: StatChart(unit: "lb", total: 27_350, points: .series(
                zip(days, [12_400, 0, 14_950, 0, 0, 0, 0]).map { DayValue(day: $0, value: $1) }
            )),
            intensity: StatChart(unit: "min", total: 46, points: .series(
                zip(days, [0, 22, 24, 0, 0, 0, 0]).map { DayValue(day: $0, value: $1) }
            ))
        )
    }
}
