//
//  DeviceConnectSheet.swift
//  wodAI
//
//  Picking a heart-rate device: why Bluetooth is needed (before iOS asks), how
//  to get your brand of device broadcasting, then nearby devices to tap.
//

import SwiftUI

struct DeviceConnectSheet: View {
    @ObservedObject private var sensors: SensorManager
    @Environment(\.dismiss) private var dismiss
    @State private var brand: DeviceBrand
    @State private var acknowledgedPermission = false

    init(sensors: SensorManager = .shared) {
        self._sensors = ObservedObject(wrappedValue: sensors)
        self._brand = State(initialValue: sensors.rememberedDevice?.brand ?? .garmin)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if sensors.needsBluetoothPermission && !acknowledgedPermission {
                        permissionExplainer
                    } else {
                        brandPicker
                        setupGuide
                        nearbyDevices
                        footnote
                    }
                }
                .padding()
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("Heart Rate Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if !sensors.needsBluetoothPermission { sensors.startDiscovery() }
        }
        .onDisappear { sensors.stopDiscovery() }
    }

    // MARK: - Permission

    private var permissionExplainer: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 44))
                .foregroundColor(.red)
            Text("Track your heart rate")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("PrimaryText"))
            Text("wodAI reads heart rate from your watch or chest strap over Bluetooth while you work out. It shows your live zone and, afterward, how hard the workout was and how much recovery you may need.")
                .foregroundColor(Color("SecondaryText"))
            Text("iOS will ask for Bluetooth access next.")
                .font(.footnote)
                .foregroundColor(Color("SecondaryText"))
            Button {
                acknowledgedPermission = true
                sensors.startDiscovery()
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BrandPrimary"))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
    }

    // MARK: - Brand setup

    private var brandPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you connecting?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryText"))
            Picker("Brand", selection: $brand) {
                ForEach(DeviceBrand.allCases) { brand in
                    Text(brand.displayName).tag(brand)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var setupGuide: some View {
        let guide = brand.setupGuide
        return VStack(alignment: .leading, spacing: 12) {
            Text(guide.title)
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color("BrandPrimary")))
                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(Color("PrimaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let tip = guide.tip {
                Label(tip, systemImage: "lightbulb")
                    .font(.footnote)
                    .foregroundColor(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let url = guide.helpURL {
                Link("\(brand.displayName) support", destination: url)
                    .font(.footnote)
                    .foregroundColor(Color("BrandPrimary"))
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Border"), lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: brand)
    }

    // MARK: - Devices

    private var nearbyDevices: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Nearby devices")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                if sensors.bluetoothIssue == nil { ProgressView().controlSize(.small) }
            }

            if let issue = sensors.bluetoothIssue {
                Label(Self.message(for: issue), systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }

            if sensors.discoveredDevices.isEmpty && sensors.bluetoothIssue == nil {
                Text("Searching… Make sure your device is broadcasting and close to your phone.")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }

            ForEach(sensors.discoveredDevices) { device in
                deviceRow(device)
            }
        }
    }

    private func deviceRow(_ device: DiscoveredDevice) -> some View {
        let isSelected = sensors.rememberedDevice?.identifier == device.id
        return Button { sensors.select(device) } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .red : Color("SecondaryText"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color("PrimaryText"))
                    Text(isSelected ? selectedStatus : signalDescription(device.rssi))
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("Success"))
                }
            }
            .padding()
            .background(Color("Surface"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("Success") : Color("Border"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var selectedStatus: String {
        if let bpm = sensors.currentBpm() { return "Connected · \(bpm) bpm" }
        switch sensors.connectionState {
        case .connected: return "Connected · waiting for heart rate"
        default: return "Connecting…"
        }
    }

    private func signalDescription(_ rssi: Int?) -> String {
        guard let rssi else { return "Connected to this iPhone" }
        if rssi >= -60 { return "Very close" }
        if rssi >= -75 { return "Nearby" }
        return "Far away"
    }

    private var footnote: some View {
        Text("You don't need to pair it in iPhone Settings › Bluetooth. wodAI connects to it directly, and reconnects on its own next time.")
            .font(.footnote)
            .foregroundColor(Color("SecondaryText"))
    }

    static func message(for issue: SensorUnavailableReason) -> String {
        switch issue {
        case .bluetoothOff: return "Bluetooth is off. Turn it on in Control Center."
        case .unauthorized: return "wodAI doesn't have Bluetooth access. Allow it in Settings › wodAI."
        case .unsupported: return "This device doesn't support Bluetooth heart rate monitors."
        }
    }
}

#Preview {
    DeviceConnectSheet()
}
