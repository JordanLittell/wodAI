//
//  GenerationProgressTests.swift
//  wodAITests
//
//  Coverage for folding streamed generation events into the session the
//  Assistant renders, and for the subscription socket's URL.
//

import Testing
import Foundation
@testable import wodAI

struct GenerationProgressTests {

    private func set(_ order: Int, reps: Int = 5, weight: Double? = nil) -> StrengthComponent {
        StrengthComponent(order: order, reps: reps, weight: weight, rpe: nil, exercise: ExerciseName(name: "Back Squat"))
    }

    private func hiit(id: Int) -> HIITWorkoutItem {
        HIITWorkoutItem(
            id: id,
            format: "AMRAP 12",
            displayText: "12 Cal Row",
            stimulus: "Steady.",
            constraintType: "time",
            constraintMagnitude: 720,
            timeCap: 720,
            timingScheme: nil,
            tags: []
        )
    }

    private func strengthSets(_ block: AssistantBlock) -> [StrengthComponent]? {
        if case let .strength(workout) = block.kind { return workout.components }
        return nil
    }

    @Test func nothingToShowBeforeTheHeader() {
        var progress = GenerationProgress()
        progress.apply(.strengthBlock(order: 0, name: "Back Squat", instructions: "Rest 2 min."))
        #expect(progress.session == nil)
    }

    @Test func showsTheHeaderAloneFirst() {
        var progress = GenerationProgress()
        progress.apply(.session(name: "Legs", description: "Squats.", stimulus: "Strength."))
        #expect(progress.session?.name == "Legs")
        #expect(progress.session?.stimulus == "Strength.")
        #expect(progress.session?.blocks.isEmpty == true)
    }

    @Test func fillsStrengthBlocksSetBySet() {
        var progress = GenerationProgress()
        progress.apply(.session(name: "Legs", description: "Squats.", stimulus: "Strength."))
        progress.apply(.strengthBlock(order: 0, name: "Back Squat", instructions: "Rest 2 min."))
        #expect(progress.session.flatMap { strengthSets($0.blocks[0]) }?.isEmpty == true)

        progress.apply(.strengthSet(order: 0, component: set(0, weight: 185)))
        progress.apply(.strengthSet(order: 0, component: set(1, weight: 195)))
        let sets = progress.session.flatMap { strengthSets($0.blocks[0]) }
        #expect(sets?.map(\.weight) == [185, 195])
    }

    @Test func ordersBlocksBySessionOrderAndLettersThem() {
        var progress = GenerationProgress()
        progress.apply(.session(name: "Legs", description: "Squats.", stimulus: "Strength."))
        progress.apply(.hiitBlock(order: 1, name: "Metcon", workout: hiit(id: 7)))
        progress.apply(.strengthBlock(order: 0, name: "Back Squat", instructions: "Rest 2 min."))

        let blocks = progress.session?.blocks ?? []
        #expect(blocks.map(\.id) == [0, 1])
        #expect(blocks.map(\.letter) == ["A", "B"])
        #expect(blocks.map(\.label) == ["Back Squat", "Metcon"])
    }

    @Test func ignoresASetForABlockItHasNotSeen() {
        var progress = GenerationProgress()
        progress.apply(.session(name: "Legs", description: "Squats.", stimulus: "Strength."))
        progress.apply(.strengthSet(order: 3, component: set(0)))
        #expect(progress.session?.blocks.isEmpty == true)
    }

    @Test func aSecondHeaderRestartsTheSession() {
        var progress = GenerationProgress()
        progress.apply(.session(name: "First", description: "A.", stimulus: "A."))
        progress.apply(.hiitBlock(order: 0, name: "Metcon", workout: hiit(id: 7)))
        progress.apply(.session(name: "Second", description: "B.", stimulus: "B."))

        #expect(progress.session?.name == "Second")
        #expect(progress.session?.blocks.isEmpty == true)
    }

    @Test func theSavedSessionReplacesTheStreamedOne() {
        var progress = GenerationProgress()
        progress.apply(.session(name: "Streamed", description: "A.", stimulus: "A."))
        progress.apply(.hiitBlock(order: 0, name: "Metcon", workout: hiit(id: 7)))
        #expect(!progress.isComplete)

        let saved = AssistantSession(
            name: "Saved", description: "A.", stimulus: "A.", coaching: "Go.", scheduledDate: nil, blocks: []
        )
        progress.apply(.complete(saved))
        #expect(progress.isComplete)
        #expect(progress.session?.name == "Saved")
        #expect(progress.session?.coaching == "Go.")
    }
}

struct WebSocketURLTests {
    @Test func usesWsForHttp() {
        let url = Network.webSocketURL(for: URL(string: "http://localhost:3000/graphql")!)
        #expect(url.absoluteString == "ws://localhost:3000/graphql")
    }

    @Test func usesWssForHttps() {
        let url = Network.webSocketURL(for: URL(string: "https://move-adapt.com/graphql")!)
        #expect(url.absoluteString == "wss://move-adapt.com/graphql")
    }

    @Test func sendsTheTokenAsABearerAuthorization() {
        let payload = Network.connectingPayload(token: "abc")
        #expect(payload["Authorization"] as? String == "Bearer abc")
        #expect(Network.connectingPayload(token: nil).isEmpty)
    }
}
