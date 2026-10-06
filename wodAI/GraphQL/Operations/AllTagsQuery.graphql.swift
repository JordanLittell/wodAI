// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AllTagsQuery: GraphQLQuery {
  public static let operationName: String = "AllTagsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "8f2f916fc1c8ee90ac0e285c2634eb461626488883ae1b71233f03b16bb714cf",
    definition: .init(
      #"query AllTagsQuery { tags { __typename id name description category } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("tags", [Tag].self),
    ] }

    public var tags: [Tag] { __data["tags"] }

    /// Tag
    ///
    /// Parent Type: `Tag`
    public struct Tag: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Tag }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("description", String.self),
        .field("category", String?.self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var category: String? { __data["category"] }
    }
  }
}
