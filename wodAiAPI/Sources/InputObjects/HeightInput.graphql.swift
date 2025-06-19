// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct HeightInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    value: Double,
    unit: GraphQLEnum<WodAiAPI.HeightUnit>
  ) {
    __data = InputDict([
      "value": value,
      "unit": unit
    ])
  }

  public var value: Double {
    get { __data["value"] }
    set { __data["value"] = newValue }
  }

  public var unit: GraphQLEnum<WodAiAPI.HeightUnit> {
    get { __data["unit"] }
    set { __data["unit"] = newValue }
  }
}
