// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SavedHiitWorkoutsQuery: GraphQLQuery {
  public static let operationName: String = "SavedHiitWorkoutsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "2446f3fee75925fa5e9dd1e27757fb35d9b94d6c3b100fefdd71a06884434822",
    definition: .init(
      #"query SavedHiitWorkoutsQuery { savedHiitWorkouts { __typename id savedAt workout { __typename id format displayText stimulus constraintType constraintMagnitude timeCap timingScheme { __typename version segments { __typename rounds phases { __typename durationSeconds direction label } } } } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("savedHiitWorkouts", [SavedHiitWorkout].self),
    ] }

    public var savedHiitWorkouts: [SavedHiitWorkout] { __data["savedHiitWorkouts"] }

    /// SavedHiitWorkout
    ///
    /// Parent Type: `SavedHIITWorkout`
    public struct SavedHiitWorkout: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SavedHIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("savedAt", WodAiAPI.DateTime.self),
        .field("workout", Workout.self),
      ] }

      public var id: Int { __data["id"] }
      public var savedAt: WodAiAPI.DateTime { __data["savedAt"] }
      public var workout: Workout { __data["workout"] }

      /// SavedHiitWorkout.Workout
      ///
      /// Parent Type: `HIITWorkout`
      public struct Workout: WodAiAPI.SelectionSet {
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
        ] }

        public var id: Int { __data["id"] }
        public var format: String? { __data["format"] }
        public var displayText: String { __data["displayText"] }
        public var stimulus: String { __data["stimulus"] }
        public var constraintType: String { __data["constraintType"] }
        public var constraintMagnitude: Int { __data["constraintMagnitude"] }
        public var timeCap: Int? { __data["timeCap"] }
        public var timingScheme: TimingScheme? { __data["timingScheme"] }

        /// SavedHiitWorkout.Workout.TimingScheme
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

          /// SavedHiitWorkout.Workout.TimingScheme.Segment
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

            /// SavedHiitWorkout.Workout.TimingScheme.Segment.Phase
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
      }
    }
  }
}
