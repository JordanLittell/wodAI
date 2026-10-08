//
//  HeartRateViews.swift
//  wodAI
//
//  Small heart-rate pieces shared across screens: the pre-start chip on a
//  metcon, the live readout on the timer, zone colors, and the heart-rate
//  curve drawn on the completion screen and the Stats feed.
//

import SwiftUI
import Charts

/// A session's heart rate over time as a smooth red line. `showsAxes` false
/// gives a bare sparkline for small cards. With `zoneThresholds`, dashed lines
/// mark where the zones around the curve start. Press and hold, then drag, to
/// read the time and bpm at any point (`interactive`).
struct HeartRateSparkline: View {
    let points: [HeartRatePoint]
    /// bpm where zones 1–5 start; empty draws no zone lines.
    var zoneThresholds: [Int] = []
    var showsAxes = true
    var interactive = true

    @State private var selected: HeartRatePoint?

    var body: some View {
        let scale = HeartRateChartScale(points: points, zoneThresholds: zoneThresholds)
        Chart {
            ForEach(scale.zoneLines, id: \.zone) { line in
                RuleMark(y: .value("Zone start", line.bpm))
                    .foregroundStyle(HeartRateZoneStyle.color(for: line.zone).opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }

            ForEach(points) { point in
                LineMark(
                    x: .value("Minutes", point.seconds / 60),
                    y: .value("bpm", point.bpm)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.red)
            }

            if let selected {
                RuleMark(x: .value("Minutes", selected.seconds / 60))
                    .foregroundStyle(Color("SecondaryText").opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(
                        position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        HeartRateReadout(point: selected, zoneThresholds: zoneThresholds)
                    }
                PointMark(
                    x: .value("Minutes", selected.seconds / 60),
                    y: .value("bpm", selected.bpm)
                )
                .foregroundStyle(.red)
                .symbolSize(36)
            }
        }
        .chartYScale(domain: scale.domain)
        .chartXAxis(showsAxes ? .automatic : .hidden)
        .chartYAxis {
            if !scale.zoneLines.isEmpty {
                // Zone names beside their lines, outside the plot so the curve
                // never runs over them; with axes, the bpm where each starts.
                AxisMarks(position: .trailing, values: scale.zoneLines.map(\.bpm)) { value in
                    AxisValueLabel {
                        if let bpm = value.as(Int.self), let line = scale.zoneLines.first(where: { $0.bpm == bpm }) {
                            Text(showsAxes ? "Z\(line.zone) \(bpm)" : "Z\(line.zone)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(HeartRateZoneStyle.color(for: line.zone))
                        }
                    }
                }
            } else if showsAxes {
                AxisMarks()
            }
        }
        .modifier(MinutesAxisLabel(isShown: showsAxes))
        .chartOverlay { proxy in
            if interactive {
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(scrub(proxy: proxy, geo: geo))
                }
            }
        }
        .accessibilityLabel("Heart rate over time")
    }

    /// A hold first, so a quick swipe over the chart still scrolls the page;
    /// then the drag moves the readout.
    private func scrub(proxy: ChartProxy, geo: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case let .second(true, drag?) = value, let plot = proxy.plotFrame else { return }
                let x = drag.location.x - geo[plot].origin.x
                guard let minutes: Double = proxy.value(atX: x) else { return }
                if selected == nil {
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                selected = HeartRateChartScale.nearest(to: minutes * 60, in: points)
            }
            .onEnded { _ in selected = nil }
    }
}

/// "min" under the x-axis. Left off entirely when hidden: an empty label
/// still reserves its line below the plot.
private struct MinutesAxisLabel: ViewModifier {
    let isShown: Bool

    func body(content: Content) -> some View {
        if isShown {
            content.chartXAxisLabel("min")
        } else {
            content
        }
    }
}

/// The time, bpm and zone at the point being scrubbed.
private struct HeartRateReadout: View {
    let point: HeartRatePoint
    let zoneThresholds: [Int]

    var body: some View {
        let zone = LiveHeartRate.zone(for: point.bpm, thresholds: zoneThresholds)
        HStack(spacing: 6) {
            Text(Self.clock(point.seconds))
                .foregroundColor(Color("SecondaryText"))
            Text("\(point.bpm) bpm")
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryText"))
            if let zone, zone > 0 {
                Text("Z\(zone) \(HeartRateZoneStyle.name(for: zone))")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(HeartRateZoneStyle.color(for: zone))
                    .cornerRadius(4)
            }
        }
        .font(.caption2)
        .monospacedDigit()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("Background"))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("Border"), lineWidth: 1))
        .fixedSize()
    }

    static func clock(_ seconds: Double) -> String {
        let whole = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}

/// The bpm range a heart-rate chart shows, and which zone lines fall in it:
/// the curve's range widened to the zone start just below and just above it,
/// so the zones the athlete was in are framed without squashing the curve.
struct HeartRateChartScale: Equatable {
    struct ZoneLine: Equatable {
        let zone: Int
        let bpm: Int
    }

    let domain: ClosedRange<Int>
    let zoneLines: [ZoneLine]

    init(points: [HeartRatePoint], zoneThresholds: [Int]) {
        let low = points.map(\.bpm).min() ?? 60
        let high = points.map(\.bpm).max() ?? 180
        let thresholds = zoneThresholds.count == 5 ? zoneThresholds : []
        let floor = thresholds.last(where: { $0 <= low }) ?? low
        let ceiling = thresholds.first(where: { $0 >= high }) ?? high
        domain = (floor - 3)...(max(ceiling, floor + 1) + 3)
        zoneLines = thresholds.enumerated()
            .filter { (floor...ceiling).contains($0.element) }
            .map { ZoneLine(zone: $0.offset + 1, bpm: $0.element) }
    }

    /// The point closest in time to `seconds`; `points` are in time order.
    static func nearest(to seconds: Double, in points: [HeartRatePoint]) -> HeartRatePoint? {
        guard !points.isEmpty else { return nil }
        var low = 0
        var high = points.count - 1
        while low < high {
            let mid = (low + high) / 2
            if points[mid].seconds < seconds { low = mid + 1 } else { high = mid }
        }
        if low > 0, abs(points[low - 1].seconds - seconds) <= abs(points[low].seconds - seconds) {
            return points[low - 1]
        }
        return points[low]
    }
}

enum HeartRateZoneStyle {
    static func color(for zone: Int?) -> Color {
        switch zone {
        case 1: return .gray
        case 2: return .blue
        case 3: return .green
        case 4: return .orange
        case 5: return .red
        default: return Color("SecondaryText")
        }
    }

    static func name(for zone: Int) -> String {
        switch zone {
        case 1: return "Warm-up"
        case 2: return "Easy"
        case 3: return "Aerobic"
        case 4: return "Threshold"
        case 5: return "Max"
        default: return "Rest"
        }
    }
}

// MARK: - Pre-start chip

/// Sits above Start on a metcon: offers to connect a device, or shows the
/// remembered one's status and live bpm. Tapping it opens the connect sheet.
struct HeartRateChip: View {
    @ObservedObject var sensors: SensorManager = .shared
    @State private var showingConnect = false

    var body: some View {
        Button { showingConnect = true } label: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 8) {
                    Image(systemName: sensors.isTrackingConfigured ? "heart.fill" : "heart")
                        .foregroundColor(iconColor(at: context.date))
                        .symbolEffect(.pulse, isActive: sensors.currentBpm(at: context.date) != nil)
                    Text(label(at: context.date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("PrimaryText"))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color("Background"))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("Border"), lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingConnect) {
            DeviceConnectSheet()
        }
        .onAppear { sensors.prepareForWorkout() }
    }

    private func iconColor(at date: Date) -> Color {
        sensors.currentBpm(at: date) != nil ? .red : Color("SecondaryText")
    }

    private func label(at date: Date) -> String {
        guard let device = sensors.rememberedDevice, sensors.isHeartRateTrackingEnabled else {
            return "Track heart rate"
        }
        if let bpm = sensors.currentBpm(at: date) {
            return "\(device.name) · \(bpm) bpm"
        }
        switch sensors.connectionState {
        case .unavailable(.bluetoothOff): return "Bluetooth is off"
        case .unavailable(.unauthorized): return "Allow Bluetooth to track heart rate"
        case .unavailable(.unsupported): return "Heart rate isn't available on this device"
        case .connected: return "\(device.name) · waiting for heart rate"
        case .idle, .connecting:
            return device.brand == .garmin
                ? "\(device.name) not found · turn on Broadcast"
                : "Looking for \(device.name)…"
        }
    }
}

// MARK: - Live readout on the timer

/// bpm and zone during the workout. Shows "—" when readings stop, never an
/// alert: a dropout mid-WOD shouldn't interrupt anyone.
struct HeartRateHUD: View {
    @ObservedObject var sensors: SensorManager = .shared
    /// bpm where zones 1–5 start; empty until the session is open.
    let zoneThresholds: [Int]

    var body: some View {
        if sensors.isTrackingConfigured {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let bpm = sensors.currentBpm(at: context.date)
                let zone = bpm.flatMap { LiveHeartRate.zone(for: $0, thresholds: zoneThresholds) }
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(bpm == nil ? Color("SecondaryText") : HeartRateZoneStyle.color(for: zone))
                    Text(bpm.map(String.init) ?? "—")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(Color("PrimaryText"))
                        .contentTransition(.numericText())
                    if let zone, zone > 0 {
                        Text("Z\(zone)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HeartRateZoneStyle.color(for: zone))
                            .cornerRadius(5)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("Surface"))
                .cornerRadius(20)
                .animation(.snappy, value: bpm)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(bpm.map { "Heart rate \($0) beats per minute" } ?? "Heart rate unavailable")
            }
        }
    }
}
