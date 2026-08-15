//
//  BodyMapTests.swift
//  wodAITests
//
//  Coverage for the two pieces of the body map that carry real logic: the SVG
//  path parser (which makes the artwork swappable data) and the muscle
//  vocabulary's contract with the server.
//

import Testing
import Foundation
import CoreGraphics
@testable import wodAI

struct SVGPathTests {

    private let box = CGSize(width: 100, height: 220)

    @Test func parsesAbsolutePolygon() {
        let path = SVGPath.parse("M10,20 L30,20 L30,40 L10,40 Z")
        #expect(!path.isEmpty)
        #expect(path.boundingRect == CGRect(x: 10, y: 20, width: 20, height: 20))
    }

    @Test func parsesRelativeCommands() {
        // Same square as above, expressed relatively.
        let path = SVGPath.parse("m10,20 l20,0 l0,20 l-20,0 z")
        #expect(path.boundingRect == CGRect(x: 10, y: 20, width: 20, height: 20))
    }

    @Test func treatsExtraPairsAfterMoveAsLines() {
        // SVG says trailing coordinate pairs after a moveto are implicit
        // linetos — without that the shape collapses to a point.
        let path = SVGPath.parse("M0,0 10,0 10,10 0,10 Z")
        #expect(path.boundingRect == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func supportsHorizontalAndVerticalShorthand() {
        let path = SVGPath.parse("M5,5 H25 V25 H5 Z")
        #expect(path.boundingRect == CGRect(x: 5, y: 5, width: 20, height: 20))
    }

    @Test func parsesMultipleSubpaths() {
        // Left/right muscle pairs are one path with two subpaths.
        let path = SVGPath.parse("M0,0 L10,0 L10,10 Z M90,0 L100,0 L100,10 Z")
        #expect(path.boundingRect.minX == 0)
        #expect(path.boundingRect.maxX == 100)
    }

    @Test func handlesNegativeNumbersWithoutSeparators() {
        let path = SVGPath.parse("M0,0L-10-10Z")
        #expect(path.boundingRect.minX == -10)
        #expect(path.boundingRect.minY == -10)
    }

    @Test func malformedInputLosesTheRegionRatherThanCrashing() {
        // A truncated command must not trap — one bad region should cost that
        // region, not the whole completion screen.
        #expect(SVGPath.parse("M10,10 L").isEmpty == false)
        #expect(SVGPath.parse("").isEmpty)
        #expect(SVGPath.parse("garbage").isEmpty)
    }

    @Test func scalesToFitPreservingAspectRatio() {
        // A full-viewBox square scaled into a wider rect should be centred
        // horizontally, not stretched.
        let rect = CGRect(x: 0, y: 0, width: 200, height: 220)
        let path = SVGPath.path(from: "M0,0 H100 V220 H0 Z", fitting: rect, viewBox: box)
        let bounds = path.boundingRect
        #expect(abs(bounds.height - 220) < 0.01)
        #expect(abs(bounds.width - 100) < 0.01)
        #expect(abs(bounds.minX - 50) < 0.01)   // centred
    }
}

struct MuscleGroupTests {

    @Test func slugsMatchTheServerVocabulary() {
        // These raw values are the API contract (WorkoutMuscleSummary.muscle).
        // Changing one silently drops that region from every body map.
        #expect(MuscleGroup(rawValue: "hip-flexors") == .hipFlexors)
        #expect(MuscleGroup(rawValue: "quads") == .quads)
        #expect(MuscleGroup(rawValue: "traps") == .traps)
    }

    @Test func unknownSlugDecodesToNilRatherThanFailing() {
        // A vocabulary term added server-side must not break an older client.
        #expect(MuscleGroup(rawValue: "full-body") == nil)
        #expect(MuscleGroup(rawValue: "cardiovascular") == nil)
    }

    @Test func everyRegionIsDrawableOnAtLeastOneFigure() {
        // The vocabulary's defining constraint: a term that cannot be drawn
        // does not belong in it.
        for muscle in MuscleGroup.allCases {
            let drawable = BodyMapArt.front[muscle] != nil || BodyMapArt.back[muscle] != nil
            #expect(drawable, "\(muscle.rawValue) has no path on either figure")
        }
    }

    @Test func everyRegionHasAJargonFreeLabel() {
        for muscle in MuscleGroup.allCases {
            #expect(!muscle.displayName.isEmpty)
            #expect(muscle.displayName != muscle.rawValue)
        }
    }

    @Test func artworkPathsAllParse() {
        for (muscle, d) in BodyMapArt.front.merging(BodyMapArt.back, uniquingKeysWith: { a, _ in a }) {
            #expect(!SVGPath.parse(d).isEmpty, "\(muscle.rawValue) produced an empty path")
        }
        #expect(!SVGPath.parse(BodyMapArt.outline).isEmpty)
    }
}

struct MuscleSummaryTests {

    @Test func ranksRegionsByShareDescending() {
        let summary = MuscleSummary(
            shares: [.core: 0.1, .quads: 0.5, .glutes: 0.3],
            region: "lower-body"
        )
        #expect(summary.ranked == [.quads, .glutes, .core])
    }

    @Test func rankingIsStableForTiedShares() {
        // Dictionary order is not deterministic, so ties must break on slug or
        // the label reshuffles between renders.
        let summary = MuscleSummary(shares: [.quads: 0.5, .glutes: 0.5], region: nil)
        #expect(summary.ranked == [.glutes, .quads])
    }

    @Test func headlineIsPlainEnglish() {
        #expect(MuscleSummary(shares: [:], region: "full-body").regionHeadline == "Full body workout")
        #expect(MuscleSummary(shares: [:], region: "upper-body").regionHeadline == "Upper body workout")
        // Unknown/absent region must still produce something showable.
        #expect(MuscleSummary(shares: [:], region: nil).regionHeadline == "Muscles worked")
        #expect(MuscleSummary(shares: [:], region: "something-new").regionHeadline == "Muscles worked")
    }

    @Test func emptySummaryIsEmpty() {
        #expect(MuscleSummary.empty.isEmpty)
        #expect(MuscleSummary(shares: [.core: 1.0], region: nil).isEmpty == false)
    }
}
