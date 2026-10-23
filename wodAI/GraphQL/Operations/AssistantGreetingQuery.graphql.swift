// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AssistantGreetingQuery: GraphQLQuery {
  public static let operationName: String = "AssistantGreeting"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "dbf98b5c231e8c4ef71b6450958e7ac2dc5df826af30046acdf0e2c109f5705d",
    definition: .init(
      #"query AssistantGreeting { assistantGreeting { __typename text suggestions { __typename id label action payload } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("assistantGreeting", AssistantGreeting.self),
    ] }

    public var assistantGreeting: AssistantGreeting { __data["assistantGreeting"] }

    /// AssistantGreeting
    ///
    /// Parent Type: `AssistantGreeting`
    public struct AssistantGreeting: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AssistantGreeting }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("text", String.self),
        .field("suggestions", [Suggestion].self),
      ] }

      public var text: String { __data["text"] }
      public var suggestions: [Suggestion] { __data["suggestions"] }

      /// AssistantGreeting.Suggestion
      ///
      /// Parent Type: `AssistantSuggestion`
      public struct Suggestion: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AssistantSuggestion }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("label", String.self),
          .field("action", GraphQLEnum<WodAiAPI.AssistantSuggestionAction>.self),
          .field("payload", String?.self),
        ] }

        public var id: String { __data["id"] }
        public var label: String { __data["label"] }
        public var action: GraphQLEnum<WodAiAPI.AssistantSuggestionAction> { __data["action"] }
        public var payload: String? { __data["payload"] }
      }
    }
  }
}
