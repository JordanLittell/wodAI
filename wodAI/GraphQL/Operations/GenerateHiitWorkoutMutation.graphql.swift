// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GenerateHiitWorkoutMutation: GraphQLMutation {
  public static let operationName: String = "GenerateHiitWorkoutMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "242a0ae50c6a3d10fc59c90b4f461dd688cb6dcaf05d90f13925b3d1256b2f0a",
    definition: .init(
      #"mutation GenerateHiitWorkoutMutation($skipWorkoutId: Int, $tagIds: [Int!]) { generateHiitWorkout(skipWorkoutId: $skipWorkoutId, tagIds: $tagIds) { __typename id format displayText stimulus constraintType constraintMagnitude timeCap timingScheme { __typename version segments { __typename rounds phases { __typename durationSeconds direction label } } } tags { __typename id name } } }"#
    ))

  public var skipWorkoutId: GraphQLNullable<Int>
  public var tagIds: GraphQLNullable<[Int]>

  public init(
    skipWorkoutId: GraphQLNullable<Int>,
    tagIds: GraphQLNullable<[Int]>
  ) {
    self.skipWorkoutId = skipWorkoutId
    self.tagIds = tagIds
  }

  public var __variables: Variables? { [
    "skipWorkoutId": skipWorkoutId,
    "tagIds": tagIds
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("generateHiitWorkout", GenerateHiitWorkout?.self, arguments: [
        "skipWorkoutId": .variable("skipWorkoutId"),
        "tagIds": .variable("tagIds")
      ]),
    ] }

    public var generateHiitWorkout: GenerateHiitWorkout? { __data["generateHiitWorkout"] }

    /// GenerateHiitWorkout
    ///
    /// Parent Type: `HIITWorkout`
    public struct GenerateHiitWorkout: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("format", String?.self),
        .field("displayText", String.self),
        .field("stimulus", String.self),
        .field("constraintType", String.self),
        .field("constraintMagnitude", Int.self),
        .field("timeCap", Int?.self),
        .field("timingScheme", TimingScheme?.self),
        .field("tags", [Tag]?.self),
      ] }

      public var id: Int { __data["id"] }
      public var format: String? { __data["format"] }
      public var displayText: String { __data["displayText"] }
      public var stimulus: String { __data["stimulus"] }
      public var constraintType: String { __data["constraintType"] }
      public var constraintMagnitude: Int { __data["constraintMagnitude"] }
      public var timeCap: Int? { __data["timeCap"] }
      public var timingScheme: TimingScheme? { __data["timingScheme"] }
      public var tags: [Tag]? { __data["tags"] }

      /// GenerateHiitWorkout.TimingScheme
      ///
      /// Parent Type: `WodTimerConfig`
      public struct TimingScheme: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WodTimerConfig }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("version", Int.self),
          .field("segments", [Segment].self),
        ] }

        public var version: Int { __data["version"] }
        public var segments: [Segment] { __data["segments"] }

        /// GenerateHiitWorkout.TimingScheme.Segment
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

          /// GenerateHiitWorkout.TimingScheme.Segment.Phase
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

      /// GenerateHiitWorkout.Tag
      ///
      /// Parent Type: `Tag`
      public struct Tag: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Tag }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String.self),
        ] }

        public var id: Int { __data["id"] }
        public var name: String { __data["name"] }
      }
    }
  }
}
