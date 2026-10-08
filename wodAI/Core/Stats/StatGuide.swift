//
//  StatGuide.swift
//  wodAI
//
//  The charts the Stats screen can switch between, and what each one means:
//  a plain-language definition and how to read it for progress, recovery and
//  injury risk. Definitions follow the backend's stat definitions
//  (workout-generator/src/stats/definitions).
//

import Foundation

struct StatPointer: Identifiable, Equatable {
    enum Topic: CaseIterable, Equatable {
        case progress, recovery, injuryRisk

        var title: String {
            switch self {
            case .progress: return "Progress"
            case .recovery: return "Recovery"
            case .injuryRisk: return "Injury risk"
            }
        }

        var systemImage: String {
            switch self {
            case .progress: return "chart.line.uptrend.xyaxis"
            case .recovery: return "bed.double"
            case .injuryRisk: return "exclamationmark.shield"
            }
        }
    }

    let topic: Topic
    let text: String
    var id: Topic { topic }
}

/// In toggle order; the first is the default.
enum StatKind: String, CaseIterable, Identifiable {
    case volume, intensity, trainingLoad, muscleLoad

    var id: String { rawValue }

    /// Short enough for a four-segment picker.
    var toggleLabel: String {
        switch self {
        case .volume: return "Volume"
        case .intensity: return "Minutes"
        case .trainingLoad: return "Load"
        case .muscleLoad: return "Muscles"
        }
    }

    var title: String {
        switch self {
        case .volume: return "Volume"
        case .intensity: return "Intensity minutes"
        case .trainingLoad: return "Training load"
        case .muscleLoad: return "Muscle load"
        }
    }

    /// Shown instead of a chart of zeros.
    var emptyMessage: String {
        switch self {
        case .volume: return "No strength sets logged this week"
        case .intensity: return "No WODs completed this week"
        case .trainingLoad: return "Rate your effort or wear a heart rate monitor to see training load"
        case .muscleLoad: return "No training this week"
        }
    }

    func chart(in stats: ActivityStats?) -> StatChart? {
        switch self {
        case .volume: return stats?.volume
        case .intensity: return stats?.intensity
        case .trainingLoad: return stats?.trainingLoad
        case .muscleLoad: return stats?.muscleLoad
        }
    }

    var definition: String {
        switch self {
        case .volume:
            return "The total weight you lifted each day: weight × reps for every strength set you logged. Bodyweight sets aren't counted."
        case .intensity:
            return "Minutes of WOD work each day: the time you logged, or the workout's estimate when you didn't log one."
        case .trainingLoad:
            return "How hard each WOD was on your body, combining how long it lasted with how hard it was. It comes from your heart rate when you wore a monitor, otherwise from your effort rating."
        case .muscleLoad:
            return "Each body region's share of this week's work, so you can see where your training went."
        }
    }

    /// One per topic, in `Topic` order.
    var pointers: [StatPointer] {
        switch self {
        case .volume:
            return [
                StatPointer(topic: .progress, text: "A slow, steady rise from week to week means you're getting stronger. Flat for a month? It may be time to add weight."),
                StatPointer(topic: .recovery, text: "Big days should be followed by lighter ones. Tall bars every day leave your muscles little time to rebuild."),
                StatPointer(topic: .injuryRisk, text: "Jumping more than about 10% in a week raises your risk of strains. Build up gradually."),
            ]
        case .intensity:
            return [
                StatPointer(topic: .progress, text: "Steady weekly minutes build your engine. Health guidelines suggest at least 75 minutes of hard effort a week."),
                StatPointer(topic: .recovery, text: "Spread minutes across the week rather than stacking them, and keep at least one day with none."),
                StatPointer(topic: .injuryRisk, text: "A sudden spike in minutes, especially after time off, is when overuse injuries happen. Ease back in."),
            ]
        case .trainingLoad:
            return [
                StatPointer(topic: .progress, text: "Fitness grows when load creeps up over weeks, not when one week is huge. Aim for gradual, repeatable increases."),
                StatPointer(topic: .recovery, text: "This feeds the Recovery card above: it compares your last 7 days to your usual 28. Several tall bars in a row mean you need an easier day."),
                StatPointer(topic: .injuryRisk, text: "Weeks far above your usual load (the Recovery card's High strain) are when injury risk is highest. Back off until it returns to On track."),
            ]
        case .muscleLoad:
            return [
                StatPointer(topic: .progress, text: "Regions you train consistently are the ones that improve. A region missing week after week will fall behind."),
                StatPointer(topic: .recovery, text: "A region taking a big share this week needs 48 hours or so before it's worked hard again."),
                StatPointer(topic: .injuryRisk, text: "One region carrying most of the work week after week is a common source of overuse pain. Balance it with other areas."),
            ]
        }
    }
}
