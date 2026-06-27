// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct SensorFrameInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    timestamp: Double,
    accelX: GraphQLNullable<Double> = nil,
    accelY: GraphQLNullable<Double> = nil,
    accelZ: GraphQLNullable<Double> = nil,
    gyroX: GraphQLNullable<Double> = nil,
    gyroY: GraphQLNullable<Double> = nil,
    gyroZ: GraphQLNullable<Double> = nil,
    heartRate: GraphQLNullable<Double> = nil,
    relativeAltitude: GraphQLNullable<Double> = nil,
    lat: GraphQLNullable<Double> = nil,
    lng: GraphQLNullable<Double> = nil,
    horizontalAccuracy: GraphQLNullable<Double> = nil
  ) {
    __data = InputDict([
      "timestamp": timestamp,
      "accelX": accelX,
      "accelY": accelY,
      "accelZ": accelZ,
      "gyroX": gyroX,
      "gyroY": gyroY,
      "gyroZ": gyroZ,
      "heartRate": heartRate,
      "relativeAltitude": relativeAltitude,
      "lat": lat,
      "lng": lng,
      "horizontalAccuracy": horizontalAccuracy
    ])
  }

  public var timestamp: Double {
    get { __data["timestamp"] }
    set { __data["timestamp"] = newValue }
  }

  public var accelX: GraphQLNullable<Double> {
    get { __data["accelX"] }
    set { __data["accelX"] = newValue }
  }

  public var accelY: GraphQLNullable<Double> {
    get { __data["accelY"] }
    set { __data["accelY"] = newValue }
  }

  public var accelZ: GraphQLNullable<Double> {
    get { __data["accelZ"] }
    set { __data["accelZ"] = newValue }
  }

  public var gyroX: GraphQLNullable<Double> {
    get { __data["gyroX"] }
    set { __data["gyroX"] = newValue }
  }

  public var gyroY: GraphQLNullable<Double> {
    get { __data["gyroY"] }
    set { __data["gyroY"] = newValue }
  }

  public var gyroZ: GraphQLNullable<Double> {
    get { __data["gyroZ"] }
    set { __data["gyroZ"] = newValue }
  }

  public var heartRate: GraphQLNullable<Double> {
    get { __data["heartRate"] }
    set { __data["heartRate"] = newValue }
  }

  public var relativeAltitude: GraphQLNullable<Double> {
    get { __data["relativeAltitude"] }
    set { __data["relativeAltitude"] = newValue }
  }

  public var lat: GraphQLNullable<Double> {
    get { __data["lat"] }
    set { __data["lat"] = newValue }
  }

  public var lng: GraphQLNullable<Double> {
    get { __data["lng"] }
    set { __data["lng"] = newValue }
  }

  public var horizontalAccuracy: GraphQLNullable<Double> {
    get { __data["horizontalAccuracy"] }
    set { __data["horizontalAccuracy"] = newValue }
  }
}
