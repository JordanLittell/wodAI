//
//  SensorManager.swift
//  wodAI
//
//  The app's one place for wearables: which device the user picked, whether
//  it's connected, and its latest reading. Merges every `SensorProvider`, so
//  screens and the workout recorder never deal with a specific kind of device.
//

import Foundation
import Combine

@MainActor
final class SensorManager: ObservableObject {
    static let shared = SensorManager()

    @Published private(set) var rememberedDevice: RememberedDevice?
    /// The user's switch for recording heart rate during workouts. On by
    /// default once a device is picked; off means the device is kept but unused.
    @Published var isHeartRateTrackingEnabled: Bool {
        didSet {
            defaults.set(isHeartRateTrackingEnabled, forKey: Keys.trackingEnabled)
            if isHeartRateTrackingEnabled { reconnect() } else { activeProvider?.disconnect() }
        }
    }
    @Published private(set) var connectionState: SensorConnectionState = .idle
    @Published private(set) var latestSample: HeartRateSample?
    /// Devices found while the connect sheet is scanning, nearest first.
    @Published private(set) var discoveredDevices: [DiscoveredDevice] = []
    /// Set when Bluetooth itself can't be used (off, not allowed), so the
    /// connect sheet can say why nothing shows up.
    @Published private(set) var bluetoothIssue: SensorUnavailableReason?

    /// Every reading from the active device, for the workout recorder.
    var samples: AnyPublisher<HeartRateSample, Never> { samplesSubject.eraseToAnyPublisher() }

    /// A reading older than this is stale: the device stopped sending.
    static let staleAfter: TimeInterval = 5

    private enum Keys {
        static let rememberedDevice = "sensors.rememberedDevice"
        static let trackingEnabled = "sensors.heartRateTrackingEnabled"
    }

    private let defaults: UserDefaults
    private let samplesSubject = PassthroughSubject<HeartRateSample, Never>()
    private var providers: [SensorProviderKind: SensorProvider]
    private var discovered: [SensorProviderKind: [DiscoveredDevice]] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var activeCancellables = Set<AnyCancellable>()

    init(providers: [SensorProvider]? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.providers = Dictionary(
            uniqueKeysWithValues: (providers ?? Self.defaultProviders()).map { ($0.kind, $0) }
        )
        self.isHeartRateTrackingEnabled = defaults.object(forKey: Keys.trackingEnabled) as? Bool ?? true
        if let data = defaults.data(forKey: Keys.rememberedDevice) {
            self.rememberedDevice = try? JSONDecoder().decode(RememberedDevice.self, from: data)
        }
        subscribeToProviders()
        if let rememberedDevice { activate(rememberedDevice.providerKind) }
    }

    private static func defaultProviders() -> [SensorProvider] {
        var providers: [SensorProvider] = [BluetoothHeartRateProvider()]
        #if DEBUG
        providers.append(SimulatedHeartRateProvider())
        #endif
        return providers
    }

    // MARK: - State

    /// True when a device is picked and tracking is on: a workout will try to record.
    var isTrackingConfigured: Bool { rememberedDevice != nil && isHeartRateTrackingEnabled }

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    /// The latest reading if it's fresh and valid, else nil (show "—").
    func currentBpm(at now: Date = Date()) -> Int? {
        guard isConnected, let sample = latestSample, sample.isValid,
              now.timeIntervalSince(sample.date) <= Self.staleAfter else { return nil }
        return sample.bpm
    }

    /// Whether connecting will show the system Bluetooth prompt, so the UI can
    /// explain why first.
    var needsBluetoothPermission: Bool { BluetoothHeartRateProvider.needsPermissionPrompt }

    /// Where the samples come from, as the workout session records it.
    var currentSource: SensorSource? {
        rememberedDevice.map { SensorSource(kind: $0.providerKind, deviceName: $0.name, brand: $0.brand) }
    }

    // MARK: - Actions

    /// Called as a workout starts: reconnect to the remembered device if it
    /// isn't connected already. Harmless when there's nothing to connect.
    func prepareForWorkout() {
        guard isTrackingConfigured, !isConnected else { return }
        reconnect()
    }

    func startDiscovery() {
        providers.values.forEach { $0.startScanning() }
    }

    func stopDiscovery() {
        providers.values.forEach { $0.stopScanning() }
    }

    /// Remember a device and connect to it.
    func select(_ device: DiscoveredDevice) {
        if let current = rememberedDevice, current.providerKind != device.providerKind {
            providers[current.providerKind]?.disconnect()
        }
        let remembered = RememberedDevice(
            providerKind: device.providerKind,
            identifier: device.id,
            name: device.name,
            brand: device.brand
        )
        rememberedDevice = remembered
        if let data = try? JSONEncoder().encode(remembered) {
            defaults.set(data, forKey: Keys.rememberedDevice)
        }
        if !isHeartRateTrackingEnabled { isHeartRateTrackingEnabled = true }
        activate(device.providerKind)
        providers[device.providerKind]?.connect(deviceID: device.id, name: device.name)
    }

    func forgetDevice() {
        activeProvider?.disconnect()
        activeCancellables.removeAll()
        rememberedDevice = nil
        defaults.removeObject(forKey: Keys.rememberedDevice)
        latestSample = nil
        connectionState = .idle
    }

    // MARK: - Wiring

    private var activeProvider: SensorProvider? {
        rememberedDevice.flatMap { providers[$0.providerKind] }
    }

    private func reconnect() {
        guard let device = rememberedDevice, isHeartRateTrackingEnabled else { return }
        providers[device.providerKind]?.connect(deviceID: device.identifier, name: device.name)
    }

    /// Discovery and Bluetooth availability come from every provider.
    private func subscribeToProviders() {
        for provider in providers.values {
            let kind = provider.kind
            provider.discoveredDevices
                .receive(on: DispatchQueue.main)
                .sink { [weak self] devices in
                    guard let self else { return }
                    self.discovered[kind] = devices
                    self.discoveredDevices = self.discovered.values.flatMap { $0 }
                        .sorted { ($0.rssi ?? 0) > ($1.rssi ?? 0) }
                }
                .store(in: &cancellables)
            if kind == .bluetoothHeartRate {
                provider.state
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] state in
                        if case let .unavailable(reason) = state {
                            self?.bluetoothIssue = reason
                        } else {
                            self?.bluetoothIssue = nil
                        }
                    }
                    .store(in: &cancellables)
            }
        }
    }

    /// Connection state and readings come from the remembered device's provider only.
    private func activate(_ kind: SensorProviderKind) {
        activeCancellables.removeAll()
        guard let provider = providers[kind] else { return }
        provider.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.connectionState = state }
            .store(in: &activeCancellables)
        provider.samples
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sample in
                self?.latestSample = sample
                self?.samplesSubject.send(sample)
            }
            .store(in: &activeCancellables)
    }
}
