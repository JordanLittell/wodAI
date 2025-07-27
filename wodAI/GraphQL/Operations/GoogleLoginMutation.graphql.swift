// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class GoogleLoginMutation: GraphQLMutation {
  public static let operationName: String = "GoogleLogin"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "2a4a8eac7afc8ba14e53602a329e4def52ce1035f3e5a0531cd6ddfb2fdc6950",
    definition: .init(
      #"mutation GoogleLogin($idToken: String!) { loginWithGoogle(idToken: $idToken) { __typename user { __typename id height { __typename value unit } gender fitnessLevel email age weight { __typename unit value } } token } }"#
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
          .field("height", Height?.self),
          .field("gender", GraphQLEnum<WodAiAPI.Gender>?.self),
          .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
          .field("email", String.self),
          .field("age", Int?.self),
          .field("weight", Weight?.self),
        ] }

        public var id: Int { __data["id"] }
        public var height: Height? { __data["height"] }
        public var gender: GraphQLEnum<WodAiAPI.Gender>? { __data["gender"] }
        public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
        public var email: String { __data["email"] }
        public var age: Int? { __data["age"] }
        public var weight: Weight? { __data["weight"] }

        /// LoginWithGoogle.User.Height
        ///
        /// Parent Type: `HeightMeasurement`
        public struct Height: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HeightMeasurement }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("value", Double.self),
            .field("unit", GraphQLEnum<WodAiAPI.HeightUnit>.self),
          ] }

          public var value: Double { __data["value"] }
          public var unit: GraphQLEnum<WodAiAPI.HeightUnit> { __data["unit"] }
        }

        /// LoginWithGoogle.User.Weight
        ///
        /// Parent Type: `WeightMeasurement`
        public struct Weight: WodAiAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WeightMeasurement }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("unit", GraphQLEnum<WodAiAPI.WeightUnit>.self),
            .field("value", Double.self),
          ] }

          public var unit: GraphQLEnum<WodAiAPI.WeightUnit> { __data["unit"] }
          public var value: Double { __data["value"] }
        }
      }
    }
  }
}
