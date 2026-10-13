// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public struct HealthSnapshotInput: InputObject {
  public private(set) var __data: InputDict

  public init(_ data: InputDict) {
    __data = data
  }

  public init(
    vo2Max: GraphQLNullable<Double> = nil,
    restingHeartRate: GraphQLNullable<Int> = nil,
    hrvMs: GraphQLNullable<Double> = nil,
    dailySteps: GraphQLNullable<Int> = nil,
    maxHeartRate: GraphQLNullable<Int> = nil,
    workoutsPerWeek: GraphQLNullable<Double> = nil,
    cardioPerWeek: GraphQLNullable<Double> = nil,
    strengthPerWeek: GraphQLNullable<Double> = nil,
    activeWeeks: GraphQLNullable<Int> = nil,
    topActivityTypes: GraphQLNullable<[String]> = nil
  ) {
    __data = InputDict([
      "vo2Max": vo2Max,
      "restingHeartRate": restingHeartRate,
      "hrvMs": hrvMs,
      "dailySteps": dailySteps,
      "maxHeartRate": maxHeartRate,
      "workoutsPerWeek": workoutsPerWeek,
      "cardioPerWeek": cardioPerWeek,
      "strengthPerWeek": strengthPerWeek,
      "activeWeeks": activeWeeks,
      "topActivityTypes": topActivityTypes
    ])
  }

  public var vo2Max: GraphQLNullable<Double> {
    get { __data["vo2Max"] }
    set { __data["vo2Max"] = newValue }
  }

  public var restingHeartRate: GraphQLNullable<Int> {
    get { __data["restingHeartRate"] }
    set { __data["restingHeartRate"] = newValue }
  }

  public var hrvMs: GraphQLNullable<Double> {
    get { __data["hrvMs"] }
    set { __data["hrvMs"] = newValue }
  }

  public var dailySteps: GraphQLNullable<Int> {
    get { __data["dailySteps"] }
    set { __data["dailySteps"] = newValue }
  }

  public var maxHeartRate: GraphQLNullable<Int> {
    get { __data["maxHeartRate"] }
    set { __data["maxHeartRate"] = newValue }
  }

  public var workoutsPerWeek: GraphQLNullable<Double> {
    get { __data["workoutsPerWeek"] }
    set { __data["workoutsPerWeek"] = newValue }
  }

  public var cardioPerWeek: GraphQLNullable<Double> {
    get { __data["cardioPerWeek"] }
    set { __data["cardioPerWeek"] = newValue }
  }

  public var strengthPerWeek: GraphQLNullable<Double> {
    get { __data["strengthPerWeek"] }
    set { __data["strengthPerWeek"] = newValue }
  }

  public var activeWeeks: GraphQLNullable<Int> {
    get { __data["activeWeeks"] }
    set { __data["activeWeeks"] = newValue }
  }

  public var topActivityTypes: GraphQLNullable<[String]> {
    get { __data["topActivityTypes"] }
    set { __data["topActivityTypes"] = newValue }
  }
}
