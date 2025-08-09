// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class ProvisionUserMutation: GraphQLMutation {
  public static let operationName: String = "ProvisionUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "761957d541b51c5ea84a47a1089592cfa15b972643f434f0d9f11f69639e6a6e",
    definition: .init(
      #"mutation ProvisionUser($input: ProvisionUserInput!) { provisionUser(input: $input) { __typename success message user { __typename id email firstName lastName } } }"#
    ))

  public var input: WodAiAPI.ProvisionUserInput

  public init(input: WodAiAPI.ProvisionUserInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("provisionUser", ProvisionUser.self, arguments: ["input": .variable("input")]),
    ] }

    public var provisionUser: ProvisionUser { __data["provisionUser"] }

    /// ProvisionUser
    ///
    /// Parent Type: `ProvisionUserResponse`
    public struct ProvisionUser: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.ProvisionUserResponse }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("success", Bool.self),
        .field("message", String?.self),
        .field("user", User?.self),
      ] }

      public var success: Bool { __data["success"] }
      public var message: String? { __data["message"] }
      public var user: User? { __data["user"] }

      /// ProvisionUser.User
      ///
      /// Parent Type: `User`
      public struct User: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("email", String.self),
          .field("firstName", String?.self),
          .field("lastName", String?.self),
        ] }

        public var id: Int { __data["id"] }
        public var email: String { __data["email"] }
        public var firstName: String? { __data["firstName"] }
        public var lastName: String? { __data["lastName"] }
      }
    }
  }
}
