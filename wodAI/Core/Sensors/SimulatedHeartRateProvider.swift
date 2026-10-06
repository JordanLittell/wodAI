//
//  SimulatedHeartRateProvider.swift
//  wodAI
//
//  Debug builds only. A pretend heart-rate monitor that shows up next to real
//  Bluetooth devices, so the whole flow (connect, live zone, upload, summary)
//  can be exercised in the Simulator, where CoreBluetooth doesn't run.
//

#if DEBUG
import Foundation
import Combine

final class SimulatedHeartRateProvider: SensorProvider {
    static let deviceID = "simulated-hrm"
    private static let device = DiscoveredDevice(
        id: deviceID,
        name: "Simulated HRM",
        brand: .generic,
        providerKind: .simulated,
        rssi: -40
    )

    let kind: SensorProviderKind = .simulated
    let supportedMetrics: Set<SensorMetric> = [.heartRate, .rrInterval]

    var discoveredDevices: AnyPublisher<[DiscoveredDevice], Never> { devicesSubject.eraseToAnyPublisher() }
    var samples: AnyPublisher<HeartRateSample, Never> { samplesSubject.eraseToAnyPublisher() }
    var state: AnyPublisher<SensorConnectionState, Never> { stateSubject.removeDuplicates().eraseToAnyPublisher() }

    private let devicesSubject = CurrentValueSubject<[DiscoveredDevice], Never>([])
    private let samplesSubject = PassthroughSubject<HeartRateSample, Never>()
    private let stateSubject = CurrentValueSubject<SensorConnectionState, Never>(.idle)
    private var timer: AnyCancellable?
    private var connectedAt = Date()

    func startScanning() { devicesSubject.send([Self.device]) }
    func stopScanning() {}

    func connect(deviceID: String, name: String) {
        guard deviceID == Self.deviceID else { return }
        stateSubject.send(.connecting(name: name))
        connectedAt = Date()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in self?.emit(at: now, name: name) }
    }

    func disconnect() {
        timer = nil
        stateSubject.send(.idle)
    }

    private func emit(at now: Date, name: String) {
        stateSubject.send(.connected(name: name))
        // Warms up from ~80 toward ~165 over two minutes, with a slow wave for
        // work/rest intervals and a little noise.
        let t = now.timeIntervalSince(connectedAt)
        let warmup = 80 + 85 * (1 - exp(-t / 45))
        let intervals = 8 * sin(t / 15)
        let bpm = Int((warmup + intervals + Double.random(in: -3...3)).rounded())
        let rr = 60_000 / Double(bpm)
        samplesSubject.send(HeartRateSample(date: now, bpm: bpm, rrIntervalsMs: [rr], sensorContact: true))
    }
}
#endif
