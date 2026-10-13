//
//  ConnectView.swift
//  wodAI
//
//  Side-menu screen for services that share fitness data with wodAI. Apple
//  Health is the first; other integrations that pull and publish fitness
//  data go here too.
//

import SwiftUI

struct ConnectView: View {
    @ObservedObject private var health: HealthSync = .shared

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AppleHealthSettingsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.pink, in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Health").font(.body).fontWeight(.medium)
                            Text(health.isConnected ? "Connected" : "Not connected")
                                .font(.caption)
                                .foregroundStyle(Color("SecondaryText"))
                        }
                    }
                }
            } footer: {
                Text("Share your training with the apps you already use.")
            }
        }
        .navigationTitle("Connect")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Apple Health: connect, sync again, choose whether workouts are saved,
/// and disconnect.
struct AppleHealthSettingsView: View {
    @ObservedObject private var health: HealthSync = .shared
    @State private var connection: HealthConnectionInfo?
    @State private var isSyncing = false
    @State private var message: String?
    @State private var suggestion: HealthSuggestion?
    @State private var selection: OnboardingLevel = .beginner
    @State private var confirmingDisconnect = false

    var body: some View {
        List {
            if !health.isAvailable {
                Section {
                    Text("Apple Health isn't available on this device.")
                        .foregroundStyle(Color("SecondaryText"))
                }
            } else if health.isConnected {
                connectedSections
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.pink)
                        Text("Connect Apple Health").font(.headline)
                        Text("wodAI reads your workouts, heart rate and cardio fitness to suggest where to start, and saves the workouts you finish so they count toward your Activity rings.")
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                    }
                    .padding(.vertical, 6)
                    syncButton(title: "Connect Apple Health")
                } footer: {
                    Text("A summary of your last 90 days of training is kept with your account to plan your workouts.")
                }
            }

            if let message {
                Section { Text(message).font(.subheadline).foregroundStyle(Color("SecondaryText")) }
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadConnection() }
        .confirmationDialog("Disconnect Apple Health?", isPresented: $confirmingDisconnect, titleVisibility: .visible) {
            Button("Disconnect", role: .destructive) { Task { await disconnect() } }
        } message: {
            Text("wodAI deletes what it keeps from Apple Health and stops saving workouts. Your profile answers stay.")
        }
        .sheet(item: $suggestion) { suggestion in
            NavigationStack {
                ScrollView {
                    HealthLevelPicker(suggestion: suggestion, selection: $selection)
                        .padding(24)
                }
                .navigationTitle("Here's what we found")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Not now") { self.suggestion = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Use \(selection.title)") { Task { await confirm(selection) } }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private var connectedSections: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected").font(.body).fontWeight(.medium)
                    Text(lastSyncText).font(.caption).foregroundStyle(Color("SecondaryText"))
                }
            }
            syncButton(title: "Sync now")
        }

        Section {
            Toggle("Save workouts to Apple Health", isOn: $health.writesWorkouts)
                .tint(Color("BrandPrimary"))
        } footer: {
            Text("A session is saved once its last set or metcon result is logged. If Apple Health already has a workout at that time, such as one from your Apple Watch, wodAI doesn't add a second.")
        }

        Section {
            Button("Disconnect Apple Health", role: .destructive) { confirmingDisconnect = true }
        } footer: {
            Text("To stop wodAI's access completely, open the Health app and go to Sharing, then Apps, then wodAI.")
        }
    }

    private func syncButton(title: String) -> some View {
        Button {
            Task { await sync() }
        } label: {
            HStack {
                Text(title).fontWeight(.semibold)
                if isSyncing {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(isSyncing)
    }

    private var lastSyncText: String {
        guard let syncedAt = connection?.syncedAt else { return "Not synced yet" }
        return "Last synced \(syncedAt.formatted(.relative(presentation: .named)))"
    }

    // MARK: - Actions

    private func loadConnection() async {
        guard health.isConnected else { return }
        connection = try? await health.connection()
    }

    /// Reads Health again and uploads it. Offers the suggested level when it
    /// differs from the athlete's current one.
    private func sync() async {
        isSyncing = true
        message = nil
        defer { isSyncing = false }
        do {
            let snapshot = try await health.connect()
            let found = try await health.upload(snapshot)
            connection = try? await health.connection()
            if let found, found.level != connection?.currentLevel {
                selection = found.level
                suggestion = found
            } else {
                message = snapshot.isEmpty
                    ? "We didn't find anything in Apple Health. Check that wodAI can read your data in the Health app."
                    : "You're up to date."
            }
        } catch {
            message = "Couldn't sync with Apple Health. Check your connection and try again."
        }
    }

    private func confirm(_ level: OnboardingLevel) async {
        do {
            try await health.confirm(level)
            suggestion = nil
            message = "Your level is now \(level.title)."
            connection = try? await health.connection()
        } catch {
            message = "Couldn't save your level. Try again."
        }
    }

    private func disconnect() async {
        do {
            try await health.disconnect()
            connection = nil
            message = nil
        } catch {
            message = "Couldn't disconnect. Check your connection and try again."
        }
    }
}

extension HealthSuggestion: Identifiable {
    var id: String { level.rawValue + reasons.joined() }
}
