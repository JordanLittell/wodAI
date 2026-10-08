//
//  StatChartView.swift
//  wodAI
//
//  One stat's Swift Chart, drawn from its shape — daily bars across the whole
//  week for a series, horizontal bars largest-first for categories — with its
//  empty, loading and error states. No card chrome: `StatsChartsSection` hosts it.
//

import SwiftUI
import Charts

struct StatChartView: View {
    let chart: StatChart?
    let week: ActivityWeek
    /// Shown instead of a chart of zeros, e.g. "No strength sets logged".
    let emptyMessage: String
    let isLoading: Bool
    let errorMessage: String?
    let onRetry: () -> Void

    private static let chartHeight: CGFloat = 140

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        if let chart {
            if chart.isEmpty {
                message(emptyMessage, systemImage: "chart.bar")
            } else {
                switch chart.points {
                case let .series(days):
                    seriesChart(days, unit: chart.unit)
                case let .categorical(categories):
                    categoryChart(categories, unit: chart.unit)
                }
            }
        } else if let errorMessage, !isLoading {
            VStack(spacing: 8) {
                message(errorMessage, systemImage: "exclamationmark.triangle")
                Button("Try Again", action: onRetry)
                    .font(.subheadline)
                    .foregroundColor(Color("BrandPrimary"))
            }
            .frame(maxWidth: .infinity)
        } else {
            // Holds the chart's space while the week loads, so the layout
            // doesn't jump when it arrives.
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("Border").opacity(0.4))
                .frame(height: Self.chartHeight)
                .overlay(ProgressView())
        }
    }

    /// Daily bars across the whole week, so bars keep their place from week to
    /// week and this week's remaining days stay blank.
    private func seriesChart(_ days: [DayValue], unit: String) -> some View {
        Chart(days) { day in
            BarMark(
                x: .value("Day", day.day, unit: .day),
                y: .value(unit, day.value)
            )
            .foregroundStyle(Color("BrandPrimary"))
            .cornerRadius(4)
        }
        .chartXScale(domain: week.start...week.end)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: Self.chartHeight)
    }

    /// Horizontal bars, largest first, each labelled with its value.
    private func categoryChart(_ categories: [CategoryValue], unit: String) -> some View {
        let maxValue = categories.map(\.value).max() ?? 0
        return Chart(categories) { category in
            BarMark(
                x: .value(unit, category.value),
                y: .value("Category", category.label)
            )
            .foregroundStyle(Color("BrandPrimary"))
            .cornerRadius(4)
            .annotation(position: .trailing, alignment: .leading) {
                Text(StatFormatting.format(category.value, unit: unit))
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
            }
        }
        // Headroom past the longest bar for its label.
        .chartXScale(domain: 0...(maxValue * 1.2))
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
        .frame(height: CGFloat(categories.count) * 28 + 8)
    }

    private func message(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundColor(Color("TertiaryText"))
            Text(text)
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }
}
