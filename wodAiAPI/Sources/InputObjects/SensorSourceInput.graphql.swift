// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct SensorSourceInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    kind: String,
    deviceName: GraphQLNullable<String> = nil,
    brand: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "kind": kind,
      "deviceName": deviceName,
      "brand": brand
    ])
  }

  public var kind: String {
    get { __data["kind"] }
    set { __data["kind"] = newValue }
  }

  public var deviceName: GraphQLNullable<String> {
    get { __data["deviceName"] }
    set { __data["deviceName"] = newValue }
  }

  public var brand: GraphQLNullable<String> {
    get { __data["brand"] }
    set { __data["brand"] = newValue }
  }
}
