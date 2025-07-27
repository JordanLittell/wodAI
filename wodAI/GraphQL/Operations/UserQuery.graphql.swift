// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
import WodAiAPI

public class UserQuery: GraphQLQuery {
  public static let operationName: String = "User"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    operationIdentifier: "254325c56578f3104507e61d4ece7b58ae705dca6ce13ea640ead534e933cd38",
    definition: .init(
      #"query User($userId: Int!) { user(id: $userId) { __typename weight { __typename value unit } age fitnessLevel gender height { __typename unit value } } }"#
    ))

  public var userId: Int

  public init(userId: Int) {
    self.userId = userId
  }

  public var __variables: Variables? { ["userId": userId] }

  public struct Data: WodAiAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("user", User?.self, arguments: ["id": .variable("userId")]),
    ] }

    public var user: User? { __data["user"] }

    /// User
    ///
    /// Parent Type: `User`
    public struct User: WodAiAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.User }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("weight", Weight?.self),
        .field("age", Int?.self),
        .field("fitnessLevel", GraphQLEnum<WodAiAPI.FitnessLevel>.self),
        .field("gender", GraphQLEnum<WodAiAPI.Gender>?.self),
        .field("height", Height?.self),
      ] }

      public var weight: Weight? { __data["weight"] }
      public var age: Int? { __data["age"] }
      public var fitnessLevel: GraphQLEnum<WodAiAPI.FitnessLevel> { __data["fitnessLevel"] }
      public var gender: GraphQLEnum<WodAiAPI.Gender>? { __data["gender"] }
      public var height: Height? { __data["height"] }

      /// User.Weight
      ///
      /// Parent Type: `WeightMeasurement`
      public struct Weight: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.WeightMeasurement }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("value", Double.self),
          .field("unit", GraphQLEnum<WodAiAPI.WeightUnit>.self),
        ] }

        public var value: Double { __data["value"] }
        public var unit: GraphQLEnum<WodAiAPI.WeightUnit> { __data["unit"] }
      }

      /// User.Height
      ///
      /// Parent Type: `HeightMeasurement`
      public struct Height: WodAiAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { WodAiAPI.Objects.HeightMeasurement }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("unit", GraphQLEnum<WodAiAPI.HeightUnit>.self),
          .field("value", Double.self),
        ] }

        public var unit: GraphQLEnum<WodAiAPI.HeightUnit> { __data["unit"] }
        public var value: Double { __data["value"] }
      }
    }
  }
}
