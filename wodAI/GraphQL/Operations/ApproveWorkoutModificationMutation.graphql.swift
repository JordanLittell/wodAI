// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ApproveWorkoutModificationMutation: GraphQLMutation {
  public static let operationName: String = "ApproveWorkoutModification"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "31fd9058a6b5402c8c7a3a41bc02b97e693f0addf6509e36136c5c1f2e41f145",
    definition: .init(
      #"mutation ApproveWorkoutModification($wodId: String!, $conversationId: String!) { approveWorkoutModification(wodId: $wodId, conversationId: $conversationId) { __typename id name description stimulus coaching components { __typename id name order definition description targetFitnessDomains energySystems muscles movements } } }"#
    ))

  public var wodId: String
  public var conversationId: String

  public init(
    wodId: String,
    conversationId: String
  ) {
    self.wodId = wodId
    self.conversationId = conversationId
  }

  public var __variables: Variables? { [
    "wodId": wodId,
    "conversationId": conversationId
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("approveWorkoutModification", ApproveWorkoutModification.self, arguments: [
        "wodId": .variable("wodId"),
        "conversationId": .variable("conversationId")
      ]),
    ] }

    public var approveWorkoutModification: ApproveWorkoutModification { __data["approveWorkoutModification"] }

    /// ApproveWorkoutModification
    ///
    /// Parent Type: `Workout`
    public struct ApproveWorkoutModification: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Workout }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("name", String.self),
        .field("description", String.self),
        .field("stimulus", String?.self),
        .field("coaching", String?.self),
        .field("components", [Component].self),
      ] }

      public var id: String { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var stimulus: String? { __data["stimulus"] }
      public var coaching: String? { __data["coaching"] }
      public var components: [Component] { __data["components"] }

      /// ApproveWorkoutModification.Component
      ///
      /// Parent Type: `Component`
      public struct Component: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Component }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("order", Int.self),
          .field("definition", String.self),
          .field("description", String.self),
          .field("targetFitnessDomains", [String].self),
          .field("energySystems", [String].self),
          .field("muscles", [String].self),
          .field("movements", [String].self),
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var order: Int { __data["order"] }
        public var definition: String { __data["definition"] }
        public var description: String { __data["description"] }
        public var targetFitnessDomains: [String] { __data["targetFitnessDomains"] }
        public var energySystems: [String] { __data["energySystems"] }
        public var muscles: [String] { __data["muscles"] }
        public var movements: [String] { __data["movements"] }
      }
    }
  }
}
