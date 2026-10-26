// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension Unions {
  static let AssistantTurnEvent = Union(
    name: "AssistantTurnEvent",
    possibleTypes: [
      Objects.AssistantTextDelta.self,
      Objects.AssistantSuggestions.self,
      Objects.AssistantAction.self,
      Objects.AssistantTurnComplete.self,
      Objects.GenerationFailed.self
    ]
  )
}