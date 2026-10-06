// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GymProfilesQuery: GraphQLQuery {
  public static let operationName: String = "GymProfiles"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "c3c010b7ed1649c27db7322eecab2d93aa72af8cc8aeaae711de6df0cd8e69c4",
    definition: .init(
      #"query GymProfiles { gymProfiles { __typename id name isActive equipment { __typename id name } } }"#
    ))

  public init() {}

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("gymProfiles", [GymProfile].self),
    ] }

    public var gymProfiles: [GymProfile] { __data["gymProfiles"] }

    /// GymProfile
    ///
    /// Parent Type: `GymProfile`
    public struct GymProfile: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GymProfile }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("isActive", Bool.self),
        .field("equipment", [Equipment].self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      public var isActive: Bool { __data["isActive"] }
      public var equipment: [Equipment] { __data["equipment"] }

      /// GymProfile.Equipment
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
