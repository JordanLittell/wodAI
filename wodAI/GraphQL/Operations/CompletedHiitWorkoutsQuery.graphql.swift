// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompletedHiitWorkoutsQuery: GraphQLQuery {
  public static let operationName: String = "CompletedHiitWorkoutsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "29a41e9250b1f786557642f0918205d97a686a298b85535a5b190151aad3a90d",
    definition: .init(
      #"query CompletedHiitWorkoutsQuery { completedHiitWorkouts { __typename id completedAt workout { __typename id displayText stimulus constraintType constraintMagnitude } } }"#
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
        .field("workout", Workout.self),
      ] }

      public var id: Int { __data["id"] }
      public var completedAt: WodAiAPI.DateTime { __data["completedAt"] }
      public var workout: Workout { __data["workout"] }

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
