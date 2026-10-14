//
//  StatGuide.swift
//  wodAI
//
//  The charts the Activity screen can switch between, and what each one means
//  in plain language. Definitions follow the backend's stat definitions
//  (workout-generator/src/stats/definitions).
//

import Foundation

/// In toggle order; the first is the default.
enum StatKind: String, CaseIterable, Identifiable {
    case volume, intensity, trainingLoad, recovery

    var id: String { rawValue }

    /// Short enough for a four-segment picker.
    var toggleLabel: String {
        switch self {
        case .volume: return "Volume"
        case .intensity: return "Minutes"
        case .trainingLoad: return "Load"
        case .recovery: return "Muscles"
        }
    }

    var title: String {
        switch self {
        case .volume: return "Volume"
        case .intensity: return "Intensity minutes"
        case .trainingLoad: return "Training load"
        case .recovery: return "Recovery right now"
        }
    }

    /// Shown instead of a chart of zeros.
    var emptyMessage: String {
        switch self {
        case .volume: return "No strength sets logged this week"
        case .intensity: return "No WODs completed this week"
        case .trainingLoad: return "Rate your effort or wear a heart rate monitor to see training load"
        case .recovery: return "Every region is fully recovered"
        }
    }

    func chart(in stats: ActivityStats?) -> StatChart? {
        switch self {
        case .volume: return stats?.volume
        case .intensity: return stats?.intensity
        case .trainingLoad: return stats?.trainingLoad
        // Recovery is "right now", not a weekly chart; it comes from muscleReadiness.
        case .recovery: return nil
        }
    }

    var definition: String {
        switch self {
        case .volume:
            return "The total weight you've lifted this week, adding up day by day: weight × reps for every strength set you logged. Bodyweight sets aren't counted. The dotted line is last week."
        case .intensity:
            return "Minutes of WOD work this week, adding up day by day: the time you logged, or the workout's estimate when you didn't log one. The dotted line is last week."
        case .trainingLoad:
            return "How hard this week's training was on your body, adding up day by day. Each workout combines how long it lasted with how hard it was: a WOD from your heart rate when you wore a monitor, otherwise from your effort rating; a strength session from the RPE of its sets. The dotted line is last week."
        case .recovery:
            return "How much of your recent training each body region is still carrying, when it's ready to train again, and when it's fully recovered."
        }
    }
}
