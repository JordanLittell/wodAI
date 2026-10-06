// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class RegisterUserMutation: GraphQLMutation {
  public static let operationName: String = "RegisterUser"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "c0d8daa36031b0ea364e246861ae23e08f3fed2c1c6f3a74b069e61f6d9b8300",
    definition: .init(
      #"mutation RegisterUser($email: String!, $password: String!) { register(email: $email, password: $password) { __typename token } }"#
    ))

  public var email: String
  public var password: String

  public init(
    email: String,
    password: String
  ) {
    self.email = email
    self.password = password
  }

  public var __variables: Variables? { [
    "email": email,
    "password": password
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("register", Register.self, arguments: [
        "email": .variable("email"),
        "password": .variable("password")
      ]),
    ] }

    public var register: Register { __data["register"] }

    /// Register
    ///
    /// Parent Type: `AuthPayload`
    public struct Register: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AuthPayload }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token", String.self),
      ] }

      public var token: String { __data["token"] }
    }
  }
}
