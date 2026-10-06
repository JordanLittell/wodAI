// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompletedHiitWorkoutsQuery: GraphQLQuery {
  public static let operationName: String = "CompletedHiitWorkoutsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "2e5c72f84671a398cead15a95d8f392f7874ad291dbc154302fc1872b089a208",
    definition: .init(
      #"query CompletedHiitWorkoutsQuery($startDate: DateTime, $endDate: DateTime) { completedHiitWorkouts(startDate: $startDate, endDate: $endDate) { __typename id completedAt durationSeconds roundsCompleted repsCompleted perceivedEffort trainingLoad heartRate { __typename avg max } heartRateSeries { __typename seconds bpm } workout { __typename id format displayText stimulus constraintType constraintMagnitude } } }"#
    ))

  public var startDate: GraphQLNullable<WodAiAPI.DateTime>
  public var endDate: GraphQLNullable<WodAiAPI.DateTime>

  public init(
    startDate: GraphQLNullable<WodAiAPI.DateTime>,
    endDate: GraphQLNullable<WodAiAPI.DateTime>
  ) {
    self.startDate = startDate
    self.endDate = endDate
  }

  public var __variables: Variables? { [
    "startDate": startDate,
    "endDate": endDate
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completedHiitWorkouts", [CompletedHiitWorkout].self, arguments: [
        "startDate": .variable("startDate"),
        "endDate": .variable("endDate")
      ]),
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
        .field("trainingLoad", Double?.self),
        .field("heartRate", HeartRate?.self),
        .field("heartRateSeries", [HeartRateSeries].self),
        .field("workout", Workout.self),
      ] }

      public var id: Int { __data["id"] }
      public var completedAt: WodAiAPI.DateTime { __data["completedAt"] }
      public var durationSeconds: Int? { __data["durationSeconds"] }
      public var roundsCompleted: Int? { __data["roundsCompleted"] }
      public var repsCompleted: Int? { __data["repsCompleted"] }
      public var perceivedEffort: Int? { __data["perceivedEffort"] }
      public var trainingLoad: Double? { __data["trainingLoad"] }
      public var heartRate: HeartRate? { __data["heartRate"] }
      public var heartRateSeries: [HeartRateSeries] { __data["heartRateSeries"] }
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
          .field("max", Double.self),
        ] }

        public var avg: Double { __data["avg"] }
        public var max: Double { __data["max"] }
      }

      /// CompletedHiitWorkout.HeartRateSeries
      ///
      /// Parent Type: `HeartRateSample`
      public struct HeartRateSeries: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HeartRateSample }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("seconds", Double.self),
          .field("bpm", Double.self),
        ] }

        public var seconds: Double { __data["seconds"] }
        public var bpm: Double { __data["bpm"] }
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
          .field("format", String?.self),
          .field("displayText", String.self),
          .field("stimulus", String.self),
          .field("constraintType", String.self),
          .field("constraintMagnitude", Int.self),
        ] }

        public var id: Int { __data["id"] }
        public var format: String? { __data["format"] }
        public var displayText: String { __data["displayText"] }
        public var stimulus: String { __data["stimulus"] }
        public var constraintType: String { __data["constraintType"] }
        public var constraintMagnitude: Int { __data["constraintMagnitude"] }
      }
    }
  }
}
