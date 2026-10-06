//
//  HeartRateSummaryCard.swift
//  wodAI
//
//  The completion screen's heart-rate section: the curve, average and max,
//  time in each zone, and the training load the server worked out.
//

import SwiftUI

struct HeartRateSummaryCard: View {
    let state: CompletionHeartRate

    var body: some View {
        switch state {
        case .none:
            EmptyView()
        case .analyzing:
            card {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Analyzing your heart rate…")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
        case .unavailable:
            card {
                Label("No heart rate came through from your device during this workout.", systemImage: "heart.slash")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
        case let .ready(summary, points):
            card { ready(summary, points: points) }
        }
    }

    @ViewBuilder
    private func ready(_ summary: HeartRateSummary, points: [HeartRatePoint]) -> some View {
        HStack(spacing: 0) {
            stat("Avg", value: "\(Int(summary.avg.rounded()))", unit: "bpm")
            stat("Max", value: "\(Int(summary.max.rounded()))", unit: "bpm")
            stat("Load", value: "\(Int(summary.trainingLoad.rounded()))", unit: Self.loadDescriptor(summary.trainingLoad))
            if let calories = summary.estimatedCalories {
                stat("Calories", value: "\(Int(calories.rounded()))", unit: "kcal")
            }
        }

        if points.count > 1 {
            HeartRateSparkline(points: points)
                .frame(height: 120)
        }

        VStack(spacing: 6) {
            ForEach((1...5).reversed(), id: \.self) { zone in
                zoneRow(zone, seconds: summary.zoneSeconds.indices.contains(zone - 1) ? summary.zoneSeconds[zone - 1] : 0,
                        total: max(1, summary.zoneSeconds.reduce(0, +)))
            }
        }

        if summary.coverage < 0.5 {
            Label("Your device only sent heart rate for part of this workout, so its load will come from your effort rating.",
                  systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
        }
    }

    private func stat(_ title: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(Color("SecondaryText"))
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundColor(Color("PrimaryText"))
            Text(unit)
                .font(.caption2)
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
    }

    private func zoneRow(_ zone: Int, seconds: Int, total: Int) -> some View {
        HStack(spacing: 8) {
            Text("Z\(zone)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(HeartRateZoneStyle.color(for: zone))
                .frame(width: 24, alignment: .leading)
            Text(HeartRateZoneStyle.name(for: zone))
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
                .frame(width: 70, alignment: .leading)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(HeartRateZoneStyle.color(for: zone))
                    .frame(width: max(seconds > 0 ? 3 : 0, geo.size.width * CGFloat(seconds) / CGFloat(total)))
            }
            .frame(height: 8)
            Text(Self.duration(seconds))
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(Color("PrimaryText"))
                .frame(width: 44, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HEART RATE")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1)
                .foregroundColor(Color("SecondaryText"))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("Border"), lineWidth: 1))
    }

    /// Edwards TRIMP in plain words. A hard 20-minute metcon lands around 80.
    static func loadDescriptor(_ load: Double) -> String {
        switch load {
        case ..<25: return "light"
        case ..<50: return "moderate"
        case ..<90: return "hard"
        default: return "very hard"
        }
    }

    static func duration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview("Ready") {
    let points = (0..<600).map { HeartRatePoint(seconds: Double($0), bpm: 90 + Int(70 * (1 - exp(-Double($0) / 90)))) }
    return HeartRateSummaryCard(state: .ready(
        HeartRateSummary(avg: 148, max: 171, min: 88, coverage: 0.97, zoneSeconds: [40, 60, 120, 300, 80],
                         trainingLoad: 41.3, estimatedCalories: 142),
        points
    ))
    .padding()
}

#Preview("Analyzing") {
    HeartRateSummaryCard(state: .analyzing).padding()
}
