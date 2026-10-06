//
//  HeartRateDevicesView.swift
//  wodAI
//
//  Side-menu screen for the heart-rate device: what's connected, the switch
//  for recording during workouts, and changing or forgetting the device.
//

import SwiftUI

struct HeartRateDevicesView: View {
    @ObservedObject private var sensors: SensorManager = .shared
    @State private var showingConnect = false
    @State private var confirmingForget = false

    var body: some View {
        List {
            if let device = sensors.rememberedDevice {
                Section {
                    deviceRow(device)
                    Toggle("Record heart rate during workouts", isOn: $sensors.isHeartRateTrackingEnabled)
                        .tint(Color("BrandPrimary"))
                } footer: {
                    Text("wodAI records your heart rate while a metcon's timer runs, then shows your zones, training load and estimated calories.")
                }

                Section {
                    Button("Change Device") { showingConnect = true }
                    Button("Forget \(device.name)", role: .destructive) { confirmingForget = true }
                }

                Section("How to connect") {
                    guideRows(device.brand.setupGuide)
                }
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                        Text("No heart rate monitor")
                            .font(.headline)
                        Text("Connect a Garmin or other watch in heart rate broadcast mode, or any Bluetooth chest strap, to see your live zone during metcons and how hard each one was.")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    .padding(.vertical, 6)
                    Button("Connect a Device") { showingConnect = true }
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle("Heart Rate Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConnect) { DeviceConnectSheet() }
        .confirmationDialog(
            "Forget this device?",
            isPresented: $confirmingForget,
            titleVisibility: .visible
        ) {
            Button("Forget Device", role: .destructive) { sensors.forgetDevice() }
        } message: {
            Text("Workouts won't record heart rate until you connect a device again.")
        }
        .onAppear { sensors.prepareForWorkout() }
    }

    private func deviceRow(_ device: RememberedDevice) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title)
                    .foregroundColor(sensors.currentBpm(at: context.date) != nil ? .red : Color("SecondaryText"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name).font(.body).fontWeight(.medium)
                    Text(status(at: context.date))
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func status(at date: Date) -> String {
        if !sensors.isHeartRateTrackingEnabled { return "Not recording" }
        if let bpm = sensors.currentBpm(at: date) { return "Connected · \(bpm) bpm" }
        switch sensors.connectionState {
        case .connected: return "Connected · waiting for heart rate"
        case .connecting, .idle: return "Not broadcasting right now"
        case let .unavailable(reason): return DeviceConnectSheet.message(for: reason)
        }
    }

    @ViewBuilder
    private func guideRows(_ guide: DeviceSetupGuide) -> some View {
        ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
            Label {
                Text(step).font(.subheadline)
            } icon: {
                Text("\(index + 1)").font(.caption).fontWeight(.bold)
            }
        }
        if let tip = guide.tip {
            Text(tip).font(.footnote).foregroundColor(Color("SecondaryText"))
        }
    }
}

#Preview {
    NavigationStack { HeartRateDevicesView() }
}
