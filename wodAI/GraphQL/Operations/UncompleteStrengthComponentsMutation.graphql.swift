// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UncompleteStrengthComponentsMutation: GraphQLMutation {
  public static let operationName: String = "UncompleteStrengthComponents"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f949becc9507e24251ce01cca26595267100eae61495200aced281f6fb2df81e",
    definition: .init(
      #"mutation UncompleteStrengthComponents($strengthWorkoutId: Int!, $componentIds: [Int!]!) { uncompleteStrengthComponents( strengthWorkoutId: $strengthWorkoutId componentIds: $componentIds ) { __typename id components { __typename id completedAt completedReps completedWeight completedRpe } } }"#
    ))

  public var strengthWorkoutId: Int
  public var componentIds: [Int]

  public init(
    strengthWorkoutId: Int,
    componentIds: [Int]
  ) {
    self.strengthWorkoutId = strengthWorkoutId
    self.componentIds = componentIds
  }

  public var __variables: Variables? { [
    "strengthWorkoutId": strengthWorkoutId,
    "componentIds": componentIds
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("uncompleteStrengthComponents", UncompleteStrengthComponents.self, arguments: [
        "strengthWorkoutId": .variable("strengthWorkoutId"),
        "componentIds": .variable("componentIds")
      ]),
    ] }

    public var uncompleteStrengthComponents: UncompleteStrengthComponents { __data["uncompleteStrengthComponents"] }

    /// UncompleteStrengthComponents
    ///
    /// Parent Type: `StrengthWorkout`
    public struct UncompleteStrengthComponents: WodAiAPI.SelectionSet {
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

      /// UncompleteStrengthComponents.Component
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
