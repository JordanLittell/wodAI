//
//  HeartRateSensorTests.swift
//  wodAITests
//
//  The Bluetooth heart-rate payload parser, brand detection from advertised
//  names, the live zone lookup, and the heart-rate chart's scale and scrubbing.
//

import Testing
import Foundation
@testable import wodAI

struct HeartRateMeasurementParserTests {
    @Test func parsesEightBitHeartRate() {
        let sample = HeartRateMeasurementParser.parse(Data([0x00, 72]))
        #expect(sample?.bpm == 72)
        #expect(sample?.sensorContact == nil)
        #expect(sample?.rrIntervalsMs.isEmpty == true)
    }

    @Test func parsesSixteenBitHeartRate() {
        // 0x0104 = 260, little-endian.
        let sample = HeartRateMeasurementParser.parse(Data([0x01, 0x04, 0x01]))
        #expect(sample?.bpm == 260)
    }

    @Test func readsSensorContact() {
        #expect(HeartRateMeasurementParser.parse(Data([0x06, 80]))?.sensorContact == true)
        #expect(HeartRateMeasurementParser.parse(Data([0x04, 80]))?.sensorContact == false)
        #expect(HeartRateMeasurementParser.parse(Data([0x04, 80]))?.isValid == false)
    }

    @Test func skipsEnergyExpendedBeforeRRIntervals() {
        // flags: energy (0x08) + RR (0x10); bpm 150; energy 0x0102; RR 1024 and 512 (1/1024 s).
        let sample = HeartRateMeasurementParser.parse(Data([0x18, 150, 0x02, 0x01, 0x00, 0x04, 0x00, 0x02]))
        #expect(sample?.bpm == 150)
        #expect(sample?.rrIntervalsMs == [1000, 500])
    }

    @Test func rejectsTruncatedPayloads() {
        #expect(HeartRateMeasurementParser.parse(Data()) == nil)
        #expect(HeartRateMeasurementParser.parse(Data([0x01, 0x04])) == nil) // 16-bit flag, one byte
        #expect(HeartRateMeasurementParser.parse(Data([0x08, 90, 0x01])) == nil) // energy flag, one byte
    }

    @Test func ignoresATrailingOddRRByte() {
        let sample = HeartRateMeasurementParser.parse(Data([0x10, 90, 0x00, 0x04, 0x07]))
        #expect(sample?.rrIntervalsMs == [1000])
    }
}

struct DeviceBrandTests {
    @Test(arguments: [
        ("Forerunner 265", DeviceBrand.garmin),
        ("fēnix 7", .garmin),
        ("Venu 3", .garmin),
        ("HRM-Pro:123456", .garmin),
        ("Polar H10 A1B2C3D4", .polar),
        ("TICKR 1A2B", .wahoo),
        ("HR Strap", .generic),
    ])
    func detectsBrandFromAdvertisedName(name: String, brand: DeviceBrand) {
        #expect(DeviceBrand.detect(fromName: name) == brand)
    }

    @Test func everyBrandHasSetupSteps() {
        for brand in DeviceBrand.allCases {
            #expect(!brand.setupGuide.steps.isEmpty)
        }
    }
}

struct LiveHeartRateZoneTests {
    private let thresholds = [94, 112, 131, 150, 168]

    @Test func zonesStartAtTheirThresholds() {
        #expect(LiveHeartRate.zone(for: 93, thresholds: thresholds) == 0)
        #expect(LiveHeartRate.zone(for: 94, thresholds: thresholds) == 1)
        #expect(LiveHeartRate.zone(for: 149, thresholds: thresholds) == 3)
        #expect(LiveHeartRate.zone(for: 150, thresholds: thresholds) == 4)
        #expect(LiveHeartRate.zone(for: 200, thresholds: thresholds) == 5)
    }

    @Test func noZoneWithoutThresholds() {
        #expect(LiveHeartRate.zone(for: 150, thresholds: []) == nil)
    }
}

struct HeartRateChartScaleTests {
    private static let thresholds = [94, 112, 131, 150, 168]

    private static func points(_ bpms: [Int]) -> [HeartRatePoint] {
        bpms.enumerated().map { HeartRatePoint(seconds: Double($0.offset * 10), bpm: $0.element) }
    }

    @Test func framesTheCurveWithTheZoneStartsAroundIt() {
        let scale = HeartRateChartScale(points: Self.points([120, 145, 160]), zoneThresholds: Self.thresholds)
        #expect(scale.zoneLines.map(\.zone) == [2, 3, 4, 5])
        #expect(scale.domain == 109...171)
    }

    @Test func noZoneLinesWithoutThresholds() {
        let scale = HeartRateChartScale(points: Self.points([120, 160]), zoneThresholds: [])
        #expect(scale.zoneLines.isEmpty)
        #expect(scale.domain == 117...163)
    }

    @Test func snapsToTheNearestPointInTime() {
        let points = Self.points([100, 110, 120, 130])
        #expect(HeartRateChartScale.nearest(to: -5, in: points)?.bpm == 100)
        #expect(HeartRateChartScale.nearest(to: 14, in: points)?.bpm == 110)
        #expect(HeartRateChartScale.nearest(to: 16, in: points)?.bpm == 120)
        #expect(HeartRateChartScale.nearest(to: 999, in: points)?.bpm == 130)
        #expect(HeartRateChartScale.nearest(to: 0, in: []) == nil)
    }
}
