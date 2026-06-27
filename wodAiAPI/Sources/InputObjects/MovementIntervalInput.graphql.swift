// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct MovementIntervalInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    movement: String,
    startTimestamp: Double,
    endTimestamp: Double,
    repCount: GraphQLNullable<Int> = nil,
    avgHeartRate: GraphQLNullable<Double> = nil,
    peakAcceleration: GraphQLNullable<Double> = nil,
    confidence: GraphQLNullable<Double> = nil
  ) {
    __data = InputDict([
      "movement": movement,
      "startTimestamp": startTimestamp,
      "endTimestamp": endTimestamp,
      "repCount": repCount,
      "avgHeartRate": avgHeartRate,
      "peakAcceleration": peakAcceleration,
      "confidence": confidence
    ])
  }

  public var movement: String {
    get { __data["movement"] }
    set { __data["movement"] = newValue }
  }

  public var startTimestamp: Double {
    get { __data["startTimestamp"] }
    set { __data["startTimestamp"] = newValue }
  }

  public var endTimestamp: Double {
    get { __data["endTimestamp"] }
    set { __data["endTimestamp"] = newValue }
  }

  public var repCount: GraphQLNullable<Int> {
    get { __data["repCount"] }
    set { __data["repCount"] = newValue }
  }

  public var avgHeartRate: GraphQLNullable<Double> {
    get { __data["avgHeartRate"] }
    set { __data["avgHeartRate"] = newValue }
  }

  public var peakAcceleration: GraphQLNullable<Double> {
    get { __data["peakAcceleration"] }
    set { __data["peakAcceleration"] = newValue }
  }

  public var confidence: GraphQLNullable<Double> {
    get { __data["confidence"] }
    set { __data["confidence"] = newValue }
  }
}
