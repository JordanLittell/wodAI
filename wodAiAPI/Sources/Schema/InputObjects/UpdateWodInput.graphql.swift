// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct UpdateWodInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    id: GraphQLNullable<String> = nil,
    instructions: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "id": id,
      "instructions": instructions
    ])
  }

  public var id: GraphQLNullable<String> {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var instructions: GraphQLNullable<String> {
    get { __data["instructions"] }
    set { __data["instructions"] = newValue }
  }
}
