//
//  WodTimerEngineTests.swift
//  wodAITests
//
//  Unit coverage for the abstract WOD timer engine's readout logic.
//

import Testing
import Foundation
@testable import wodAI

struct WodTimerEngineTests {

    // MARK: - For Time (open-ended count-up)

    @Test func openEndedCountUpNeverCompletes() {
        let config = WodTimerConfig.forTime(timeCap: nil)
        let start = config.readout(atElapsed: 0)
        #expect(start.displaySeconds == 0)
        #expect(start.totalRounds == 1)
        #expect(start.isComplete == false)

        let later = config.readout(atElapsed: 5000)
        #expect(later.displaySeconds == 5000)
        #expect(later.isComplete == false)
    }

    // MARK: - For Time capped / AMRAP (countdown)

    @Test func cappedCountdownRemainingAndCompletion() {
        let config = WodTimerConfig.forTime(timeCap: 1200) // 20:00
        #expect(config.readout(atElapsed: 0).displaySeconds == 1200)
        #expect(config.readout(atElapsed: 300).displaySeconds == 900)
        // Exactly at the cap: complete.
        #expect(config.readout(atElapsed: 1200).isComplete == true)
        #expect(config.readout(atElapsed: 1500).isComplete == true)
        // Just before the cap: not complete, 1s remaining.
        let almost = config.readout(atElapsed: 1199)
        #expect(almost.isComplete == false)
        #expect(almost.displaySeconds == 1)
    }

    // MARK: - Tabata (multi-round, multi-phase)

    private var tabata: WodTimerConfig {
        WodTimerConfig(segments: [
            TimerSegment(rounds: 8, phases: [
                TimerPhase(duration: 20, direction: .down, label: "Work"),
                TimerPhase(duration: 10, direction: .down, label: "Rest")
            ])
        ])
    }

    @Test func tabataRoundAndPhaseProgression() {
        // t=0: round 1, Work, 20s remaining.
        let r0 = tabata.readout(atElapsed: 0)
        #expect(r0.roundNumber == 1)
        #expect(r0.totalRounds == 8)
        #expect(r0.phaseLabel == "Work")
        #expect(r0.displaySeconds == 20)

        // t=25: 5s into the Rest phase of round 1 -> 5s remaining.
        let r1 = tabata.readout(atElapsed: 25)
        #expect(r1.roundNumber == 1)
        #expect(r1.phaseLabel == "Rest")
        #expect(r1.displaySeconds == 5)

        // t=30: start of round 2 (each round is 30s).
        let r2 = tabata.readout(atElapsed: 30)
        #expect(r2.roundNumber == 2)
        #expect(r2.phaseLabel == "Work")
        #expect(r2.displaySeconds == 20)

        // t=90: into round 4's Work phase.
        let r4 = tabata.readout(atElapsed: 90)
        #expect(r4.roundNumber == 4)
        #expect(r4.phaseLabel == "Work")

        // Total duration = 8 * 30 = 240s -> complete.
        #expect(tabata.readout(atElapsed: 240).isComplete == true)
        #expect(tabata.readout(atElapsed: 239).isComplete == false)
    }

    // MARK: - Multi-AMRAP with rest (multiple rounds, mixed count)

    @Test func multiAmrapWithRest() {
        // 3 x (5:00 AMRAP + 2:00 rest) = 3 rounds of [300 down, 120 down].
        let config = WodTimerConfig(segments: [
            TimerSegment(rounds: 3, phases: [
                TimerPhase(duration: 300, direction: .down, label: "AMRAP"),
                TimerPhase(duration: 120, direction: .down, label: "Rest")
            ])
        ])
        #expect(config.totalRounds == 3)

        // Round 1 AMRAP.
        #expect(config.readout(atElapsed: 0).phaseLabel == "AMRAP")
        // 350s in: round 1 rest (300..420), 50s into the 120s rest -> 70s remaining.
        let rest1 = config.readout(atElapsed: 350)
        #expect(rest1.roundNumber == 1)
        #expect(rest1.phaseLabel == "Rest")
        #expect(rest1.displaySeconds == 70)
        // 420s in: round 2 AMRAP begins.
        #expect(config.readout(atElapsed: 420).roundNumber == 2)
        // Total = 3 * 420 = 1260 -> complete.
        #expect(config.readout(atElapsed: 1260).isComplete == true)
    }

    // MARK: - EMOM

    @Test func emomRounds() {
        // 30-minute EMOM = 30 rounds of one 60s down phase.
        let config = WodTimerConfig(segments: [
            TimerSegment(rounds: 30, phases: [
                TimerPhase(duration: 60, direction: .down, label: nil)
            ])
        ])
        #expect(config.totalRounds == 30)
        #expect(config.readout(atElapsed: 0).roundNumber == 1)
        #expect(config.readout(atElapsed: 60).roundNumber == 2)
        #expect(config.readout(atElapsed: 125).roundNumber == 3)
        #expect(config.readout(atElapsed: 1800).isComplete == true)
    }

    // MARK: - Hour-long phase detection

    @Test func hasHourLongPhase() {
        #expect(WodTimerConfig.forTime(timeCap: 3600).hasHourLongPhase == true)
        #expect(WodTimerConfig.forTime(timeCap: 1800).hasHourLongPhase == false)
        #expect(WodTimerConfig.forTime(timeCap: nil).hasHourLongPhase == false)
    }

    // MARK: - Count-up within a bounded phase

    @Test func boundedCountUpShowsElapsed() {
        let config = WodTimerConfig(segments: [
            TimerSegment(rounds: 1, phases: [
                TimerPhase(duration: 600, direction: .up, label: nil)
            ])
        ])
        #expect(config.readout(atElapsed: 0).displaySeconds == 0)
        #expect(config.readout(atElapsed: 120).displaySeconds == 120)
        #expect(config.readout(atElapsed: 600).isComplete == true)
    }

    // MARK: - Fallback

    @Test func fallbackWithoutSchemeUsesCap() {
        #expect(WodTimerConfig.fallback(timeCap: 900).readout(atElapsed: 0).displaySeconds == 900)
        #expect(WodTimerConfig.fallback(timeCap: nil).readout(atElapsed: 100).displaySeconds == 100)
    }
}
