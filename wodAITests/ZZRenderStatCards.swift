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
        let load = StatChart(unit: "%", total: nil, points: .categorical([
            CategoryValue(label: "Back", value: 24), CategoryValue(label: "Legs", value: 38),
            CategoryValue(label: "Shoulders", value: 17), CategoryValue(label: "Core", value: 12), CategoryValue(label: "Arms", value: 9)]))
        let empty = StatChart(unit: "min", total: 0, points: .series(days.map { DayValue(day: $0, value: 0) }))
        let view = VStack(spacing: 12) {
            StatChartCard(title: "Volume", chart: volume, week: week, emptyMessage: "No strength sets logged this week", isLoading: false, errorMessage: nil, onRetry: {})
            StatChartCard(title: "Intensity minutes", chart: empty, week: week, emptyMessage: "No WODs completed this week", isLoading: false, errorMessage: nil, onRetry: {})
            StatChartCard(title: "Muscle load", chart: load, week: week, emptyMessage: "No training this week", isLoading: false, errorMessage: nil, onRetry: {})
            StatChartCard(title: "Loading", chart: nil, week: week, emptyMessage: "", isLoading: true, errorMessage: nil, onRetry: {})
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
