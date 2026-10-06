//
//  OnboardingFlowTests.swift
//  wodAITests
//

import Testing
@testable import wodAI

struct OnboardingFlowTests {
    /// Two ladders: three rungs, then two.
    private func flowAtFirstSkill() -> OnboardingFlow {
        var flow = OnboardingFlow(ladderRungCounts: [3, 2])
        for _ in 0..<5 { flow.advance() } // goal → … → equipment → first question
        return flow
    }

    @Test func walksTheFixedStepsInOrder() {
        var flow = OnboardingFlow(ladderRungCounts: [3])
        var seen = [flow.current]
        for _ in 0..<5 { flow.advance(); seen.append(flow.current) }
        #expect(seen == [.goal, .experience, .schedule, .gym, .equipment, .skill(ladder: 0, rung: 0)])
    }

    @Test func aYesSettlesTheLadderAtThatRung() {
        var flow = flowAtFirstSkill()
        #expect(flow.answerSkill(false) == nil)
        #expect(flow.current == .skill(ladder: 0, rung: 1))
        #expect(flow.answerSkill(true) == SkillLadderResult(ladder: 0, level: 1))
        #expect(flow.current == .skill(ladder: 1, rung: 0))
    }

    @Test func noToEveryRungMeansNone() {
        var flow = flowAtFirstSkill()
        flow.answerSkill(false)
        flow.answerSkill(false)
        #expect(flow.answerSkill(false) == SkillLadderResult(ladder: 0, level: nil))
        #expect(flow.current == .skill(ladder: 1, rung: 0))
    }

    @Test func theLastLadderLeadsToLifts() {
        var flow = flowAtFirstSkill()
        flow.answerSkill(true)
        flow.skipLadder()
        #expect(flow.current == .lifts)
        flow.advance()
        #expect(flow.current == .aboutYou)
        #expect(flow.isLastStep)
    }

    @Test func withoutLaddersEquipmentLeadsToLifts() {
        var flow = OnboardingFlow(ladderRungCounts: [])
        for _ in 0..<5 { flow.advance() }
        #expect(flow.current == .lifts)
    }

    @Test func backRetracesEveryQuestion() {
        var flow = flowAtFirstSkill()
        flow.answerSkill(false)
        flow.answerSkill(true)
        flow.back()
        #expect(flow.current == .skill(ladder: 0, rung: 1))
        flow.back()
        #expect(flow.current == .skill(ladder: 0, rung: 0))
        flow.back()
        #expect(flow.current == .equipment)
    }

    @Test func cannotGoBackFromTheFirstStep() {
        var flow = OnboardingFlow(ladderRungCounts: [3])
        #expect(!flow.canGoBack)
        flow.back()
        #expect(flow.current == .goal)
    }

    @Test func progressRisesSteadilyToOne() {
        var flow = flowAtFirstSkill()
        var values = [flow.progress]
        flow.answerSkill(false); values.append(flow.progress)
        flow.answerSkill(true); values.append(flow.progress)
        flow.answerSkill(true); values.append(flow.progress)
        flow.advance(); values.append(flow.progress)
        #expect(zip(values, values.dropFirst()).allSatisfy { $0 < $1 })
        #expect(values.last == 1)
        // 5 fixed steps + 2 ladders + 2 closing steps = 9 pages.
        #expect(OnboardingFlow(ladderRungCounts: [3, 2]).progress == 1.0 / 9)
    }
}
