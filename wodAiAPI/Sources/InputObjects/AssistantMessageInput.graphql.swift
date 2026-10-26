// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct AssistantMessageInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    role: GraphQLEnum<WodAiAPI.AssistantRole>,
    text: String
  ) {
    __data = InputDict([
      "role": role,
      "text": text
    ])
  }

  public var role: GraphQLEnum<WodAiAPI.AssistantRole> {
    get { __data["role"] }
    set { __data["role"] = newValue }
  }

  public var text: String {
    get { __data["text"] }
    set { __data["text"] = newValue }
  }
}
