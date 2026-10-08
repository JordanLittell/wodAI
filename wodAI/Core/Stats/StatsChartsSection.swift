//
//  StatsChartsSection.swift
//  wodAI
//
//  The Stats screen's charts in one card: a toggle picks the stat, which shows
//  its chart, what it measures, and how to read it for progress, recovery and
//  injury risk. Every stat arrives in one request, so switching is instant.
//

import SwiftUI

struct StatsChartsSection: View {
    @Binding var kind: StatKind
    let stats: ActivityStats?
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

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("How to read it")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundColor(Color("SecondaryText"))
                ForEach(kind.pointers) { pointer in
                    PointerRow(pointer: pointer)
                }
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
}

private struct PointerRow: View {
    let pointer: StatPointer

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: pointer.topic.systemImage)
                .font(.subheadline)
                .foregroundColor(Color("BrandPrimary"))
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(pointer.topic.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                Text(pointer.text)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
