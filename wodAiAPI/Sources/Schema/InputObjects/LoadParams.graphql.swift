// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct LoadParams: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    weight: GraphQLNullable<Int> = nil,
    volume: GraphQLNullable<Int> = nil,
    skill: GraphQLNullable<Int> = nil
  ) {
    __data = InputDict([
      "weight": weight,
      "volume": volume,
      "skill": skill
    ])
  }

  public var weight: GraphQLNullable<Int> {
    get { __data["weight"] }
    set { __data["weight"] = newValue }
  }

  public var volume: GraphQLNullable<Int> {
    get { __data["volume"] }
    set { __data["volume"] = newValue }
  }

  public var skill: GraphQLNullable<Int> {
    get { __data["skill"] }
    set { __data["skill"] = newValue }
  }
}
