//
//  HeartRateMeasurementParser.swift
//  wodAI
//
//  Decodes the Bluetooth Heart Rate Measurement characteristic (0x2A37), the
//  payload every standard heart-rate device sends. Layout, little-endian:
//
//    byte 0      flags
//                  bit 0     heart rate is UInt16 (else UInt8)
//                  bits 1-2  sensor contact: bit 2 = supported, bit 1 = detected
//                  bit 3     energy expended field present (UInt16, kJ)
//                  bit 4     RR intervals present
//    then        heart rate (1 or 2 bytes)
//    then        energy expended (2 bytes), if flagged
//    then        RR intervals, UInt16 each in 1/1024 s, to the end
//

import Foundation

enum HeartRateMeasurementParser {
    static func parse(_ data: Data, at date: Date = Date()) -> HeartRateSample? {
        let bytes = [UInt8](data)
        guard let flags = bytes.first else { return nil }

        var index = 1
        func uint16() -> UInt16? {
            guard index + 1 < bytes.count else { return nil }
            defer { index += 2 }
            return UInt16(bytes[index]) | UInt16(bytes[index + 1]) << 8
        }

        let bpm: Int
        if flags & 0x01 != 0 {
            guard let value = uint16() else { return nil }
            bpm = Int(value)
        } else {
            guard index < bytes.count else { return nil }
            bpm = Int(bytes[index])
            index += 1
        }

        let contactSupported = flags & 0x04 != 0
        let contact: Bool? = contactSupported ? flags & 0x02 != 0 : nil

        if flags & 0x08 != 0 {
            guard uint16() != nil else { return nil }
        }

        var rrIntervals: [Double] = []
        if flags & 0x10 != 0 {
            while let raw = uint16() {
                rrIntervals.append(Double(raw) / 1024 * 1000)
            }
        }

        return HeartRateSample(date: date, bpm: bpm, rrIntervalsMs: rrIntervals, sensorContact: contact)
    }
}
