// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct StrengthComponentResultInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    id: Int,
    reps: Int,
    weight: GraphQLNullable<Double> = nil,
    rpe: GraphQLNullable<Int> = nil
  ) {
    __data = InputDict([
      "id": id,
      "reps": reps,
      "weight": weight,
      "rpe": rpe
    ])
  }

  public var id: Int {
    get { __data["id"] }
    set { __data["id"] = newValue }
  }

  public var reps: Int {
    get { __data["reps"] }
    set { __data["reps"] = newValue }
  }

  public var weight: GraphQLNullable<Double> {
    get { __data["weight"] }
    set { __data["weight"] = newValue }
  }

  public var rpe: GraphQLNullable<Int> {
    get { __data["rpe"] }
    set { __data["rpe"] = newValue }
  }
}
