// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension Unions {
  static let WorkoutGenerationEvent = Union(
    name: "WorkoutGenerationEvent",
    possibleTypes: [
      Objects.GenerationSession.self,
      Objects.GenerationStrengthBlock.self,
      Objects.GenerationStrengthSet.self,
      Objects.GenerationHiitBlock.self,
      Objects.GenerationDraftHiitBlock.self,
      Objects.GenerationComplete.self,
      Objects.GenerationFailed.self
    ]
  )
}