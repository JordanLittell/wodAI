//
//  StatChartView.swift
//  wodAI
//
//  One stat's Swift Chart, drawn from its shape — a running total across the
//  week for a series, with last week's dotted behind it, or horizontal bars
//  largest-first for categories — with its empty, loading and error states.
//  No card chrome: `StatsChartsSection` hosts it.
//

import SwiftUI
import Charts

struct StatChartView: View {
    let chart: StatChart?
    /// The same stat for the week before, overlaid on a series; nil hides it.
    let previous: StatChart?
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
            // A quiet week still shows last week's line, as the bar to beat.
            if chart.isEmpty, previous?.isEmpty ?? true {
                message(emptyMessage, systemImage: "chart.bar")
            } else {
                switch chart.points {
                case .series:
                    seriesChart(chart)
                case let .categorical(categories):
                    if chart.isEmpty {
                        message(emptyMessage, systemImage: "chart.bar")
                    } else {
                        categoryChart(categories, unit: chart.unit)
                    }
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

    /// The week's running total as a solid line, over last week's as a dotted
    /// one, both across the whole week so each weekday keeps its place. This
    /// week's line stops at today; the gap to last week's is the story.
    private func seriesChart(_ chart: StatChart) -> some View {
        let current = chart.runningTotal ?? []
        let previous = (previous?.runningTotal ?? []).shifted(byWeeks: 1, calendar: week.calendar)
        return VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(previous) { day in
                    LineMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value(chart.unit, day.value),
                        series: .value("Week", WeekLine.last.rawValue)
                    )
                    .foregroundStyle(WeekLine.last.color)
                    .lineStyle(WeekLine.last.stroke)
                }
                ForEach(current) { day in
                    LineMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value(chart.unit, day.value),
                        series: .value("Week", WeekLine.this.rawValue)
                    )
                    .foregroundStyle(WeekLine.this.color)
                    .lineStyle(WeekLine.this.stroke)
                }
                // Marks where this week stands now.
                if let latest = current.last {
                    PointMark(
                        x: .value("Day", latest.day, unit: .day),
                        y: .value(chart.unit, latest.value)
                    )
                    .foregroundStyle(WeekLine.this.color)
                    .symbolSize(40)
                }
            }
            .chartXScale(domain: week.start...week.end)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(current: chart, previous: self.previous))

            HStack(spacing: 16) {
                legendItem(.this, total: chart.total, unit: chart.unit)
                if self.previous != nil {
                    legendItem(.last, total: self.previous?.total, unit: chart.unit)
                }
            }
        }
    }

    private func legendItem(_ line: WeekLine, total: Double?, unit: String) -> some View {
        HStack(spacing: 6) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: 18, y: 1))
            }
            .stroke(line.color, style: line.stroke)
            .frame(width: 18, height: 2)
            Text(line.rawValue)
                .foregroundColor(Color("SecondaryText"))
            if let total {
                Text(StatFormatting.format(total, unit: unit))
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
            }
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }

    private func accessibilityLabel(current: StatChart, previous: StatChart?) -> String {
        let thisWeek = current.total.map { "This week \(StatFormatting.format($0, unit: current.unit))" }
        let lastWeek = previous?.total.map { "last week \(StatFormatting.format($0, unit: current.unit))" }
        return [thisWeek, lastWeek].compactMap { $0 }.joined(separator: ", ")
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

/// The two lines on a series chart.
private enum WeekLine: String {
    case this = "This week"
    case last = "Last week"

    var color: Color {
        switch self {
        case .this: return Color("BrandPrimary")
        case .last: return Color("SecondaryText")
        }
    }

    var stroke: StrokeStyle {
        switch self {
        case .this: return StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        case .last: return StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [2, 4])
        }
    }
}
