// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class UpdateUserMutation: GraphQLMutation {
  public static let operationName: String = "UpdateUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation UpdateUser($updateUserId: Int!, $input: UpdateUserInput!) { updateUser(id: $updateUserId, input: $input) { __typename id } }"#
    ))

  public var updateUserId: Int
  public var input: UpdateUserInput

  public init(
    updateUserId: Int,
    input: UpdateUserInput
  ) {
    self.updateUserId = updateUserId
    self.input = input
  }

  public var __variables: Variables? { [
    "updateUserId": updateUserId,
    "input": input
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("updateUser", UpdateUser.self, arguments: [
        "id": .variable("updateUserId"),
        "input": .variable("input")
      ]),
    ] }

    public var updateUser: UpdateUser { __data["updateUser"] }

    /// UpdateUser
    ///
    /// Parent Type: `User`
    public struct UpdateUser: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", Int.self),
      ] }

      public var id: Int { __data["id"] }
    }
  }
}
