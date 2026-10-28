// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class RemoveMemoryItemMutation: GraphQLMutation {
  public static let operationName: String = "RemoveMemoryItem"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "6b91d16df9b901b5b55bee5c87345915d9a9b05f05a6d55e82fba15b9fa3ac3c",
    definition: .init(
      #"mutation RemoveMemoryItem($id: ID!) { removeMemoryItem(id: $id) }"#
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
      .field("removeMemoryItem", Bool.self, arguments: ["id": .variable("id")]),
    ] }

    public var removeMemoryItem: Bool { __data["removeMemoryItem"] }
  }
}
