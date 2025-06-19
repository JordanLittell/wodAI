// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class CreateGymProfileMutation: GraphQLMutation {
  public static let operationName: String = "CreateGymProfileMutation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "51ec32179aed185ee2e08bc3f47950364c9b70e535d90d87d4f53a3464d4c3e5",
    definition: .init(
      #"mutation CreateGymProfileMutation($input: CreateGymProfileInput!) { createGymProfile(input: $input) { __typename equipment { __typename id name } name } }"#
    ))

  public var input: WodAiAPI.CreateGymProfileInput

  public init(input: WodAiAPI.CreateGymProfileInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("createGymProfile", CreateGymProfile.self, arguments: ["input": .variable("input")]),
    ] }

    public var createGymProfile: CreateGymProfile { __data["createGymProfile"] }

    /// CreateGymProfile
    ///
    /// Parent Type: `GymProfile`
    public struct CreateGymProfile: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GymProfile }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("equipment", [Equipment].self),
        .field("name", String.self),
      ] }

      public var equipment: [Equipment] { __data["equipment"] }
      public var name: String { __data["name"] }

      /// CreateGymProfile.Equipment
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
