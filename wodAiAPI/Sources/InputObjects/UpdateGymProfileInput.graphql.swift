// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct UpdateGymProfileInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    name: GraphQLNullable<String> = nil,
    equipmentIds: GraphQLNullable<[Int]> = nil
  ) {
    __data = InputDict([
      "name": name,
      "equipmentIds": equipmentIds
    ])
  }

  public var name: GraphQLNullable<String> {
    get { __data["name"] }
    set { __data["name"] = newValue }
  }

  public var equipmentIds: GraphQLNullable<[Int]> {
    get { __data["equipmentIds"] }
    set { __data["equipmentIds"] = newValue }
  }
}
