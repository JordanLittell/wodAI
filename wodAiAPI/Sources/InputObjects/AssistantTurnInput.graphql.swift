// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct AssistantTurnInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    flow: GraphQLNullable<String> = nil,
    messages: [WodAiAPI.AssistantMessageInput],
    timezone: String,
    conversationId: GraphQLNullable<WodAiAPI.ID> = nil
  ) {
    __data = InputDict([
      "flow": flow,
      "messages": messages,
      "timezone": timezone,
      "conversationId": conversationId
    ])
  }

  public var flow: GraphQLNullable<String> {
    get { __data["flow"] }
    set { __data["flow"] = newValue }
  }

  public var messages: [WodAiAPI.AssistantMessageInput] {
    get { __data["messages"] }
    set { __data["messages"] = newValue }
  }

  public var timezone: String {
    get { __data["timezone"] }
    set { __data["timezone"] = newValue }
  }

  public var conversationId: GraphQLNullable<WodAiAPI.ID> {
    get { __data["conversationId"] }
    set { __data["conversationId"] = newValue }
  }
}
