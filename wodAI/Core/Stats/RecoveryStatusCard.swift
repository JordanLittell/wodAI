//
//  RecoveryStatusCard.swift
//  wodAI
//
//  How recovered the athlete is right now: the last 7 days' training load
//  against the last 28 (backend `recoveryStatus`). Load comes from heart rate
//  when a device recorded the workout, else from perceived effort.
//

import SwiftUI
import Apollo
import WodAiAPI

struct RecoveryStatus: Equatable {
    enum Level: Equatable {
        case insufficientData, fresh, optimal, elevated, highStrain
    }

    let level: Level
    /// 7-day load over 28-day load; nil without enough history.
    let ratio: Double?
    let lastHardSessionAt: Date?

    var title: String {
        switch level {
        case .insufficientData: return "Building your baseline"
        case .fresh: return "Fresh"
        case .optimal: return "On track"
        case .elevated: return "Elevated"
        case .highStrain: return "High strain"
        }
    }

    var message: String {
        switch level {
        case .insufficientData:
            return "Rate your effort after each workout (or wear a heart rate monitor) for about two weeks to see how recovered you are."
        case .fresh:
            return "This week has been lighter than you're used to. A good day to push."
        case .optimal:
            return "Your recent training is in line with what you're used to."
        case .elevated:
            return "You've trained harder than usual this week. Keep an eye on sleep and soreness."
        case .highStrain:
            return "This week is much harder than you're used to. Consider an easier session or a rest day."
        }
    }

    var color: Color {
        switch level {
        case .insufficientData: return Color("SecondaryText")
        case .fresh: return .green
        case .optimal: return .blue
        case .elevated: return .orange
        case .highStrain: return .red
        }
    }
}

@MainActor
final class RecoveryStatusStore: ObservableObject {
    @Published private(set) var status: RecoveryStatus?
    @Published private(set) var isLoading = false

    private let client: ApolloClient?

    init(client: ApolloClient = Network.shared.client) {
        self.client = client
    }

    /// For previews: shows `status` and never touches the network.
    init(preview status: RecoveryStatus?) {
        self.client = nil
        self.status = status
    }

    func load() async {
        guard let client, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let query = RecoveryStatusQuery(timezone: .some(TimeZone.current.identifier))
        let data: RecoveryStatusQuery.Data? = await withCheckedContinuation { continuation in
            client.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                switch result {
                case let .success(graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let messages = errors.compactMap(\.message).joined(separator: "; ")
                        TelemetryService.captureGraphQLErrors(messages: messages, operation: "RecoveryStatus")
                    }
                    continuation.resume(returning: graphQLResult.data)
                case let .failure(error):
                    TelemetryService.captureError(error, tags: ["operation": "RecoveryStatus"])
                    continuation.resume(returning: nil)
                }
            }
        }
        guard let result = data?.recoveryStatus else { return }
        status = RecoveryStatus(
            level: Self.level(result.status),
            ratio: result.ratio,
            lastHardSessionAt: result.lastHardSessionAt.flatMap { DateParser().parseDate($0) }
        )
    }

    private static func level(_ value: GraphQLEnum<RecoveryLevel>) -> RecoveryStatus.Level {
        switch value.value {
        case .fresh: return .fresh
        case .optimal: return .optimal
        case .elevated: return .elevated
        case .highStrain: return .highStrain
        case .insufficientData, .none: return .insufficientData
        }
    }
}

struct RecoveryStatusCard: View {
    let status: RecoveryStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recovery")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                if let status {
                    Text(status.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(status.color)
                }
            }

            if let status {
                if let ratio = status.ratio {
                    gauge(ratio, color: status.color)
                }
                Text(status.message)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
                if let last = status.lastHardSessionAt {
                    Text("Last hard session \(last.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("Border").opacity(0.4))
                    .frame(height: 44)
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Border"), lineWidth: 1))
    }

    /// The 7:28-day ratio on a 0.5–2.0 track, with the "on track" band
    /// (0.8–1.3) marked.
    private func gauge(_ ratio: Double, color: Color) -> some View {
        GeometryReader { geo in
            let lower = 0.5, upper = 2.0
            let x = { (value: Double) in geo.size.width * CGFloat((min(max(value, lower), upper) - lower) / (upper - lower)) }
            ZStack(alignment: .leading) {
                Capsule().fill(Color("Border").opacity(0.5)).frame(height: 6)
                Capsule().fill(Color.blue.opacity(0.25))
                    .frame(width: x(1.3) - x(0.8), height: 6)
                    .offset(x: x(0.8))
                Circle().fill(color).frame(width: 14, height: 14)
                    .offset(x: x(ratio) - 7)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 14)
        .accessibilityLabel("Recent load is \(Int((ratio * 100).rounded())) percent of usual")
    }
}

#Preview {
    VStack {
        RecoveryStatusCard(status: RecoveryStatus(level: .elevated, ratio: 1.42, lastHardSessionAt: Date().addingTimeInterval(-86_400)))
        RecoveryStatusCard(status: RecoveryStatus(level: .insufficientData, ratio: nil, lastHardSessionAt: nil))
    }
    .padding()
}
