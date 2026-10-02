// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public struct HeartRateSummaryFields: WodAiAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment HeartRateSummaryFields on HeartRateSummary { __typename avg max min coverage zoneSeconds trainingLoad estimatedCalories }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HeartRateSummary }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("avg", Double.self),
    .field("max", Double.self),
    .field("min", Double.self),
    .field("coverage", Double.self),
    .field("zoneSeconds", [Int].self),
    .field("trainingLoad", Double.self),
    .field("estimatedCalories", Double?.self),
  ] }

  public var avg: Double { __data["avg"] }
  public var max: Double { __data["max"] }
  public var min: Double { __data["min"] }
  public var coverage: Double { __data["coverage"] }
  public var zoneSeconds: [Int] { __data["zoneSeconds"] }
  public var trainingLoad: Double { __data["trainingLoad"] }
  public var estimatedCalories: Double? { __data["estimatedCalories"] }
}
