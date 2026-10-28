// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public struct MemoryItemFields: WodAiAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment MemoryItemFields on MemoryItem { __typename id kind text startsOn endsOn }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.MemoryItem }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("id", WodAiAPI.ID.self),
    .field("kind", GraphQLEnum<WodAiAPI.MemoryItemKind>.self),
    .field("text", String.self),
    .field("startsOn", String?.self),
    .field("endsOn", String?.self),
  ] }

  public var id: WodAiAPI.ID { __data["id"] }
  public var kind: GraphQLEnum<WodAiAPI.MemoryItemKind> { __data["kind"] }
  public var text: String { __data["text"] }
  public var startsOn: String? { __data["startsOn"] }
  public var endsOn: String? { __data["endsOn"] }
}
