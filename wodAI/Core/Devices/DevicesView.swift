//
//  DevicesView.swift
//  wodAI
//
//  Lets the user set up workout-tracking devices. Apple Watch only for now; the layout is
//  list-based so additional device kinds slot in later. Setup is where permissions are
//  granted — keeping them off the disruptive workout hot path.
//

import SwiftUI

struct DevicesView: View {
    // Connection + permission state the phone tracks for the watch.
    @ObservedObject private var bridge = HIITSessionManager.shared.bridge
    @State private var preparing = false
    @State private var showInstructions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                appleWatchCard

                if showInstructions && !bridge.isWatchConfigured {
                    instructionsCard
                }

                Text("More device types coming soon.")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding()
        }
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Apple Watch

    private var appleWatchCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "applewatch")
                    .font(.title2)
                    .foregroundColor(statusColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Watch")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                Spacer()
                if bridge.isWatchConfigured {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            if bridge.isWatchConfigured {
                permissionRow("heart.fill", "Health", bridge.watchHealthAuthorized)
                permissionRow("figure.walk.motion", "Motion", bridge.watchMotionAuthorized)
            } else if canSetUp {
                Button(action: beginSetup) {
                    Text(preparing ? "Preparing…" : "Set Up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color("BrandPrimary"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(preparing)
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("Border"), lineWidth: 1))
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Finish on your Apple Watch", systemImage: "arrow.right.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color("PrimaryText"))
            Text("Open the wodAI app on your Apple Watch and tap **Grant Access** to allow Health & Motion tracking. This page updates automatically once it's done.")
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("BrandPrimary").opacity(0.08))
        .cornerRadius(12)
    }

    private func permissionRow(_ icon: String, _ label: String, _ granted: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Color("SecondaryText"))
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color("PrimaryText"))
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(granted ? .green : Color("SecondaryText"))
        }
    }

    // MARK: - Derived state

    /// We can run setup only once the watch app is actually installed on a paired watch.
    private var canSetUp: Bool { bridge.isPaired && bridge.isWatchAppInstalled }

    private var statusText: String {
        if bridge.isWatchConfigured { return bridge.isReachable ? "Connected" : "Set up — ready" }
        if !bridge.isPaired { return "No Apple Watch paired" }
        if !bridge.isWatchAppInstalled { return "Install wodAI on your Apple Watch" }
        return "Tap Set Up to grant access"
    }

    private var statusColor: Color {
        bridge.isWatchConfigured ? .green : Color("SecondaryText")
    }

    private func beginSetup() {
        preparing = true
        showInstructions = true
        Task {
            // Phone-side HealthKit auth needed to auto-launch the watch app later.
            await HIITSessionManager.shared.requestPhoneHealthAuthorization()
            preparing = false
        }
    }
}

#Preview {
    NavigationStack { DevicesView() }
}
