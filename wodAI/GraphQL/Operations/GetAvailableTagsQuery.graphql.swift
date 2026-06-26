// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GetAvailableTagsQuery: GraphQLQuery {
  public static let operationName: String = "GetAvailableTagsQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "685960889e6e624bbff4055c10428632e4350fca9043bce4ac95ec3c972faef5",
    definition: .init(
      #"query GetAvailableTagsQuery($selectedTagIds: [Int!]) { availableTags(selectedTagIds: $selectedTagIds) { __typename id name description category count } }"#
    ))

  public var selectedTagIds: GraphQLNullable<[Int]>

  public init(selectedTagIds: GraphQLNullable<[Int]>) {
    self.selectedTagIds = selectedTagIds
  }

  public var __variables: Variables? { ["selectedTagIds": selectedTagIds] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("availableTags", [AvailableTag].self, arguments: ["selectedTagIds": .variable("selectedTagIds")]),
    ] }

    public var availableTags: [AvailableTag] { __data["availableTags"] }

    /// AvailableTag
    ///
    /// Parent Type: `TagFacet`
    public struct AvailableTag: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.TagFacet }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("description", String.self),
        .field("category", String?.self),
        .field("count", Int.self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String { __data["description"] }
      public var category: String? { __data["category"] }
      public var count: Int { __data["count"] }
    }
  }
}
