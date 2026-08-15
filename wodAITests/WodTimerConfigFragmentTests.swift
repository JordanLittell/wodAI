//
//  WodTimerConfigFragmentTests.swift
//  wodAITests
//
//  Coverage for `WodTimerConfig(fragment:)` — the bridge from a backend timing
//  scheme onto the engine model. The backend config is a v1/v2 union: v1 carries
//  compact `segments` (with a `rounds` multiplier), v2 carries a flat, fully
//  expanded `phases` list. Exactly one is ever populated.
//

import Testing
import Foundation
import ApolloAPI
import WodAiAPI
@testable import wodAI

// MARK: - Stubs

private struct StubPhase: TimingPhaseFragment {
    var durationSeconds: Int?
    var direction: GraphQLEnum<WodAiAPI.PhaseDirection>
    var label: String?

    static func down(_ seconds: Int?, _ label: String? = nil) -> StubPhase {
        StubPhase(durationSeconds: seconds, direction: GraphQLEnum(.down), label: label)
    }

    static func up(_ seconds: Int?, _ label: String? = nil) -> StubPhase {
        StubPhase(durationSeconds: seconds, direction: GraphQLEnum(.up), label: label)
    }
}

private struct StubSegment: TimingSegmentFragment {
    var rounds: Int
    var phases: [StubPhase]
}

private struct StubScheme: TimingSchemeFragment {
    var version: Int
    var segments: [StubSegment]?
    var phases: [StubPhase]?

    static func v1(_ segments: [StubSegment]) -> StubScheme {
        StubScheme(version: 1, segments: segments, phases: nil)
    }

    static func v2(_ phases: [StubPhase]) -> StubScheme {
        StubScheme(version: 2, segments: nil, phases: phases)
    }
}

struct WodTimerConfigFragmentTests {

    // MARK: - v1 (compact segments)

    @Test func v1SegmentsExpandIntoRounds() throws {
        // Tabata: 8 x (20s work / 10s rest).
        let fragment = StubScheme.v1([
            StubSegment(rounds: 8, phases: [.down(20, "Work"), .down(10, "Rest")])
        ])
        let config = try #require(WodTimerConfig(fragment: fragment))

        #expect(config.totalRounds == 8)

        let start = config.readout(atElapsed: 0)
        #expect(start.roundNumber == 1)
        #expect(start.phaseLabel == "Work")
        #expect(start.displaySeconds == 20)

        // 25s in: 5s into round 1's rest.
        let rest = config.readout(atElapsed: 25)
        #expect(rest.phaseLabel == "Rest")
        #expect(rest.displaySeconds == 5)

        // Round 2 starts at 30s; the whole thing is 8 * 30 = 240s.
        #expect(config.readout(atElapsed: 30).roundNumber == 2)
        #expect(config.readout(atElapsed: 239).isComplete == false)
        #expect(config.readout(atElapsed: 240).isComplete == true)
    }

    @Test func v1PreservesOpenEndedCountUp() throws {
        // A capless "For Time": one open-ended count-up phase.
        let fragment = StubScheme.v1([StubSegment(rounds: 1, phases: [.up(nil)])])
        let config = try #require(WodTimerConfig(fragment: fragment))

        #expect(config.readout(atElapsed: 5000).displaySeconds == 5000)
        #expect(config.readout(atElapsed: 5000).isComplete == false)
    }

    @Test func v1MultipleSegmentsRunInOrder() throws {
        // 3:00 buy-in, then 2 x 1:00 rounds.
        let fragment = StubScheme.v1([
            StubSegment(rounds: 1, phases: [.down(180, "Buy-in")]),
            StubSegment(rounds: 2, phases: [.down(60, "Round")])
        ])
        let config = try #require(WodTimerConfig(fragment: fragment))

        #expect(config.totalRounds == 3)
        #expect(config.readout(atElapsed: 0).phaseLabel == "Buy-in")
        #expect(config.readout(atElapsed: 180).phaseLabel == "Round")
        #expect(config.readout(atElapsed: 180).roundNumber == 2)
        #expect(config.readout(atElapsed: 300).isComplete == true)
    }

    // MARK: - v2 (flat, fully expanded phases)

    @Test func v2FlatPhasesWalkInOrderAsOneRound() throws {
        // A compound workout: 20s of burpees, 10s rest, 30s of wall balls.
        let fragment = StubScheme.v2([
            .down(20, "Burpees"),
            .down(10, "Rest"),
            .down(30, "Wall Balls")
        ])
        let config = try #require(WodTimerConfig(fragment: fragment))

        // v2 is already expanded — one pass, so the round counter stays hidden
        // (WodTimerView only renders it when totalRounds > 1).
        #expect(config.totalRounds == 1)

        let first = config.readout(atElapsed: 0)
        #expect(first.phaseLabel == "Burpees")
        #expect(first.displaySeconds == 20)

        #expect(config.readout(atElapsed: 20).phaseLabel == "Rest")
        #expect(config.readout(atElapsed: 25).displaySeconds == 5)

        let third = config.readout(atElapsed: 30)
        #expect(third.phaseLabel == "Wall Balls")
        #expect(third.displaySeconds == 30)

        // Total = 20 + 10 + 30 = 60s; complete exactly at the boundary.
        #expect(config.readout(atElapsed: 59).isComplete == false)
        #expect(config.readout(atElapsed: 60).isComplete == true)
    }

    @Test func v2SinglePhaseOpenEnded() throws {
        let fragment = StubScheme.v2([.up(nil, "For Time")])
        let config = try #require(WodTimerConfig(fragment: fragment))

        #expect(config.totalRounds == 1)
        #expect(config.readout(atElapsed: 900).displaySeconds == 900)
        #expect(config.readout(atElapsed: 900).isComplete == false)
    }

    // MARK: - Degenerate configs fall back

    @Test func nilOrEmptyConfigReturnsNil() {
        // Neither shape populated — a malformed blob, or a version this client
        // doesn't understand. Must return nil so `activeConfig` falls back to
        // `.fallback(timeCap:)`; an empty segment list would read as an
        // already-complete workout the instant the user pressed start.
        #expect(WodTimerConfig(fragment: StubScheme(version: 1, segments: nil, phases: nil)) == nil)
        #expect(WodTimerConfig(fragment: StubScheme(version: 1, segments: [], phases: nil)) == nil)
        #expect(WodTimerConfig(fragment: StubScheme(version: 2, segments: nil, phases: [])) == nil)
        #expect(WodTimerConfig(fragment: StubScheme(version: 3, segments: [], phases: [])) == nil)
    }

    @Test func segmentsWinWhenBothArePresent() throws {
        // The backend guarantees exactly one shape, but pin the precedence so a
        // sloppy payload still produces the richer v1 reading.
        let fragment = StubScheme(
            version: 1,
            segments: [StubSegment(rounds: 4, phases: [.down(60, "Segment")])],
            phases: [.down(10, "Phase")]
        )
        let config = try #require(WodTimerConfig(fragment: fragment))

        #expect(config.totalRounds == 4)
        #expect(config.readout(atElapsed: 0).phaseLabel == "Segment")
    }
}
