// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct CreateWodInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    description: GraphQLNullable<String> = nil,
    loadParams: GraphQLNullable<LoadParams> = nil
  ) {
    __data = InputDict([
      "description": description,
      "loadParams": loadParams
    ])
  }

  public var description: GraphQLNullable<String> {
    get { __data["description"] }
    set { __data["description"] = newValue }
  }

  public var loadParams: GraphQLNullable<LoadParams> {
    get { __data["loadParams"] }
    set { __data["loadParams"] = newValue }
  }
}
