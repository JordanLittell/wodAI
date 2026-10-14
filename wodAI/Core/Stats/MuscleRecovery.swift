//
//  MuscleRecovery.swift
//  wodAI
//
//  How recovered each body region is right now, when it's ready to train again
//  and when it's fully recovered (backend `muscleReadiness`). These are the same
//  per-region fatigue scores the planner programs from, so the athlete can see
//  why a session kept them off a region. Shown at the top of the Muscles tab.
//

import SwiftUI
import Apollo
import WodAiAPI

struct MuscleReadiness: Equatable {
    struct Region: Identifiable, Equatable {
        let slug: String
        let name: String
        /// 0-100, 0 fully recovered.
        let fatigue: Int
        /// When fatigue drops under `MuscleReadiness.readyBelow`; nil when it already has.
        let readyAt: Date?
        /// When fatigue reaches zero.
        let recoveredAt: Date

        var id: String { slug }

        /// Above this the planner leaves a region alone; between `readyBelow`
        /// and this it only works it lightly.
        static let restAbove = 60

        var isResting: Bool { fatigue > Self.restAbove }
        var isReady: Bool { fatigue < MuscleReadiness.readyBelow }

        var color: Color {
            if isReady { return .green }
            return isResting ? .red : .orange
        }

        /// "Ready to train", "Ready to train by 6:00 PM", "… tomorrow", "… Thursday".
        func readyText(now: Date = Date(), calendar: Calendar = .current) -> String {
            guard !isReady, let readyAt, readyAt > now else { return "Ready to train" }
            return "Ready to train \(Self.when(readyAt, now: now, calendar: calendar))"
        }

        /// "Fully recovered by 6:00 PM", "… tomorrow", "… Saturday".
        func recoveredText(now: Date = Date(), calendar: Calendar = .current) -> String {
            guard recoveredAt > now else { return "Fully recovered" }
            return "Fully recovered \(Self.when(recoveredAt, now: now, calendar: calendar))"
        }

        private static func when(_ date: Date, now: Date, calendar: Calendar) -> String {
            if calendar.isDate(date, inSameDayAs: now) {
                return "by \(date.formatted(date: .omitted, time: .shortened))"
            }
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
               calendar.isDate(date, inSameDayAs: tomorrow) {
                return "tomorrow"
            }
            return date.formatted(.dateTime.weekday(.wide))
        }
    }

    /// Under this a region trains normally (the backend's READY_FATIGUE).
    static let readyBelow = 30

    /// Every region still fatigued, most fatigued first; any region not here is
    /// fully recovered.
    let regions: [Region]

    init(regions: [Region]) {
        self.regions = regions.sorted { $0.fatigue > $1.fatigue || ($0.fatigue == $1.fatigue && $0.name < $1.name) }
    }
}

@MainActor
final class MuscleReadinessStore: ObservableObject {
    @Published private(set) var readiness: MuscleReadiness?
    @Published private(set) var isLoading = false

    private let client: ApolloClient?

    init(client: ApolloClient = Network.shared.client) {
        self.client = client
    }

    /// For previews: shows `readiness` and never touches the network.
    init(preview readiness: MuscleReadiness?) {
        self.client = nil
        self.readiness = readiness
    }

    func load() async {
        guard let client, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let data: MuscleReadinessQuery.Data? = await withCheckedContinuation { continuation in
            client.fetch(query: MuscleReadinessQuery(), cachePolicy: .fetchIgnoringCacheCompletely) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "MuscleReadiness")
                    }
                    continuation.resume(returning: graphQLResult.data)
                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": "MuscleReadiness"])
                    continuation.resume(returning: nil)
                }
            }
        }
        guard let regions = data?.muscleReadiness else { return }
        let parser = DateParser()
        readiness = MuscleReadiness(regions: regions.map {
            MuscleReadiness.Region(
                slug: $0.slug,
                name: $0.name,
                fatigue: $0.fatigue,
                readyAt: parser.parseDate($0.readyAt),
                recoveredAt: parser.parseDate($0.recoveredAt) ?? Date()
            )
        })
    }
}

/// The top of the Muscles tab: one row per region still recovering. Always
/// "right now", whichever week the screen shows.
struct MuscleRecoverySection: View {
    let readiness: MuscleReadiness?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recovery right now")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                ExplainerButton(explainer: .readiness)
            }

            if let readiness {
                if readiness.regions.isEmpty {
                    Text("Every region is fully recovered.")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                } else {
                    ForEach(readiness.regions) { region in
                        row(region)
                    }
                    Text("Any region not listed is fully recovered. Your plan leaves red regions alone and works orange ones lightly.")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("Border").opacity(0.4))
                    .frame(height: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ region: MuscleReadiness.Region) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(region.name)
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                Text("\(region.fatigue)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundColor(region.color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color("Border").opacity(0.5))
                    Capsule().fill(region.color)
                        .frame(width: geo.size.width * CGFloat(min(max(region.fatigue, 0), 100)) / 100)
                }
            }
            .frame(height: 6)
            HStack {
                Text(region.readyText())
                    .foregroundColor(region.isReady ? Color("SecondaryText") : region.color)
                Spacer()
                Text(region.recoveredText())
                    .foregroundColor(Color("SecondaryText"))
            }
            .font(.caption)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(region.name), \(region.fatigue) percent fatigued. \(region.readyText()). \(region.recoveredText()).")
    }
}

#Preview {
    MuscleRecoverySection(readiness: MuscleReadiness(regions: [
        .init(slug: "quadriceps", name: "Quadriceps", fatigue: 72, readyAt: Date().addingTimeInterval(2 * 86_400), recoveredAt: Date().addingTimeInterval(3 * 86_400)),
        .init(slug: "glutes", name: "Glutes", fatigue: 41, readyAt: Date().addingTimeInterval(20 * 3_600), recoveredAt: Date().addingTimeInterval(2 * 86_400)),
        .init(slug: "core", name: "Core", fatigue: 12, readyAt: nil, recoveredAt: Date().addingTimeInterval(10 * 3_600)),
    ]))
    .padding()
}
