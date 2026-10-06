// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class EquipmentQuery: GraphQLQuery {
  public static let operationName: String = "Equipment"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "66384e8449349309aea1e2fe8643a2968392f221baca2f15c46a2216518d3cfe",
    definition: .init(
      #"query Equipment { equipment { __typename name id } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("equipment", [Equipment].self),
    ] }

    public var equipment: [Equipment] { __data["equipment"] }

    /// Equipment
    ///
    /// Parent Type: `Equipment`
    public struct Equipment: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Equipment }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
        .field("id", Int.self),
      ] }

      public var name: String { __data["name"] }
      public var id: Int { __data["id"] }
    }
  }
}
