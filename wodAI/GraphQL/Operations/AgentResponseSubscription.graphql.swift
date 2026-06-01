// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AgentResponseSubscription: GraphQLSubscription {
  public static let operationName: String = "AgentResponse"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f48261b8eb5ee8d4fc544a483907675da8303d3b1654cd5dec3751c750629104",
    definition: .init(
      #"subscription AgentResponse($wodId: String!) { agentResponse(wodId: $wodId) { __typename text isComplete conversationId } }"#
    ))

  public var wodId: String

  public init(wodId: String) {
    self.wodId = wodId
  }

  public var __variables: Variables? { ["wodId": wodId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Subscription }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("agentResponse", AgentResponse.self, arguments: ["wodId": .variable("wodId")]),
    ] }

    public var agentResponse: AgentResponse { __data["agentResponse"] }

    /// AgentResponse
    ///
    /// Parent Type: `AgentResponse`
    public struct AgentResponse: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AgentResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("text", String.self),
        .field("isComplete", Bool.self),
        .field("conversationId", String.self),
      ] }

      public var text: String { __data["text"] }
      public var isComplete: Bool { __data["isComplete"] }
      public var conversationId: String { __data["conversationId"] }
    }
  }
}
