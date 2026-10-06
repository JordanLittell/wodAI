//
//  BluetoothHeartRateProvider.swift
//  wodAI
//
//  Any device that speaks the standard Bluetooth Heart Rate Service: chest
//  straps, and watches in heart-rate broadcast mode (Garmin, Polar, ...). These
//  connect inside the app, never through iPhone Settings › Bluetooth.
//
//  The CBCentralManager is created on first use rather than at launch, because
//  creating it is what shows the Bluetooth permission prompt; that should
//  happen when the user asks to connect a device, not on app start.
//

import Foundation
import Combine
import CoreBluetooth

final class BluetoothHeartRateProvider: NSObject, SensorProvider {
    static let heartRateService = CBUUID(string: "180D")
    static let heartRateMeasurement = CBUUID(string: "2A37")
    private static let restoreIdentifier = "com.adapt.wodAI.heart-rate-central"

    let kind: SensorProviderKind = .bluetoothHeartRate
    let supportedMetrics: Set<SensorMetric> = [.heartRate, .rrInterval]

    var discoveredDevices: AnyPublisher<[DiscoveredDevice], Never> { devicesSubject.eraseToAnyPublisher() }
    var samples: AnyPublisher<HeartRateSample, Never> { samplesSubject.eraseToAnyPublisher() }
    var state: AnyPublisher<SensorConnectionState, Never> { stateSubject.removeDuplicates().eraseToAnyPublisher() }

    private let devicesSubject = CurrentValueSubject<[DiscoveredDevice], Never>([])
    private let samplesSubject = PassthroughSubject<HeartRateSample, Never>()
    private let stateSubject = CurrentValueSubject<SensorConnectionState, Never>(.idle)

    private var central: CBCentralManager?
    private var seen: [UUID: (peripheral: CBPeripheral, rssi: Int?)] = [:]
    /// The device we're connected to or trying to reach, kept so a dropout
    /// reconnects automatically.
    private var target: (id: UUID, name: String)?
    private var connected: CBPeripheral?
    private var wantsScan = false

    /// Whether using Bluetooth will show the system permission prompt.
    static var needsPermissionPrompt: Bool { CBManager.authorization == .notDetermined }

    private func makeCentralIfNeeded() -> CBCentralManager {
        if let central { return central }
        let created = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreIdentifier]
        )
        central = created
        return created
    }

    func startScanning() {
        wantsScan = true
        let central = makeCentralIfNeeded()
        guard central.state == .poweredOn else { return }
        seen = seen.filter { $0.value.peripheral.state == .connected }
        // Devices already connected to this phone (by another app, or by us)
        // don't advertise, so they'd never appear in a scan.
        for peripheral in central.retrieveConnectedPeripherals(withServices: [Self.heartRateService]) {
            seen[peripheral.identifier] = (peripheral, nil)
        }
        publishDevices()
        // Duplicates keep RSSI fresh, so the list can sort nearest first.
        central.scanForPeripherals(
            withServices: [Self.heartRateService],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stopScanning() {
        wantsScan = false
        central?.stopScan()
    }

    func connect(deviceID: String, name: String) {
        guard let id = UUID(uuidString: deviceID) else { return }
        if let current = connected, current.identifier != id {
            central?.cancelPeripheralConnection(current)
        }
        target = (id, name)
        stateSubject.send(.connecting(name: name))
        let central = makeCentralIfNeeded()
        if central.state == .poweredOn { connectTarget(using: central) }
    }

    func disconnect() {
        target = nil
        if let connected { central?.cancelPeripheralConnection(connected) }
        connected = nil
        stateSubject.send(.idle)
    }

    private func connectTarget(using central: CBCentralManager) {
        guard let target else { return }
        let peripheral = seen[target.id]?.peripheral
            ?? central.retrievePeripherals(withIdentifiers: [target.id]).first
        guard let peripheral else {
            // Never seen on this phone: find it by scanning; didDiscover connects.
            central.scanForPeripherals(withServices: [Self.heartRateService])
            return
        }
        peripheral.delegate = self
        if peripheral.state == .connected {
            didConnect(peripheral)
        } else {
            // A pending connect doesn't time out: iOS completes it whenever the
            // device starts broadcasting, so turning broadcast on later just works.
            central.connect(peripheral)
        }
    }

    private func didConnect(_ peripheral: CBPeripheral) {
        connected = peripheral
        stateSubject.send(.connected(name: target?.name ?? peripheral.name ?? "Heart rate monitor"))
        if !wantsScan { central?.stopScan() }
        peripheral.discoverServices([Self.heartRateService])
    }

    private func publishDevices() {
        let devices = seen.values
            .map { entry -> DiscoveredDevice in
                let name = entry.peripheral.name ?? "Heart rate monitor"
                return DiscoveredDevice(
                    id: entry.peripheral.identifier.uuidString,
                    name: name,
                    brand: DeviceBrand.detect(fromName: name),
                    providerKind: kind,
                    rssi: entry.rssi
                )
            }
            // Strongest signal first: the athlete's own device is usually closest.
            // Already-connected devices (no RSSI) go first too.
            .sorted { ($0.rssi ?? 0) > ($1.rssi ?? 0) }
        devicesSubject.send(devices)
    }

    private func unavailableReason(for state: CBManagerState) -> SensorUnavailableReason? {
        switch state {
        case .poweredOff: return .bluetoothOff
        case .unauthorized: return .unauthorized
        case .unsupported: return .unsupported
        default: return nil
        }
    }
}

extension BluetoothHeartRateProvider: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if let reason = unavailableReason(for: central.state) {
            stateSubject.send(.unavailable(reason))
            return
        }
        guard central.state == .poweredOn else { return }
        if let target {
            stateSubject.send(.connecting(name: target.name))
            connectTarget(using: central)
        } else {
            stateSubject.send(.idle)
        }
        if wantsScan { startScanning() }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        // iOS relaunched the app in the background mid-workout; pick the
        // connection back up instead of dropping it.
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        for peripheral in peripherals {
            peripheral.delegate = self
            seen[peripheral.identifier] = (peripheral, nil)
            if target == nil {
                target = (peripheral.identifier, peripheral.name ?? "Heart rate monitor")
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssi = RSSI.intValue
        // 127 means "unavailable"; keep the last good reading.
        let usable = rssi == 127 ? seen[peripheral.identifier]?.rssi : rssi
        seen[peripheral.identifier] = (peripheral, usable)
        if wantsScan { publishDevices() }
        if let target, target.id == peripheral.identifier, peripheral.state == .disconnected {
            peripheral.delegate = self
            central.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard peripheral.identifier == target?.id else {
            central.cancelPeripheralConnection(peripheral)
            return
        }
        didConnect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard peripheral.identifier == target?.id else { return }
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if connected?.identifier == peripheral.identifier { connected = nil }
        // Out of range or broadcast switched off: wait for it to come back.
        guard let target, target.id == peripheral.identifier else { return }
        stateSubject.send(.connecting(name: target.name))
        central.connect(peripheral)
    }
}

extension BluetoothHeartRateProvider: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid == Self.heartRateService {
            peripheral.discoverCharacteristics([Self.heartRateMeasurement], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] where characteristic.uuid == Self.heartRateMeasurement {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == Self.heartRateMeasurement,
              let data = characteristic.value,
              let sample = HeartRateMeasurementParser.parse(data) else { return }
        samplesSubject.send(sample)
    }
}
