//
//  StatsChartsSection.swift
//  wodAI
//
//  The Activity screen's charts in one card: a toggle picks the stat, which shows
//  its chart, against last week's where it has a running total, and what it
//  measures. Every stat arrives in one request, so switching is instant. The
//  Muscles toggle shows recovery right now instead of a weekly chart.
//

import SwiftUI

struct StatsChartsSection: View {
    @Binding var kind: StatKind
    let stats: ActivityStats?
    /// The week before `week`, for the series charts' overlay.
    var previousStats: ActivityStats? = nil
    /// Each region's recovery right now, shown at the top of the Muscles tab.
    var readiness: MuscleReadiness? = nil
    let week: ActivityWeek
    let isLoading: Bool
    let errorMessage: String?
    let onRetry: () -> Void

    var body: some View {
        let chart = kind.chart(in: stats)
        VStack(alignment: .leading, spacing: 14) {
            Picker("Chart", selection: $kind) {
                ForEach(StatKind.allCases) { kind in
                    Text(kind.toggleLabel).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            if kind == .recovery {
                // Right now, whatever week is selected; not a weekly chart.
                MuscleRecoverySection(readiness: readiness)
            } else {
                weeklyChart(chart)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: kind)
        .padding()
        .background(Color("Surface"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func weeklyChart(_ chart: StatChart?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(kind.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryText"))
            Spacer()
            if let chart, !chart.isEmpty, let headline = chart.headline() {
                Text(headline)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("BrandPrimary"))
                    .contentTransition(.numericText())
            }
        }

        StatChartView(
            chart: chart,
            previous: kind.chart(in: previousStats),
            week: week,
            emptyMessage: kind.emptyMessage,
            isLoading: isLoading,
            errorMessage: errorMessage,
            onRetry: onRetry
        )

        Text(kind.definition)
            .font(.subheadline)
            .foregroundColor(Color("SecondaryText"))
            .fixedSize(horizontal: false, vertical: true)

        // What this week's numbers rest on: measured, estimated, left out.
        if let provenance = chart?.provenance {
            Label(provenance, systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
