// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ActivityStatsQuery: GraphQLQuery {
  public static let operationName: String = "ActivityStats"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "7f594a0112a07211ac4ba03946d907a7a69ed71af55ec3d6d6fadb5263c1fcf3",
    definition: .init(
      #"query ActivityStats($start: DateTime!, $end: DateTime!, $timezone: String) { volume: stat( type: STRENGTH_VOLUME startDate: $start endDate: $end timezone: $timezone ) { __typename ...StatFields } intensity: stat( type: INTENSITY_MINUTES startDate: $start endDate: $end timezone: $timezone ) { __typename ...StatFields } trainingLoad: stat( type: TRAINING_LOAD startDate: $start endDate: $end timezone: $timezone ) { __typename ...StatFields } }"#,
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
      .field("stat", alias: "trainingLoad", TrainingLoad.self, arguments: [
        "type": "TRAINING_LOAD",
        "startDate": .variable("start"),
        "endDate": .variable("end"),
        "timezone": .variable("timezone")
      ]),
    ] }

    public var volume: Volume { __data["volume"] }
    public var intensity: Intensity { __data["intensity"] }
    public var trainingLoad: TrainingLoad { __data["trainingLoad"] }

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
      public var provenance: String? { __data["provenance"] }

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
        public var provenance: String? { __data["provenance"] }
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
        public var provenance: String? { __data["provenance"] }
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
      public var provenance: String? { __data["provenance"] }

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
        public var provenance: String? { __data["provenance"] }
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
        public var provenance: String? { __data["provenance"] }
        public var series: [Series] { __data["series"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Series = StatFields.AsSeriesStat.Series
      }
    }

    /// TrainingLoad
    ///
    /// Parent Type: `StatResult`
    public struct TrainingLoad: WodAiAPI.SelectionSet {
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
      public var provenance: String? { __data["provenance"] }

      public var asCategoricalStat: AsCategoricalStat? { _asInlineFragment() }
      public var asSeriesStat: AsSeriesStat? { _asInlineFragment() }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var statFields: StatFields { _toFragment() }
      }

      /// TrainingLoad.AsCategoricalStat
      ///
      /// Parent Type: `CategoricalStat`
      public struct AsCategoricalStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.TrainingLoad
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CategoricalStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.TrainingLoad.self,
          StatFields.self,
          StatFields.AsCategoricalStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var provenance: String? { __data["provenance"] }
        public var categories: [Category] { __data["categories"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var statFields: StatFields { _toFragment() }
        }

        public typealias Category = StatFields.AsCategoricalStat.Category
      }

      /// TrainingLoad.AsSeriesStat
      ///
      /// Parent Type: `SeriesStat`
      public struct AsSeriesStat: WodAiAPI.InlineFragment, ApolloAPI.CompositeInlineFragment {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public typealias RootEntityType = ActivityStatsQuery.Data.TrainingLoad
        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SeriesStat }
        public static var __mergedSources: [any ApolloAPI.SelectionSet.Type] { [
          ActivityStatsQuery.Data.TrainingLoad.self,
          StatFields.self,
          StatFields.AsSeriesStat.self
        ] }

        public var type: GraphQLEnum<WodAiAPI.StatType> { __data["type"] }
        public var shape: GraphQLEnum<WodAiAPI.StatShape> { __data["shape"] }
        public var unit: String { __data["unit"] }
        public var total: Double? { __data["total"] }
        public var provenance: String? { __data["provenance"] }
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
