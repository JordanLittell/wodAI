// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GoogleLoginMutation: GraphQLMutation {
  public static let operationName: String = "GoogleLogin"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "e2da06f428ca2ee4086d25613fce0de3aae33519d755aeaceec182e3e5052231",
    definition: .init(
      #"mutation GoogleLogin($idToken: String!) { loginWithGoogle(idToken: $idToken) { __typename user { __typename id height gender fitnessLevel email age weight } token } }"#
    ))

  public var idToken: String

  public init(idToken: String) {
    self.idToken = idToken
  }

  public var __variables: Variables? { ["idToken": idToken] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("loginWithGoogle", LoginWithGoogle.self, arguments: ["idToken": .variable("idToken")]),
    ] }

    public var loginWithGoogle: LoginWithGoogle { __data["loginWithGoogle"] }

    /// LoginWithGoogle
    ///
    /// Parent Type: `AuthPayload`
    public struct LoginWithGoogle: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.AuthPayload }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("user", User.self),
        .field("token", String.self),
      ] }

      public var user: User { __data["user"] }
      public var token: String { __data["token"] }

      /// LoginWithGoogle.User
      ///
      /// Parent Type: `User`
      public struct User: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("height", Int?.self),
          .field("gender", GraphQLEnum<WodAiAPI.Gender>?.self),
          .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
          .field("email", String.self),
          .field("age", Int?.self),
          .field("weight", Int?.self),
        ] }

        public var id: Int { __data["id"] }
        public var height: Int? { __data["height"] }
        public var gender: GraphQLEnum<WodAiAPI.Gender>? { __data["gender"] }
        public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
        public var email: String { __data["email"] }
        public var age: Int? { __data["age"] }
        public var weight: Int? { __data["weight"] }
      }
    }
  }
}
