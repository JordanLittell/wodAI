// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class SetActiveGymProfileMutation: GraphQLMutation {
  public static let operationName: String = "SetActiveGymProfile"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "f4cec96727350c38f7f3d5a9181d1964267b5f21b0844cdc88e0b46190b8482b",
    definition: .init(
      #"mutation SetActiveGymProfile($setActiveGymProfileId: Int!) { setActiveGymProfile(id: $setActiveGymProfileId) { __typename name } }"#
    ))

  public var setActiveGymProfileId: Int

  public init(setActiveGymProfileId: Int) {
    self.setActiveGymProfileId = setActiveGymProfileId
  }

  public var __variables: Variables? { ["setActiveGymProfileId": setActiveGymProfileId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("setActiveGymProfile", SetActiveGymProfile.self, arguments: ["id": .variable("setActiveGymProfileId")]),
    ] }

    public var setActiveGymProfile: SetActiveGymProfile { __data["setActiveGymProfile"] }

    /// SetActiveGymProfile
    ///
    /// Parent Type: `GymProfile`
    public struct SetActiveGymProfile: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.GymProfile }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("name", String.self),
      ] }

      public var name: String { __data["name"] }
    }
  }
}
