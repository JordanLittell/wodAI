// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UpdateMemoryItemMutation: GraphQLMutation {
  public static let operationName: String = "UpdateMemoryItem"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "1d911f3b38914712b2603bb8a977ecba946f140e57df1dc566ba86a5d773d06a",
    definition: .init(
      #"mutation UpdateMemoryItem($id: ID!, $text: String, $weeks: Int) { updateMemoryItem(id: $id, text: $text, weeks: $weeks) { __typename ...MemoryItemFields } }"#,
      fragments: [MemoryItemFields.self]
    ))

  public var id: WodAiAPI.ID
  public var text: GraphQLNullable<String>
  public var weeks: GraphQLNullable<Int>

  public init(
    id: WodAiAPI.ID,
    text: GraphQLNullable<String>,
    weeks: GraphQLNullable<Int>
  ) {
    self.id = id
    self.text = text
    self.weeks = weeks
  }

  public var __variables: Variables? { [
    "id": id,
    "text": text,
    "weeks": weeks
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateMemoryItem", UpdateMemoryItem.self, arguments: [
        "id": .variable("id"),
        "text": .variable("text"),
        "weeks": .variable("weeks")
      ]),
    ] }

    public var updateMemoryItem: UpdateMemoryItem { __data["updateMemoryItem"] }

    /// UpdateMemoryItem
    ///
    /// Parent Type: `MemoryItem`
    public struct UpdateMemoryItem: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.MemoryItem }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .fragment(MemoryItemFields.self),
      ] }

      public var id: WodAiAPI.ID { __data["id"] }
      public var kind: GraphQLEnum<WodAiAPI.MemoryItemKind> { __data["kind"] }
      public var text: String { __data["text"] }
      public var startsOn: String? { __data["startsOn"] }
      public var endsOn: String? { __data["endsOn"] }

      public struct Fragments: FragmentContainer {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public var memoryItemFields: MemoryItemFields { _toFragment() }
      }
    }
  }
}
