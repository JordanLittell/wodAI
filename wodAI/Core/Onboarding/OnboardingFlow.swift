//
//  OnboardingFlow.swift
//  wodAI
//
//  Where a new athlete is in onboarding, and where each answer takes them.
//  Apollo-free so the navigation and progress math are unit-testable
//  (wodAITests/OnboardingFlowTests.swift).
//
//  Skill questions come from the backend as ladders, each ordered hardest
//  first. The athlete is asked down a ladder until their first yes, and that
//  rung is their level; "no" to every rung means none of them.
//

import Foundation

enum OnboardingStep: Hashable {
    case goal
    case experience
    case schedule
    case gym
    case equipment
    /// One question: rung `rung` of ladder `ladder`.
    case skill(ladder: Int, rung: Int)
    case lifts
    case aboutYou
}

/// A finished ladder: the hardest rung the athlete can do, or nil for none.
struct SkillLadderResult: Equatable {
    let ladder: Int
    let level: Int?
}

struct OnboardingFlow {
    /// How many rungs each skill ladder has, in the order they're asked.
    let ladderRungCounts: [Int]
    /// Every step shown so far; Back pops it, so re-answering a skill question
    /// simply replaces the earlier answer.
    private(set) var path: [OnboardingStep] = [.goal]

    init(ladderRungCounts: [Int]) {
        self.ladderRungCounts = ladderRungCounts.filter { $0 > 0 }
    }

    var current: OnboardingStep { path[path.count - 1] }
    var canGoBack: Bool { path.count > 1 }
    var isLastStep: Bool { current == .aboutYou }

    mutating func back() {
        if canGoBack { path.removeLast() }
    }

    /// Moves past any step that isn't a skill question.
    mutating func advance() {
        guard let next = step(after: current) else { return }
        path.append(next)
    }

    /// Answers the current skill question. Returns the ladder's result once the
    /// answer settles it (a yes, or a no on its last rung), else nil.
    @discardableResult
    mutating func answerSkill(_ yes: Bool) -> SkillLadderResult? {
        guard case let .skill(ladder, rung) = current else { return nil }
        let isLastRung = rung == ladderRungCounts[ladder] - 1
        if !yes && !isLastRung {
            path.append(.skill(ladder: ladder, rung: rung + 1))
            return nil
        }
        path.append(firstStep(fromLadder: ladder + 1))
        return SkillLadderResult(ladder: ladder, level: yes ? rung : nil)
    }

    /// Leaves the current ladder unanswered.
    mutating func skipLadder() {
        guard case let .skill(ladder, _) = current else { return }
        path.append(firstStep(fromLadder: ladder + 1))
    }

    /// 0...1 for the progress bar. Each step, and each ladder, is one page; a
    /// ladder fills its page as the athlete works down its rungs.
    var progress: Double {
        let pages = Double(Self.leadingSteps.count + ladderRungCounts.count + Self.trailingSteps.count)
        let position: Double
        switch current {
        case let .skill(ladder, rung):
            position = Double(Self.leadingSteps.count + ladder) + Double(rung) / Double(ladderRungCounts[ladder])
        default:
            if let i = Self.leadingSteps.firstIndex(of: current) {
                position = Double(i)
            } else {
                position = Double(Self.leadingSteps.count + ladderRungCounts.count
                    + (Self.trailingSteps.firstIndex(of: current) ?? 0))
            }
        }
        return (position + 1) / pages
    }

    // MARK: - Order

    private static let leadingSteps: [OnboardingStep] = [.goal, .experience, .schedule, .gym, .equipment]
    private static let trailingSteps: [OnboardingStep] = [.lifts, .aboutYou]

    private func step(after step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .equipment:
            return firstStep(fromLadder: 0)
        case .skill:
            return nil // answered with answerSkill / skipLadder
        default:
            let order = Self.leadingSteps + Self.trailingSteps
            guard let i = order.firstIndex(of: step), i + 1 < order.count else { return nil }
            return order[i + 1]
        }
    }

    private func firstStep(fromLadder ladder: Int) -> OnboardingStep {
        ladder < ladderRungCounts.count ? .skill(ladder: ladder, rung: 0) : .lifts
    }
}
