// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ActivityStatsQuery: GraphQLQuery {
  public static let operationName: String = "ActivityStats"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f7be1a9cda9a6a9fd388aa908df77d07fcb6edbbb04883d8a35609baae182065",
    definition: .init(
      #"query ActivityStats($start: DateTime!, $end: DateTime!, $timezone: String) { muscleLoad: stat( type: MUSCLE_LOAD startDate: $start endDate: $end timezone: $timezone ) { __typename ...StatFields } volume: stat( type: STRENGTH_VOLUME startDate: $start endDate: $end timezone: $timezone ) { __typename ...StatFields } intensity: stat( type: INTENSITY_MINUTES startDate: $start endDate: $end timezone: $timezone ) { __typename ...StatFields } }"#,
      fragments: [StatFields.self]
    ))

  public var start: WodAiAPI.DateTime
  public var end: WodAiAPI.DateTime
  public var timezone: GraphQLNullable<String>

  public init(
    start: WodAiAPI.DateTime,
    end: WodAiAPI.DateTime,
    timezone: GraphQLNullable<String>
  ) {
    self.start = start
    self.end = end
    self.timezone = timezone
  }

  public var __variables: Variables? { [
    "start": start,
    "end": end,
    "timezone": timezone
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("stat", alias: "muscleLoad", MuscleLoad.self, arguments: [
        "type": "MUSCLE_LOAD",
        "startDate": .variable("start"),
        "endDate": .variable("end"),
        "timezone": .variable("timezone")
      ]),
      .field("stat", alias: "volume", Volume.self, arguments: [
        "type": "STRENGTH_VOLUME",
        "startDate": .variable("start"),
        "endDate": .variable("end"),
        "timezone": .variable("timezone")
      ]),
      .field("stat", alias: "intensity", Intensity.self, arguments: [
        "type": "INTENSITY_MINUTES",
        "startDate": .variable("start"),
        "endDate": .variable("end"),
        "timezone": .variable("timezone")
      ]),
    ] }

    public var muscleLoad: MuscleLoad { __data["muscleLoad"] }
    public var volume: Volume { __data["volume"] }
    public var intensity: Intensity { __data["intensity"] }

    /// MuscleLoad
    ///
    /// Parent Type: `StatResult`
    public struct MuscleLoad: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Interfaces.StatResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(StatFields.self),
      ] }

      public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
      public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
      public var unit: String { __data["unit"] }
      public var total: Double? { __data["total"] }

      public var asCategoricalStat: AsCategoricalStat? { _asInlineFragment() }
      public var asSeriesStat: AsSeriesStat? { _asInlineFragment() }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var statFields: StatFields { _toFragment() }
      }

      /// MuscleLoad.AsCategoricalStat
      ///
      /// Parent Type: `CategoricalStat`
      public struct AsCategoricalStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.MuscleLoad
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CategoricalStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.MuscleLoad.self,
          StatFields.self,
          StatFields.AsCategoricalStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var categories: [Category] { __data["categories"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Category = StatFields.AsCategoricalStat.Category
      }

      /// MuscleLoad.AsSeriesStat
      ///
      /// Parent Type: `SeriesStat`
      public struct AsSeriesStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.MuscleLoad
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SeriesStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.MuscleLoad.self,
          StatFields.self,
          StatFields.AsSeriesStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var series: [Series] { __data["series"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Series = StatFields.AsSeriesStat.Series
      }
    }

    /// Volume
    ///
    /// Parent Type: `StatResult`
    public struct Volume: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Interfaces.StatResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(StatFields.self),
      ] }

      public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
      public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
      public var unit: String { __data["unit"] }
      public var total: Double? { __data["total"] }

      public var asCategoricalStat: AsCategoricalStat? { _asInlineFragment() }
      public var asSeriesStat: AsSeriesStat? { _asInlineFragment() }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var statFields: StatFields { _toFragment() }
      }

      /// Volume.AsCategoricalStat
      ///
      /// Parent Type: `CategoricalStat`
      public struct AsCategoricalStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.Volume
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CategoricalStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.Volume.self,
          StatFields.self,
          StatFields.AsCategoricalStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var categories: [Category] { __data["categories"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Category = StatFields.AsCategoricalStat.Category
      }

      /// Volume.AsSeriesStat
      ///
      /// Parent Type: `SeriesStat`
      public struct AsSeriesStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.Volume
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SeriesStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.Volume.self,
          StatFields.self,
          StatFields.AsSeriesStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var series: [Series] { __data["series"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Series = StatFields.AsSeriesStat.Series
      }
    }

    /// Intensity
    ///
    /// Parent Type: `StatResult`
    public struct Intensity: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Interfaces.StatResult }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(StatFields.self),
      ] }

      public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
      public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
      public var unit: String { __data["unit"] }
      public var total: Double? { __data["total"] }

      public var asCategoricalStat: AsCategoricalStat? { _asInlineFragment() }
      public var asSeriesStat: AsSeriesStat? { _asInlineFragment() }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var statFields: StatFields { _toFragment() }
      }

      /// Intensity.AsCategoricalStat
      ///
      /// Parent Type: `CategoricalStat`
      public struct AsCategoricalStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.Intensity
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CategoricalStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.Intensity.self,
          StatFields.self,
          StatFields.AsCategoricalStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var categories: [Category] { __data["categories"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Category = StatFields.AsCategoricalStat.Category
      }

      /// Intensity.AsSeriesStat
      ///
      /// Parent Type: `SeriesStat`
      public struct AsSeriesStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.Intensity
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SeriesStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.Intensity.self,
          StatFields.self,
          StatFields.AsSeriesStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var series: [Series] { __data["series"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Series = StatFields.AsSeriesStat.Series
      }
    }
  }
}
