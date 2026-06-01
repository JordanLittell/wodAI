// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class AppleLoginMutation: GraphQLMutation {
  public static let operationName: String = "AppleLogin"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "e9bea7f2c7db9194badedf18ae82be5afefa650b75dd42e07ac0a902bdb87aef",
    definition: .init(
      #"mutation AppleLogin($identityToken: String!, $fullName: String, $email: String, $user: String!) { loginWithApple( identityToken: $identityToken fullName: $fullName email: $email user: $user ) { __typename token user { __typename id email sub firstName lastName age gender fitnessLevel } } }"#
    ))

  public var identityToken: String
  public var fullName: GraphQLNullable<String>
  public var email: GraphQLNullable<String>
  public var user: String

  public init(
    identityToken: String,
    fullName: GraphQLNullable<String>,
    email: GraphQLNullable<String>,
    user: String
  ) {
    self.identityToken = identityToken
    self.fullName = fullName
    self.email = email
    self.user = user
  }

  public var __variables: Variables? { [
    "identityToken": identityToken,
    "fullName": fullName,
    "email": email,
    "user": user
  ] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("loginWithApple", LoginWithApple.self, arguments: [
        "identityToken": .variable("identityToken"),
        "fullName": .variable("fullName"),
        "email": .variable("email"),
        "user": .variable("user")
      ]),
    ] }

    public var loginWithApple: LoginWithApple { __data["loginWithApple"] }

    /// LoginWithApple
    ///
    /// Parent Type: `AuthPayload`
    public struct LoginWithApple: WodAiAPI.SelectionSet {
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

      /// LoginWithApple.User
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
          .field("sub", String.self),
          .field("firstName", String?.self),
          .field("lastName", String?.self),
          .field("age", Int?.self),
          .field("gender", GraphQLEnum<WodAiAPI.Gender>?.self),
          .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
        ] }

        public var id: Int { __data["id"] }
        public var email: String { __data["email"] }
        public var sub: String { __data["sub"] }
        public var firstName: String? { __data["firstName"] }
        public var lastName: String? { __data["lastName"] }
        public var age: Int? { __data["age"] }
        public var gender: GraphQLEnum<WodAiAPI.Gender>? { __data["gender"] }
        public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
      }
    }
  }
}
