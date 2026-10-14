//
//  MuscleReadinessCard.swift
//  wodAI
//
//  Which body regions are still recovering, and when each will be ready to
//  train again (backend `muscleReadiness`). These are the same per-region
//  fatigue scores the planner programs from, so the athlete can see why a
//  session kept them off a region.
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

        var id: String { slug }

        /// Above this the planner leaves a region alone; between `readyBelow`
        /// and this it only works it lightly.
        static let restAbove = 60

        var isResting: Bool { fatigue > Self.restAbove }

        var color: Color { isResting ? .red : .orange }

        /// "Ready", "Ready by 6:00 PM", "Ready tomorrow", "Ready Thursday".
        func readyText(now: Date = Date(), calendar: Calendar = .current) -> String {
            guard let readyAt, readyAt > now else { return "Ready" }
            if calendar.isDate(readyAt, inSameDayAs: now) {
                return "Ready by \(readyAt.formatted(date: .omitted, time: .shortened))"
            }
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
               calendar.isDate(readyAt, inSameDayAs: tomorrow) {
                return "Ready tomorrow"
            }
            return "Ready \(readyAt.formatted(.dateTime.weekday(.wide)))"
        }
    }

    /// Under this a region trains normally (the backend's READY_FATIGUE).
    static let readyBelow = 30

    /// Every region the backend reported, most fatigued first.
    let regions: [Region]

    /// The regions not yet ready to train normally; the rest are left off the card.
    var recovering: [Region] { regions.filter { $0.fatigue >= Self.readyBelow } }
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
            MuscleReadiness.Region(slug: $0.slug, name: $0.name, fatigue: $0.fatigue, readyAt: parser.parseDate($0.readyAt))
        })
    }
}

struct MuscleReadinessCard: View {
    let readiness: MuscleReadiness?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Readiness")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryText"))

            if let readiness {
                let recovering = readiness.recovering
                if recovering.isEmpty {
                    Text("Everything's ready to train.")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                } else {
                    ForEach(recovering) { region in
                        row(region)
                    }
                    Text("Your plan works around these until they're ready. Everything else is ready to train.")
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
        .padding()
        .background(Color("Surface"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Border"), lineWidth: 1))
    }

    private func row(_ region: MuscleReadiness.Region) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(region.name)
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                Text(region.readyText())
                    .font(.caption)
                    .fontWeight(.semibold)
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
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(region.name), \(region.fatigue) percent fatigued, \(region.readyText())")
    }
}

#Preview {
    VStack {
        MuscleReadinessCard(readiness: MuscleReadiness(regions: [
            .init(slug: "quadriceps", name: "Quadriceps", fatigue: 72, readyAt: Date().addingTimeInterval(2 * 86_400)),
            .init(slug: "glutes", name: "Glutes", fatigue: 41, readyAt: Date().addingTimeInterval(20 * 3_600)),
            .init(slug: "core", name: "Core", fatigue: 12, readyAt: nil),
        ]))
        MuscleReadinessCard(readiness: MuscleReadiness(regions: []))
    }
    .padding()
}
