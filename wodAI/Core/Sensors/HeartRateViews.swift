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
/// gives a bare sparkline for small cards.
struct HeartRateSparkline: View {
    let points: [HeartRatePoint]
    var showsAxes = true

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Minutes", point.seconds / 60),
                y: .value("bpm", point.bpm)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.red)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis(showsAxes ? .automatic : .hidden)
        .chartYAxis(showsAxes ? .automatic : .hidden)
        .chartXAxisLabel(showsAxes ? "min" : "")
        .accessibilityLabel("Heart rate over time")
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
