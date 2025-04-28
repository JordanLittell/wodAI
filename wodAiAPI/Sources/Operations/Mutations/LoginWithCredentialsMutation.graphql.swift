// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class LoginWithCredentialsMutation: GraphQLMutation {
  public static let operationName: String = "LoginWithCredentials"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation LoginWithCredentials($email: String!, $password: String!) { loginWithCredentials(email: $email, password: $password) { __typename token user { __typename id email fitnessLevel gender } } }"#
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
      .field("loginWithCredentials", LoginWithCredentials.self, arguments: [
        "email": .variable("email"),
        "password": .variable("password")
      ]),
    ] }

    public var loginWithCredentials: LoginWithCredentials { __data["loginWithCredentials"] }

    /// LoginWithCredentials
    ///
    /// Parent Type: `AuthPayload`
    public struct LoginWithCredentials: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AuthPayload }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("token", String.self),
        .field("user", User.self),
      ] }

      public var token: String { __data["token"] }
      public var user: User { __data["user"] }

      /// LoginWithCredentials.User
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
          .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
          .field("gender", GraphQLEnum<WodAiAPI.Gender>?.self),
        ] }

        public var id: Int { __data["id"] }
        public var email: String { __data["email"] }
        public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
        public var gender: GraphQLEnum<WodAiAPI.Gender>? { __data["gender"] }
      }
    }
  }
}
