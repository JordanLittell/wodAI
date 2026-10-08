//
//  ActivityView.swift
//  wodAI
//

import SwiftUI

struct ActivityView: View {
    @State private var selectedWeek: ActivityWeek
    /// The chart the toggle shows; kept when the week changes.
    @State private var selectedStat: StatKind = .volume
    @StateObject private var stats: ActivityStatsStore
    @StateObject private var feed: ActivityFeedStore
    @StateObject private var recovery = RecoveryStatusStore()
    /// The card tapped to edit; drives the pushed completion screen.
    @State private var editing: EditTarget?
    /// An edit was saved, so the week's charts (volume, training load) are
    /// out of date; they reload when the editor closes.
    @State private var statsStale = false

    /// Passing `previewItems` or `previewStats` shows them without fetching.
    init(
        previewItems: [ActivityItem]? = nil,
        previewStats: ActivityStats? = nil,
        initialWeek: ActivityWeek = ActivityWeek(containing: Date())
    ) {
        self._selectedWeek = State(initialValue: initialWeek)
        let isPreview = previewItems != nil || previewStats != nil
        self._stats = StateObject(wrappedValue: isPreview ? ActivityStatsStore(preview: previewStats) : ActivityStatsStore())
        self._feed = StateObject(wrappedValue: isPreview ? ActivityFeedStore(preview: previewItems ?? []) : ActivityFeedStore())
    }

    /// The selected week's workouts under the day they were done, newest first.
    private var days: [ActivityDay] {
        ActivityFeed.days(feed.items.filter { selectedWeek.contains($0.completedAt) })
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

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
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        // Each runs on appear and again whenever the week changes, cancelling
        // the previous week's load.
        .task(id: selectedWeek) { await stats.load(week: selectedWeek) }
        .task(id: selectedWeek) { await feed.load(week: selectedWeek) }
        .task { await recovery.load() }
        .navigationDestination(item: $editing) { target in
            editor(for: target.item)
        }
        .onChange(of: editing) { _, editing in
            guard editing == nil, statsStale else { return }
            statsStale = false
            Task {
                await stats.load(week: selectedWeek, force: true)
                await recovery.load()
            }
        }
    }

    @ViewBuilder
    private func editor(for item: ActivityItem) -> some View {
        switch item {
        case let .hiit(entry):
            EditHiitCompletionView(entry: entry) { updated in
                feed.replace(.hiit(updated))
                statsStale = true
            }
        case let .strength(entry):
            if let workout = entry.workout {
                StrengthWorkoutView(workout: workout, onChange: { updated in
                    if let edited = entry.updated(with: updated) {
                        feed.replace(.strength(edited))
                    } else {
                        feed.remove(id: item.id)
                    }
                    statsStale = true
                })
            }
        }
    }

    private var chartsSection: some View {
        StatsChartsSection(
            kind: $selectedStat,
            stats: stats.stats,
            week: selectedWeek,
            isLoading: stats.isLoading,
            errorMessage: stats.errorMessage,
            onRetry: { Task { await stats.load(week: selectedWeek) } }
        )
    }

    private var workoutsSection: some View {
        let days = days
        let count = days.reduce(0) { $0 + $1.items.count }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Workouts")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                if !days.isEmpty {
                    Text("\(count) completed")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
            }

            if days.isEmpty {
                workoutsPlaceholder
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(days) { day in
                        ActivityDayDivider(day: day.day, count: day.items.count)
                        ForEach(day.items) { item in
                            Button {
                                editing = EditTarget(item: item)
                            } label: {
                                switch item {
                                case let .hiit(entry): CompletedHiitCard(entry: entry)
                                case let .strength(entry): CompletedStrengthCard(entry: entry)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Edit this result")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var workoutsPlaceholder: some View {
        Group {
            if feed.isLoading {
                ProgressView()
                    .tint(Color("BrandPrimary"))
            } else if let message = feed.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(Color("Warning"))
                    Text("Unable to load workouts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("PrimaryText"))
                    Text(message)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                    Button("Try Again") { Task { await feed.load(week: selectedWeek) } }
                        .foregroundColor(Color("BrandPrimary"))
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(Color("TertiaryText"))
                    Text("No workouts this week")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func changeWeek(by weeks: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedWeek = selectedWeek.shifted(by: weeks)
        }
    }
}

/// A tapped card, snapshotted so its editor keeps its workout even if the
/// card leaves the feed (a strength piece with every set un-checked).
private struct EditTarget: Hashable {
    let item: ActivityItem

    static func == (lhs: EditTarget, rhs: EditTarget) -> Bool { lhs.item.id == rhs.item.id }
    func hash(into hasher: inout Hasher) { hasher.combine(item.id) }
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
    let now = Date()
    let hr = (0..<60).map { i in
        HeartRatePoint(seconds: Double(i * 12), bpm: 110 + Int(55 * (1 - exp(-Double(i) / 12))) + (i % 5) * 2)
    }
    return NavigationStack {
        ActivityView(previewItems: [
            .hiit(CompletedHiitEntry(
                id: 1, completedAt: now.addingTimeInterval(-3600), workoutId: 101,
                format: "For Time", displayText: "21-15-9 For Time:\nThrusters (95/65 lb)\nPull-ups",
                stimulus: "Lactic Threshold", perceivedEffort: 9, avgHeartRate: 158, maxHeartRate: 181,
                trainingLoad: 64, heartRate: hr
            )),
            .strength(CompletedStrengthEntry(
                id: 7, completedAt: now.addingTimeInterval(-5400), title: "Back Squat",
                lifts: [.init(exercise: "Back Squat", prescribedReps: [5, 5, 5, 3, 3],
                              loggedWeights: [135, 155, 175, 185, 195])]
            )),
            .hiit(CompletedHiitEntry(
                id: 2, completedAt: now.addingTimeInterval(-86_400), workoutId: 102,
                format: "AMRAP 20", displayText: "AMRAP 20:\n5 Pull-ups\n10 Push-ups\n15 Air Squats",
                stimulus: "Aerobic Endurance", perceivedEffort: 5, trainingLoad: 50
            )),
            .strength(CompletedStrengthEntry(
                id: 8, completedAt: now.addingTimeInterval(-90_000), title: "Front Squat + Pendlay Row",
                lifts: [
                    .init(exercise: "Front Squat", prescribedReps: [5, 5, 5], loggedWeights: [155, 155, 165]),
                    .init(exercise: "Pull-up", prescribedReps: [8, 8, 8], loggedWeights: [nil, nil, nil]),
                ]
            )),
            .hiit(CompletedHiitEntry(
                id: 3, completedAt: now.addingTimeInterval(-2 * 86_400), workoutId: 103,
                format: "EMOM 12", displayText: "EMOM 12:\nMin 1: 15 Cal Row\nMin 2: 12 Burpees",
                stimulus: "Aerobic Capacity", perceivedEffort: 3
            )),
            .hiit(CompletedHiitEntry(
                id: 4, completedAt: now.addingTimeInterval(-2 * 86_400 - 600), workoutId: 104,
                displayText: "3 RFT:\n400 m Run\n21 KB Swings", stimulus: "Mixed Modal"
            )),
        ], previewStats: .preview)
    }
}

#Preview("Empty week") {
    NavigationStack {
        ActivityView(previewItems: [])
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
