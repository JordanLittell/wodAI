// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UpdateGymProfileMutation: GraphQLMutation {
  public static let operationName: String = "UpdateGymProfile"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f2e5724369a928a7e79dae5ba65592ee0b65888efaf0d4c65f422e2cbab7270f",
    definition: .init(
      #"mutation UpdateGymProfile($updateGymProfileId: Int!, $input: UpdateGymProfileInput!) { updateGymProfile(id: $updateGymProfileId, input: $input) { __typename id name updatedAt equipment { __typename id name } } }"#
    ))

  public var updateGymProfileId: Int
  public var input: WodAiAPI.UpdateGymProfileInput

  public init(
    updateGymProfileId: Int,
    input: WodAiAPI.UpdateGymProfileInput
  ) {
    self.updateGymProfileId = updateGymProfileId
    self.input = input
  }

  public var __variables: Variables? { [
    "updateGymProfileId": updateGymProfileId,
    "input": input
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateGymProfile", UpdateGymProfile.self, arguments: [
        "id": .variable("updateGymProfileId"),
        "input": .variable("input")
      ]),
    ] }

    public var updateGymProfile: UpdateGymProfile { __data["updateGymProfile"] }

    /// UpdateGymProfile
    ///
    /// Parent Type: `GymProfile`
    public struct UpdateGymProfile: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GymProfile }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
        .field("name", String.self),
        .field("updatedAt", WodAiAPI.DateTime.self),
        .field("equipment", [Equipment].self),
      ] }

      public var id: Int { __data["id"] }
      public var name: String { __data["name"] }
      public var updatedAt: WodAiAPI.DateTime { __data["updatedAt"] }
      public var equipment: [Equipment] { __data["equipment"] }

      /// UpdateGymProfile.Equipment
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
