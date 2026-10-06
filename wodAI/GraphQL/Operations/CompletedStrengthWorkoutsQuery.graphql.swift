// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompletedStrengthWorkoutsQuery: GraphQLQuery {
  public static let operationName: String = "CompletedStrengthWorkouts"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "82c5f7b386e4852a404ef980fe9c78c2ecb592ef6a642cc4636d8067313199bd",
    definition: .init(
      #"query CompletedStrengthWorkouts($startDate: DateTime!, $endDate: DateTime!) { completedStrengthWorkouts(startDate: $startDate, endDate: $endDate) { __typename completedAt strengthWorkout { __typename id name stimulus instructions components { __typename id order reps weight completedAt completedReps completedWeight exercise { __typename name } } } } }"#
    ))

  public var startDate: WodAiAPI.DateTime
  public var endDate: WodAiAPI.DateTime

  public init(
    startDate: WodAiAPI.DateTime,
    endDate: WodAiAPI.DateTime
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
      .field("completedStrengthWorkouts", [CompletedStrengthWorkout].self, arguments: [
        "startDate": .variable("startDate"),
        "endDate": .variable("endDate")
      ]),
    ] }

    public var completedStrengthWorkouts: [CompletedStrengthWorkout] { __data["completedStrengthWorkouts"] }

    /// CompletedStrengthWorkout
    ///
    /// Parent Type: `CompletedStrengthWorkout`
    public struct CompletedStrengthWorkout: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.CompletedStrengthWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("completedAt", WodAiAPI.DateTime.self),
        .field("strengthWorkout", StrengthWorkout.self),
      ] }

      public var completedAt: WodAiAPI.DateTime { __data["completedAt"] }
      public var strengthWorkout: StrengthWorkout { __data["strengthWorkout"] }

      /// CompletedStrengthWorkout.StrengthWorkout
      ///
      /// Parent Type: `StrengthWorkout`
      public struct StrengthWorkout: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthWorkout }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String?.self),
          .field("stimulus", String.self),
          .field("instructions", String.self),
          .field("components", [Component].self),
        ] }

        public var id: Int { __data["id"] }
        public var name: String? { __data["name"] }
        public var stimulus: String { __data["stimulus"] }
        public var instructions: String { __data["instructions"] }
        public var components: [Component] { __data["components"] }

        /// CompletedStrengthWorkout.StrengthWorkout.Component
        ///
        /// Parent Type: `StrengthComponent`
        public struct Component: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthComponent }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("order", Int.self),
            .field("reps", Int.self),
            .field("weight", Double?.self),
            .field("completedAt", WodAiAPI.DateTime?.self),
            .field("completedReps", Int?.self),
            .field("completedWeight", Double?.self),
            .field("exercise", Exercise.self),
          ] }

          public var id: Int { __data["id"] }
          public var order: Int { __data["order"] }
          public var reps: Int { __data["reps"] }
          public var weight: Double? { __data["weight"] }
          public var completedAt: WodAiAPI.DateTime? { __data["completedAt"] }
          public var completedReps: Int? { __data["completedReps"] }
          public var completedWeight: Double? { __data["completedWeight"] }
          public var exercise: Exercise { __data["exercise"] }

          /// CompletedStrengthWorkout.StrengthWorkout.Component.Exercise
          ///
          /// Parent Type: `HIITExercise`
          public struct Exercise: WodAiAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HIITExercise }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("name", String.self),
            ] }

            public var name: String { __data["name"] }
          }
        }
      }
    }
  }
}
