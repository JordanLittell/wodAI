//
//  DeviceBrand.swift
//  wodAI
//
//  Who made a device, and how to get it sending heart rate. This is the place
//  brand-specific setup lives: adding a brand is a case, its name patterns and
//  its guide. A brand that needs more than instructions (its own SDK or app)
//  also gets its own `SensorProvider`; the workout code doesn't change.
//

import Foundation

enum DeviceBrand: String, Codable, CaseIterable, Identifiable {
    case garmin
    case polar
    case wahoo
    case generic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .garmin: return "Garmin"
        case .polar: return "Polar"
        case .wahoo: return "Wahoo"
        case .generic: return "Other"
        }
    }

    /// Lowercased fragments of the names devices advertise. Garmin watches
    /// broadcast under their model name, so the list is of model lines; the
    /// HRM- prefix covers Garmin's chest straps.
    private var namePatterns: [String] {
        switch self {
        case .garmin:
            return ["garmin", "forerunner", "fenix", "fēnix", "epix", "venu", "vivoactive", "vívoactive",
                    "instinct", "enduro", "tactix", "approach", "descent", "quatix", "hrm-", "hrm "]
        case .polar:
            return ["polar"]
        case .wahoo:
            return ["tickr", "wahoo"]
        case .generic:
            return []
        }
    }

    /// The brand a device's advertised name points to, or `.generic`.
    static func detect(fromName name: String) -> DeviceBrand {
        let lowered = name.lowercased()
        return allCases.first { brand in
            brand.namePatterns.contains { lowered.contains($0) }
        } ?? .generic
    }

    var setupGuide: DeviceSetupGuide {
        switch self {
        case .garmin:
            return DeviceSetupGuide(
                title: "Turn on heart rate broadcast",
                steps: [
                    "On your watch, open the controls menu (on most models, hold the top-left button).",
                    "Choose Broadcast Heart Rate. If it isn't there, look under Settings › Sensors & Accessories › Wrist Heart Rate.",
                    "Keep the watch nearby. It will show up in the list below.",
                ],
                tip: "Menu names vary by model. To skip this step each time, turn on Broadcast During Activity in your watch's wrist heart rate settings, then start a HIIT activity on the watch when you start the workout.",
                helpURL: URL(string: "https://support.garmin.com/")
            )
        case .polar:
            return DeviceSetupGuide(
                title: "Start broadcasting",
                steps: [
                    "Chest strap: wet the electrodes and put it on. It starts broadcasting by itself.",
                    "Polar watch: start a training session and turn on sharing heart rate with other devices.",
                    "It will show up in the list below.",
                ],
                tip: nil,
                helpURL: URL(string: "https://support.polar.com/")
            )
        case .wahoo:
            return DeviceSetupGuide(
                title: "Put on your TICKR",
                steps: [
                    "Wet the strap and put it on. The TICKR starts broadcasting once it detects your heart rate.",
                    "It will show up in the list below.",
                ],
                tip: nil,
                helpURL: URL(string: "https://support.wahoofitness.com/")
            )
        case .generic:
            return DeviceSetupGuide(
                title: "Start broadcasting",
                steps: [
                    "Chest strap: put it on. Most start broadcasting when they detect your heart rate.",
                    "Watch: turn on its heart rate broadcast (sometimes called HR broadcast or sharing heart rate).",
                    "It will show up in the list below.",
                ],
                tip: "Any device that works with gym equipment or cycling apps as a Bluetooth heart rate monitor will work here.",
                helpURL: nil
            )
        }
    }
}

struct DeviceSetupGuide: Equatable {
    let title: String
    let steps: [String]
    let tip: String?
    let helpURL: URL?
}
