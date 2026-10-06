// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class DeleteGymProfileMutation: GraphQLMutation {
  public static let operationName: String = "DeleteGymProfile"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "e3d6bd087a822862dfdf317d11fbbd1c07be18f895a52e99cd3daa0fa651a465",
    definition: .init(
      #"mutation DeleteGymProfile($deleteGymProfileId: Int!) { deleteGymProfile(id: $deleteGymProfileId) }"#
    ))

  public var deleteGymProfileId: Int

  public init(deleteGymProfileId: Int) {
    self.deleteGymProfileId = deleteGymProfileId
  }

  public var __variables: Variables? { ["deleteGymProfileId": deleteGymProfileId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("deleteGymProfile", Bool.self, arguments: ["id": .variable("deleteGymProfileId")]),
    ] }

    public var deleteGymProfile: Bool { __data["deleteGymProfile"] }
  }
}
