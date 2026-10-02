// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public struct GeneratedHiitWorkout: WodAiAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment GeneratedHiitWorkout on HIITWorkout { __typename id name format stimulus displayText constraintType constraintMagnitude timeCap timingScheme { __typename version segments { __typename rounds phases { __typename durationSeconds direction label } } phases { __typename durationSeconds direction label } } }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("id", Int.self),
    .field("name", String?.self),
    .field("format", String?.self),
    .field("stimulus", String.self),
    .field("displayText", String.self),
    .field("constraintType", String.self),
    .field("constraintMagnitude", Int.self),
    .field("timeCap", Int?.self),
    .field("timingScheme", TimingScheme?.self),
  ] }

  public var id: Int { __data["id"] }
  public var name: String? { __data["name"] }
  public var format: String? { __data["format"] }
  public var stimulus: String { __data["stimulus"] }
  public var displayText: String { __data["displayText"] }
  public var constraintType: String { __data["constraintType"] }
  public var constraintMagnitude: Int { __data["constraintMagnitude"] }
  public var timeCap: Int? { __data["timeCap"] }
  public var timingScheme: TimingScheme? { __data["timingScheme"] }

  /// TimingScheme
  ///
  /// Parent Type: `WodTimerConfig`
  public struct TimingScheme: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WodTimerConfig }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("version", Int.self),
      .field("segments", [Segment]?.self),
      .field("phases", [Phase]?.self),
    ] }

    public var version: Int { __data["version"] }
    public var segments: [Segment]? { __data["segments"] }
    public var phases: [Phase]? { __data["phases"] }

    /// TimingScheme.Segment
    ///
    /// Parent Type: `TimerSegment`
    public struct Segment: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TimerSegment }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("rounds", Int.self),
        .field("phases", [Phase].self),
      ] }

      public var rounds: Int { __data["rounds"] }
      public var phases: [Phase] { __data["phases"] }

      /// TimingScheme.Segment.Phase
      ///
      /// Parent Type: `TimerPhase`
      public struct Phase: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TimerPhase }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("durationSeconds", Int?.self),
          .field("direction", GraphQLEnum<WodAiAPI.PhaseDirection>.self),
          .field("label", String?.self),
        ] }

        public var durationSeconds: Int? { __data["durationSeconds"] }
        public var direction: GraphQLEnum<WodAiAPI.PhaseDirection> { __data["direction"] }
        public var label: String? { __data["label"] }
      }
    }

    /// TimingScheme.Phase
    ///
    /// Parent Type: `TimerPhase`
    public struct Phase: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TimerPhase }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("durationSeconds", Int?.self),
        .field("direction", GraphQLEnum<WodAiAPI.PhaseDirection>.self),
        .field("label", String?.self),
      ] }

      public var durationSeconds: Int? { __data["durationSeconds"] }
      public var direction: GraphQLEnum<WodAiAPI.PhaseDirection> { __data["direction"] }
      public var label: String? { __data["label"] }
    }
  }
}
