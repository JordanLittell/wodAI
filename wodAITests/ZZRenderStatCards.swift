import Testing
import SwiftUI
@testable import wodAI

@MainActor
struct ZZRenderStatCards {
    @Test func render() throws {
        let week = ActivityWeek(containing: Date())
        let day = { (o: Int) in week.calendar.date(byAdding: .day, value: o, to: week.start)! }
        let days = (0..<7).map(day)
        let volume = StatChart(unit: "lb", total: 27_350, points: .series(zip(days, [12_400, 0, 14_950, 0, 0, 0, 0]).map { DayValue(day: $0, value: $1) }))
        let empty = StatChart(unit: "min", total: 0, points: .series(days.map { DayValue(day: $0, value: 0) }))
        let stats = ActivityStats(volume: volume, intensity: empty)
        let lastDays = days.map { week.calendar.date(byAdding: .weekOfYear, value: -1, to: $0)! }
        let lastWeek = ActivityStats(
            volume: StatChart(unit: "lb", total: 31_200, points: .series(zip(lastDays, [10_800, 0, 9_600, 0, 10_800, 0, 0]).map { DayValue(day: $0, value: $1) })),
            intensity: StatChart(unit: "min", total: 64, points: .series(zip(lastDays, [0, 20, 0, 24, 0, 20, 0]).map { DayValue(day: $0, value: $1) }))
        )
        let view = VStack(spacing: 12) {
            ForEach(StatKind.allCases) { kind in
                StatsChartsSection(kind: .constant(kind), stats: stats, previousStats: lastWeek, week: week, isLoading: false, errorMessage: nil, onRetry: {})
            }
            StatsChartsSection(kind: .constant(.volume), stats: nil, week: week, isLoading: true, errorMessage: nil, onRetry: {})
        }
        .padding()
        .frame(width: 393)
        .background(Color("Background"))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let data = try #require(renderer.uiImage?.pngData())
        try data.write(to: URL(fileURLWithPath: "/private/tmp/claude-501/-Users-jordanlittell-projects-wod-ai-workout-generator/693655e9-fe8e-43c4-acf3-8bf4e85429ed/scratchpad/stat-cards.png"))
    }
}
