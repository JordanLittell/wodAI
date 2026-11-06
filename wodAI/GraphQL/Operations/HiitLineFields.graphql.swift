// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public struct HiitLineFields: WodAiAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment HiitLineFields on HIITPrescription { __typename line partId amount amountUnit max load loadUnit exercise { __typename id name patterns loads } }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITPrescription }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("line", Int.self),
    .field("partId", Int?.self),
    .field("amount", Double?.self),
    .field("amountUnit", GraphQLEnum<WodAiAPI.AmountUnit>.self),
    .field("max", Bool.self),
    .field("load", Double?.self),
    .field("loadUnit", GraphQLEnum<WodAiAPI.LoadUnit>?.self),
    .field("exercise", Exercise.self),
  ] }

  public var line: Int { __data["line"] }
  public var partId: Int? { __data["partId"] }
  public var amount: Double? { __data["amount"] }
  public var amountUnit: GraphQLEnum<WodAiAPI.AmountUnit> { __data["amountUnit"] }
  public var max: Bool { __data["max"] }
  public var load: Double? { __data["load"] }
  public var loadUnit: GraphQLEnum<WodAiAPI.LoadUnit>? { __data["loadUnit"] }
  public var exercise: Exercise { __data["exercise"] }

  /// Exercise
  ///
  /// Parent Type: `HIITExercise`
  public struct Exercise: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITExercise }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", Int.self),
      .field("name", String.self),
      .field("patterns", String.self),
      .field("loads", [GraphQLEnum<WodAiAPI.LoadKind>].self),
    ] }

    public var id: Int { __data["id"] }
    public var name: String { __data["name"] }
    public var patterns: String { __data["patterns"] }
    public var loads: [GraphQLEnum<WodAiAPI.LoadKind>] { __data["loads"] }
  }
}
