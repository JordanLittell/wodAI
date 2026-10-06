// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public struct StatFields: WodAiAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment StatFields on StatResult { __typename type shape unit total ... on CategoricalStat { categories { __typename label value } } ... on SeriesStat { series { __typename x y } } }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Interfaces.StatResult }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("type", GraphQLEnum<WodAiAPI.StatType>.self),
    .field("shape", GraphQLEnum<WodAiAPI.StatShape>.self),
    .field("unit", String.self),
    .field("total", Double?.self),
    .inlineFragment(AsCategoricalStat.self),
    .inlineFragment(AsSeriesStat.self),
  ] }

  public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
  public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
  public var unit: String { __data["unit"] }
  public var total: Double? { __data["total"] }

  public var asCategoricalStat: AsCategoricalStat? { _asInlineFragment() }
  public var asSeriesStat: AsSeriesStat? { _asInlineFragment() }

  /// AsCategoricalStat
  ///
  /// Parent Type: `CategoricalStat`
  public struct AsCategoricalStat: WodAiAPI.InlineFragment {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public typealias RootEntityType = StatFields
    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CategoricalStat }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("categories", [Category].self),
    ] }

    public var categories: [Category] { __data["categories"] }
    public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
    public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
    public var unit: String { __data["unit"] }
    public var total: Double? { __data["total"] }

    /// AsCategoricalStat.Category
    ///
    /// Parent Type: `CategoryPoint`
    public struct Category: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CategoryPoint }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("label", String.self),
        .field("value", Double.self),
      ] }

      public var label: String { __data["label"] }
      public var value: Double { __data["value"] }
    }
  }

  /// AsSeriesStat
  ///
  /// Parent Type: `SeriesStat`
  public struct AsSeriesStat: WodAiAPI.InlineFragment {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public typealias RootEntityType = StatFields
    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SeriesStat }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("series", [Series].self),
    ] }

    public var series: [Series] { __data["series"] }
    public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
    public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
    public var unit: String { __data["unit"] }
    public var total: Double? { __data["total"] }

    /// AsSeriesStat.Series
    ///
    /// Parent Type: `SeriesPoint`
    public struct Series: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SeriesPoint }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("x", String.self),
        .field("y", Double.self),
      ] }

      public var x: String { __data["x"] }
      public var y: Double { __data["y"] }
    }
  }
}
