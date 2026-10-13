// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class HealthSessionQuery: GraphQLQuery {
  public static let operationName: String = "HealthSession"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "34b7a0d45c51742632a96432db4ddb17997fabc1bd2501c037cd410e3aa2689d",
    definition: .init(
      #"query HealthSession($id: String!) { workout(id: $id) { __typename id name completed completedAt strengthWorkouts { __typename components { __typename completedAt } } hiitPieces { __typename id completion { __typename completedAt durationSeconds } } } }"#
    ))

  public var id: String

  public init(id: String) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("workout", Workout?.self, arguments: ["id": .variable("id")]),
    ] }

    public var workout: Workout? { __data["workout"] }

    /// Workout
    ///
    /// Parent Type: `Workout`
    public struct Workout: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("name", String.self),
        .field("completed", Bool.self),
        .field("completedAt", WodAiAPI.DateTime?.self),
        .field("strengthWorkouts", [StrengthWorkout].self),
        .field("hiitPieces", [HiitPiece].self),
      ] }

      public var id: String { __data["id"] }
      public var name: String { __data["name"] }
      public var completed: Bool { __data["completed"] }
      public var completedAt: WodAiAPI.DateTime? { __data["completedAt"] }
      public var strengthWorkouts: [StrengthWorkout] { __data["strengthWorkouts"] }
      public var hiitPieces: [HiitPiece] { __data["hiitPieces"] }

      /// Workout.StrengthWorkout
      ///
      /// Parent Type: `StrengthWorkout`
      public struct StrengthWorkout: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthWorkout }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("components", [Component].self),
        ] }

        public var components: [Component] { __data["components"] }

        /// Workout.StrengthWorkout.Component
        ///
        /// Parent Type: `StrengthComponent`
        public struct Component: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthComponent }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("completedAt", WodAiAPI.DateTime?.self),
          ] }

          public var completedAt: WodAiAPI.DateTime? { __data["completedAt"] }
        }
      }

      /// Workout.HiitPiece
      ///
      /// Parent Type: `WorkoutHiitPiece`
      public struct HiitPiece: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WorkoutHiitPiece }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("completion", Completion?.self),
        ] }

        public var id: Int { __data["id"] }
        public var completion: Completion? { __data["completion"] }

        /// Workout.HiitPiece.Completion
        ///
        /// Parent Type: `CompletedHIITWorkout`
        public struct Completion: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CompletedHIITWorkout }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("completedAt", WodAiAPI.DateTime.self),
            .field("durationSeconds", Int?.self),
          ] }

          public var completedAt: WodAiAPI.DateTime { __data["completedAt"] }
          public var durationSeconds: Int? { __data["durationSeconds"] }
        }
      }
    }
  }
}
