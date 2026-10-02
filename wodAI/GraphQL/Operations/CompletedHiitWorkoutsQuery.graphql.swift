// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompletedHiitWorkoutsQuery: GraphQLQuery {
  public static let operationName: String = "CompletedHiitWorkoutsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "1b71e4e5afce7ed585e415f43e6c5917f7c05a6af7c3fe289d57d09cdd0690cb",
    definition: .init(
      #"query CompletedHiitWorkoutsQuery { completedHiitWorkouts { __typename id completedAt durationSeconds roundsCompleted repsCompleted perceivedEffort notes trainingLoad heartRate { __typename avg } workout { __typename id displayText stimulus constraintType constraintMagnitude } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completedHiitWorkouts", [CompletedHiitWorkout].self),
    ] }

    public var completedHiitWorkouts: [CompletedHiitWorkout] { __data["completedHiitWorkouts"] }

    /// CompletedHiitWorkout
    ///
    /// Parent Type: `CompletedHIITWorkout`
    public struct CompletedHiitWorkout: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CompletedHIITWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("completedAt", WodAiAPI.DateTime.self),
        .field("durationSeconds", Int?.self),
        .field("roundsCompleted", Int?.self),
        .field("repsCompleted", Int?.self),
        .field("perceivedEffort", Int?.self),
        .field("notes", String?.self),
        .field("trainingLoad", Double?.self),
        .field("heartRate", HeartRate?.self),
        .field("workout", Workout.self),
      ] }

      public var id: Int { __data["id"] }
      public var completedAt: WodAiAPI.DateTime { __data["completedAt"] }
      public var durationSeconds: Int? { __data["durationSeconds"] }
      public var roundsCompleted: Int? { __data["roundsCompleted"] }
      public var repsCompleted: Int? { __data["repsCompleted"] }
      public var perceivedEffort: Int? { __data["perceivedEffort"] }
      public var notes: String? { __data["notes"] }
      public var trainingLoad: Double? { __data["trainingLoad"] }
      public var heartRate: HeartRate? { __data["heartRate"] }
      public var workout: Workout { __data["workout"] }

      /// CompletedHiitWorkout.HeartRate
      ///
      /// Parent Type: `HeartRateSummary`
      public struct HeartRate: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HeartRateSummary }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("avg", Double.self),
        ] }

        public var avg: Double { __data["avg"] }
      }

      /// CompletedHiitWorkout.Workout
      ///
      /// Parent Type: `HIITWorkout`
      public struct Workout: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITWorkout }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("displayText", String.self),
          .field("stimulus", String.self),
          .field("constraintType", String.self),
          .field("constraintMagnitude", Int.self),
        ] }

        public var id: Int { __data["id"] }
        public var displayText: String { __data["displayText"] }
        public var stimulus: String { __data["stimulus"] }
        public var constraintType: String { __data["constraintType"] }
        public var constraintMagnitude: Int { __data["constraintMagnitude"] }
      }
    }
  }
}
