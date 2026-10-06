// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CompleteStrengthComponentsMutation: GraphQLMutation {
  public static let operationName: String = "CompleteStrengthComponents"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "4745f35446f2aef8e5b59cea5f2895716ae966edc458016864fbb13bd18e2f3b",
    definition: .init(
      #"mutation CompleteStrengthComponents($strengthWorkoutId: Int!, $components: [StrengthComponentResultInput!]!) { completeStrengthComponents( strengthWorkoutId: $strengthWorkoutId components: $components ) { __typename id components { __typename id completedAt completedReps completedWeight completedRpe } } }"#
    ))

  public var strengthWorkoutId: Int
  public var components: [WodAiAPI.StrengthComponentResultInput]

  public init(
    strengthWorkoutId: Int,
    components: [WodAiAPI.StrengthComponentResultInput]
  ) {
    self.strengthWorkoutId = strengthWorkoutId
    self.components = components
  }

  public var __variables: Variables? { [
    "strengthWorkoutId": strengthWorkoutId,
    "components": components
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("completeStrengthComponents", CompleteStrengthComponents.self, arguments: [
        "strengthWorkoutId": .variable("strengthWorkoutId"),
        "components": .variable("components")
      ]),
    ] }

    public var completeStrengthComponents: CompleteStrengthComponents { __data["completeStrengthComponents"] }

    /// CompleteStrengthComponents
    ///
    /// Parent Type: `StrengthWorkout`
    public struct CompleteStrengthComponents: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthWorkout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("components", [Component].self),
      ] }

      public var id: Int { __data["id"] }
      public var components: [Component] { __data["components"] }

      /// CompleteStrengthComponents.Component
      ///
      /// Parent Type: `StrengthComponent`
      public struct Component: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.StrengthComponent }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("completedAt", WodAiAPI.DateTime?.self),
          .field("completedReps", Int?.self),
          .field("completedWeight", Double?.self),
          .field("completedRpe", Int?.self),
        ] }

        public var id: Int { __data["id"] }
        public var completedAt: WodAiAPI.DateTime? { __data["completedAt"] }
        public var completedReps: Int? { __data["completedReps"] }
        public var completedWeight: Double? { __data["completedWeight"] }
        public var completedRpe: Int? { __data["completedRpe"] }
      }
    }
  }
}
