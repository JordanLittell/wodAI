// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct BenchmarkInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    type: String,
    value: Double,
    unit: String
  ) {
    __data = InputDict([
      "type": type,
      "value": value,
      "unit": unit
    ])
  }

  public var type: String {
    get { __data["type"] }
    set { __data["type"] = newValue }
  }

  public var value: Double {
    get { __data["value"] }
    set { __data["value"] = newValue }
  }

  public var unit: String {
    get { __data["unit"] }
    set { __data["unit"] = newValue }
  }
}
