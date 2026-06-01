// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GetConversationQuery: GraphQLQuery {
  public static let operationName: String = "GetConversation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "fbb4ef4c5942b52ad941ceabf9a498b1f1db81bb7e2a4a0abda016d3fcb39223",
    definition: .init(
      #"query GetConversation($wodId: String!) { getConversation(wodId: $wodId) { __typename id resourceType resourceId messages { __typename id role content createdAt } createdAt updatedAt } }"#
    ))

  public var wodId: String

  public init(wodId: String) {
    self.wodId = wodId
  }

  public var __variables: Variables? { ["wodId": wodId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("getConversation", GetConversation?.self, arguments: ["wodId": .variable("wodId")]),
    ] }

    public var getConversation: GetConversation? { __data["getConversation"] }

    /// GetConversation
    ///
    /// Parent Type: `Conversation`
    public struct GetConversation: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Conversation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("resourceType", String.self),
        .field("resourceId", String.self),
        .field("messages", [Message].self),
        .field("createdAt", WodAiAPI.DateTime.self),
        .field("updatedAt", WodAiAPI.DateTime.self),
      ] }

      public var id: String { __data["id"] }
      public var resourceType: String { __data["resourceType"] }
      public var resourceId: String { __data["resourceId"] }
      public var messages: [Message] { __data["messages"] }
      public var createdAt: WodAiAPI.DateTime { __data["createdAt"] }
      public var updatedAt: WodAiAPI.DateTime { __data["updatedAt"] }

      /// GetConversation.Message
      ///
      /// Parent Type: `AgentMessage`
      public struct Message: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AgentMessage }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("role", GraphQLEnum<WodAiAPI.AgentMessageRole>.self),
          .field("content", String.self),
          .field("createdAt", WodAiAPI.DateTime.self),
        ] }

        public var id: String { __data["id"] }
        public var role: GraphQLEnum<WodAiAPI.AgentMessageRole> { __data["role"] }
        public var content: String { __data["content"] }
        public var createdAt: WodAiAPI.DateTime { __data["createdAt"] }
      }
    }
  }
}
