// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GymPresetsQuery: GraphQLQuery {
  public static let operationName: String = "GymPresets"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "ffbbd7fd4ba065e2b21006b38a8ea2da2b5eb8c8b189ac8390e9b050fad6482b",
    definition: .init(
      #"query GymPresets { gymPresets { __typename key name equipment { __typename id name } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("gymPresets", [GymPreset].self),
    ] }

    public var gymPresets: [GymPreset] { __data["gymPresets"] }

    /// GymPreset
    ///
    /// Parent Type: `GymPreset`
    public struct GymPreset: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GymPreset }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("key", String.self),
        .field("name", String.self),
        .field("equipment", [Equipment].self),
      ] }

      public var key: String { __data["key"] }
      public var name: String { __data["name"] }
      public var equipment: [Equipment] { __data["equipment"] }

      /// GymPreset.Equipment
      ///
      /// Parent Type: `Equipment`
      public struct Equipment: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Equipment }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String.self),
        ] }

        public var id: Int { __data["id"] }
        public var name: String { __data["name"] }
      }
    }
  }
}
