// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class EndConversationMutation: GraphQLMutation {
  public static let operationName: String = "EndConversation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "18f8bed8a1016d0e88d24bd9e67a7d7ef7688340364940e5cdbdf903ad8882e7",
    definition: .init(
      #"mutation EndConversation($id: ID!) { endConversation(id: $id) }"#
    ))

  public var id: WodAiAPI.ID

  public init(id: WodAiAPI.ID) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("endConversation", Bool.self, arguments: ["id": .variable("id")]),
    ] }

    public var endConversation: Bool { __data["endConversation"] }
  }
}
