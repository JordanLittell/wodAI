// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GymProfilesQuery: GraphQLQuery {
  public static let operationName: String = "GymProfiles"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "1f9b909987dc134eb18ef7de3f59fa039b1ce62973d3300a7619e24b28fb1f7d",
    definition: .init(
      #"query GymProfiles { gymProfiles { __typename id name isDefault equipment { __typename id name } } }"#
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
        .field("isDefault", Bool.self),
        .field("equipment", [Equipment].self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      public var isDefault: Bool { __data["isDefault"] }
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
