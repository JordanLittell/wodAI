// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SavedHiitWorkoutsQuery: GraphQLQuery {
  public static let operationName: String = "SavedHiitWorkoutsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "c63c49e08b06b9e462603f27a5b2adf1e01202f89e10ae7c6f4d64797a0a7d6e",
    definition: .init(
      #"query SavedHiitWorkoutsQuery { savedHiitWorkouts { __typename id savedAt workout { __typename id format displayText stimulus constraintType constraintMagnitude } } }"#
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
