// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SendAgentMessageMutation: GraphQLMutation {
  public static let operationName: String = "SendAgentMessage"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "8e2ae7a9d0af9862d893432bc4e18ae9d2a32fb4cbc3f6449f99e24a8dee9931",
    definition: .init(
      #"mutation SendAgentMessage($wodId: String!, $message: String!) { sendAgentMessage(wodId: $wodId, message: $message) { __typename conversationId messageId } }"#
    ))

  public var wodId: String
  public var message: String

  public init(
    wodId: String,
    message: String
  ) {
    self.wodId = wodId
    self.message = message
  }

  public var __variables: Variables? { [
    "wodId": wodId,
    "message": message
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("sendAgentMessage", SendAgentMessage.self, arguments: [
        "wodId": .variable("wodId"),
        "message": .variable("message")
      ]),
    ] }

    public var sendAgentMessage: SendAgentMessage { __data["sendAgentMessage"] }

    /// SendAgentMessage
    ///
    /// Parent Type: `SendAgentMessageResponse`
    public struct SendAgentMessage: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.SendAgentMessageResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("conversationId", String.self),
        .field("messageId", String.self),
      ] }

      public var conversationId: String { __data["conversationId"] }
      public var messageId: String { __data["messageId"] }
    }
  }
}
