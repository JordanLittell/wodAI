//
//  WhiteboardHeuristic.swift
//  wodAI
//
//  Decides, on the phone, when the camera is looking at something worth
//  sending: text that reads like a workout and has held steady for a moment.
//  It's a cheap first filter so the camera can close by itself; the server
//  reads the photo properly and can still reject it.
//

import Foundation
import UIKit

enum WhiteboardHeuristic {
    /// True when recognized text reads like a workout: at least three lines,
    /// at least two with numbers (reps, loads, times), and at least one
    /// workout cue (a format like AMRAP or "For Time", a rep scheme like
    /// 21-15-9 or 5x5, a unit, or a common movement).
    static func looksLikeWorkout(lines: [String]) -> Bool {
        let lines = lines
            .flatMap { $0.split(whereSeparator: \.isNewline) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard lines.count >= 3 else { return false }

        let withNumbers = lines.filter { $0.contains(where: \.isNumber) }
        guard withNumbers.count >= 2 else { return false }

        let text = lines.joined(separator: "\n")
        return cues.contains { text.range(of: $0, options: [.regularExpression, .caseInsensitive]) != nil }
    }

    /// Formats, rep schemes, units, and movements, each as a regex.
    private static let cues: [String] = [
        // Formats and structure
        #"\bamrap\b"#, #"\bemom\b"#, #"\be\d+mom\b"#, #"\bfor\s+time\b"#, #"\brft\b"#, #"\btabata\b"#,
        #"\brounds?\b"#, #"\bsets?\b"#, #"\breps?\b"#, #"\brest\b"#, #"\bcap\b"#, #"\bevery\b"#,
        // Rep schemes: 21-15-9, 5x5, 3 × 10
        #"\b\d+(\s*-\s*\d+){2,}\b"#, #"\b\d+\s*[x×]\s*\d+\b"#,
        // Units: 400m, 95 lb, 24kg, 20 cal, 2 min
        #"\b\d+\s*(m|km|lbs?|kg|cals?|calories|min|mins|minutes|sec|secs)\b"#, #"\d+\s*#"#,
        // Movements
        #"squat"#, #"deadlift"#, #"\bclean"#, #"snatch"#, #"\bjerk"#, #"press"#, #"thruster"#, #"burpee"#,
        #"pull[\s-]?ups?"#, #"push[\s-]?ups?"#, #"\brow"#, #"\brun\b"#, #"wall\s*balls?"#, #"kettlebell"#, #"\bkbs?\b"#,
        #"swings?"#, #"lunges?"#, #"box\s*jumps?"#, #"double[\s-]?unders?"#, #"\bdus?\b"#, #"toes[\s-]?to[\s-]?bar"#,
        #"\bt2b\b"#, #"muscle[\s-]?ups?"#, #"handstand"#, #"\bhspu\b"#, #"sit[\s-]?ups?"#, #"\bbike\b"#, #"\bski\b"#,
        #"dumbbell"#, #"\bdbs?\b"#,
    ]
}

/// Holds the camera until the text has looked like a workout for
/// `holdDuration` without a break, so a passing glance doesn't trigger it.
struct WhiteboardStabilityGate {
    var holdDuration: TimeInterval = 1.0
    private(set) var passingSince: Date?

    init(holdDuration: TimeInterval = 1.0) {
        self.holdDuration = holdDuration
    }

    /// Records the latest check; a failing one restarts the hold.
    mutating func update(passes: Bool, at now: Date) {
        if passes {
            if passingSince == nil { passingSince = now }
        } else {
            passingSince = nil
        }
    }

    func isSatisfied(at now: Date) -> Bool {
        guard let passingSince else { return false }
        return now.timeIntervalSince(passingSince) >= holdDuration
    }
}

enum WhiteboardImageEncoder {
    /// The photo scaled so its long edge is at most `maxDimension`, as JPEG.
    /// About 200-400 KB: plenty for the model to read a board, small enough
    /// to send over the socket.
    static func jpeg(from image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.7) -> Data? {
        let size = image.size
        let longEdge = max(size.width, size.height)
        guard longEdge > 0 else { return nil }
        let scale = min(1, maxDimension / longEdge)
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
