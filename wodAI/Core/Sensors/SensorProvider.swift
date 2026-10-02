//
//  SensorProvider.swift
//  wodAI
//
//  One way of getting data from a wearable. Each provider handles its own
//  discovery and connection; `SensorManager` merges them, so a new kind of
//  device (an Apple Watch app, a vendor SDK) is a new provider and nothing
//  downstream changes.
//

import Foundation
import Combine

protocol SensorProvider: AnyObject {
    var kind: SensorProviderKind { get }
    var supportedMetrics: Set<SensorMetric> { get }

    /// Devices found by the current scan, nearest first.
    var discoveredDevices: AnyPublisher<[DiscoveredDevice], Never> { get }
    /// Readings from the connected device.
    var samples: AnyPublisher<HeartRateSample, Never> { get }
    var state: AnyPublisher<SensorConnectionState, Never> { get }

    func startScanning()
    func stopScanning()
    /// Connects to a device by its `DiscoveredDevice.id`, whether it was just
    /// discovered or remembered from an earlier launch, and keeps reconnecting
    /// if it drops out until `disconnect()`.
    func connect(deviceID: String, name: String)
    func disconnect()
}
