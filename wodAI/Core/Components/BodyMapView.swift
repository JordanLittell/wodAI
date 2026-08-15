//
//  BodyMapView.swift
//  wodAI
//
//  "Muscles worked", drawn on a human figure rather than listed as anatomy.
//
//  Users should not need to know what "lats" or "posterior chain" means to read
//  their own recap, so the diagram is the primary representation and the text
//  underneath is plain-English support. Front and back are always shown
//  together: most CrossFit work is posterior-chain heavy, and a front-only
//  figure would systematically under-report what was trained.
//
//  Artwork lives entirely in `BodyMapArt` — this view never hard-codes geometry,
//  so swapping the placeholder for the commissioned figure touches no code here.
//

import SwiftUI

struct BodyMapView: View {
    let summary: MuscleSummary
    /// Height of each figure. Both are drawn at the same scale so they read as
    /// two views of one body.
    var figureHeight: CGFloat = 190

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if summary.isEmpty {
                emptyState
            } else {
                figures
                topRegionsLabel
            }
        }
    }

    // MARK: - Figures

    private var figures: some View {
        HStack(spacing: 12) {
            labelledFigure("Front", regions: BodyMapArt.front)
            labelledFigure("Back", regions: BodyMapArt.back)
        }
        // The figures carry the whole message and are individually meaningless
        // to a screen reader, so expose one summarising element instead of 18
        // unlabelled shapes.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Muscles worked")
        .accessibilityValue(accessibilityDescription)
    }

    private func labelledFigure(_ title: String, regions: [MuscleGroup: String]) -> some View {
        VStack(spacing: 6) {
            figure(regions: regions)
                .frame(height: figureHeight)
            Text(title)
                .font(.caption2)
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
    }

    private func figure(regions: [MuscleGroup: String]) -> some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)

            // Silhouette first; regions paint on top of it.
            context.fill(
                SVGPath.path(from: BodyMapArt.outline, fitting: rect, viewBox: BodyMapArt.viewBox),
                with: .color(Self.outlineColor)
            )

            for (muscle, d) in regions {
                let path = SVGPath.path(from: d, fitting: rect, viewBox: BodyMapArt.viewBox)
                context.fill(path, with: .color(color(for: muscle)))
            }
        }
    }

    // MARK: - Intensity encoding

    private static let outlineColor = Color("Surface2")

    /// Highest share in this workout — intensity is relative to the hardest-hit
    /// region, not absolute. Shares are fractions of total working time, so
    /// across a dozen regions they are all small; scaling against the max is
    /// what makes the ramp legible.
    private var peakShare: Double {
        max(summary.shares.values.max() ?? 0, .leastNonzeroMagnitude)
    }

    /// Four steps, not a continuous ramp: users cannot resolve finer gradations,
    /// and quantizing stops the figure implying a precision the underlying
    /// time model does not have.
    private func step(for muscle: MuscleGroup) -> Int {
        guard let share = summary.shares[muscle], share > 0 else { return 0 }
        let relative = share / peakShare
        switch relative {
        case ..<0.25:  return 1
        case ..<0.50:  return 2
        case ..<0.75:  return 3
        default:       return 4
        }
    }

    /// One hue at varying intensity. Multiple hues would read as unrelated
    /// categories; a red/green ramp would imply a good/bad judgement that does
    /// not exist here.
    private func color(for muscle: MuscleGroup) -> Color {
        switch step(for: muscle) {
        case 1:  return Color("BrandPrimary").opacity(0.28)
        case 2:  return Color("BrandPrimary").opacity(0.50)
        case 3:  return Color("BrandPrimary").opacity(0.75)
        case 4:  return Color("BrandPrimary")
        default: return Self.outlineColor      // present in the art, not worked
        }
    }

    private func intensityWord(for muscle: MuscleGroup) -> String {
        switch step(for: muscle) {
        case 4:  return "worked hard"
        case 3:  return "worked"
        case 2:  return "lightly worked"
        default: return "barely worked"
        }
    }

    // MARK: - Supporting text

    private var topRegionsLabel: some View {
        let top = summary.ranked.prefix(3).map(\.displayName)
        return VStack(alignment: .leading, spacing: 4) {
            Text(summary.regionHeadline)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryText"))
            if !top.isEmpty {
                Text("Mostly \(ListFormatter.localizedString(byJoining: top).lowercased())")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
            }
        }
    }

    private var accessibilityDescription: String {
        guard !summary.isEmpty else { return "Not available for this workout" }
        let parts = summary.ranked.prefix(4).map { "\($0.displayName), \(intensityWord(for: $0))" }
        return "\(summary.regionHeadline). " + parts.joined(separator: ". ")
    }

    // MARK: - Empty state

    /// Reached for ~2 of 9,224 live workouts, but real. Show the plain figure
    /// and say so — never fabricate highlights to fill the card, because users
    /// will believe them.
    private var emptyState: some View {
        VStack(spacing: 10) {
            figure(regions: [:])
                .frame(height: figureHeight)
                .opacity(0.6)
            Text("We couldn't map this one")
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Muscles worked: not available for this workout")
    }
}

// MARK: - Previews

#Preview("Full body") {
    BodyMapView(summary: MuscleSummary(
        shares: [.quads: 0.22, .glutes: 0.18, .shoulders: 0.16, .core: 0.14,
                 .lats: 0.10, .triceps: 0.08, .hamstrings: 0.07, .calves: 0.05],
        region: "full-body"
    ))
    .padding()
}

#Preview("Leg dominant") {
    BodyMapView(summary: MuscleSummary(
        shares: [.quads: 0.40, .glutes: 0.28, .hamstrings: 0.20, .calves: 0.12],
        region: "lower-body"
    ))
    .padding()
}

#Preview("Upper body") {
    BodyMapView(summary: MuscleSummary(
        shares: [.shoulders: 0.34, .triceps: 0.24, .lats: 0.20, .chest: 0.12, .forearms: 0.10],
        region: "upper-body"
    ))
    .padding()
}

#Preview("Single region") {
    BodyMapView(summary: MuscleSummary(shares: [.core: 1.0], region: "full-body"))
        .padding()
}

#Preview("Empty") {
    BodyMapView(summary: .empty)
        .padding()
}

#Preview("Full body — dark") {
    BodyMapView(summary: MuscleSummary(
        shares: [.quads: 0.22, .glutes: 0.18, .shoulders: 0.16, .core: 0.14,
                 .lats: 0.10, .triceps: 0.08, .hamstrings: 0.07, .calves: 0.05],
        region: "full-body"
    ))
    .padding()
    .preferredColorScheme(.dark)
}
