// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ToggleGymProfileMutation: GraphQLMutation {
  public static let operationName: String = "ToggleGymProfileMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "6621e66a56384edc243a8cf3a23d3e564b6bfb8802765f62c2c2fd3595afdd97",
    definition: .init(
      #"mutation ToggleGymProfileMutation($id: Int!) { toggleGymProfile(id: $id) { __typename id name isActive equipment { __typename id name } } }"#
    ))

  public var id: Int

  public init(id: Int) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("toggleGymProfile", ToggleGymProfile.self, arguments: ["id": .variable("id")]),
    ] }

    public var toggleGymProfile: ToggleGymProfile { __data["toggleGymProfile"] }

    /// ToggleGymProfile
    ///
    /// Parent Type: `GymProfile`
    public struct ToggleGymProfile: WodAiAPI.SelectionSet {
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

      /// ToggleGymProfile.Equipment
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
